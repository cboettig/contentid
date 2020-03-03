#' register a URL with remote and/or local registries
#'
#' @param url a URL for a data file
#' @param registries list of registries at which to register the URL
#' @param ... additional arguments to `[register_local]`
#' or `[register_remote]`.
#' @details Local registries can be specified as one or more file paths
#'  where local registries should be created.  Usually a given application
#'  will want to register in only one local registry.  For most use cases,
#'  the default registry should be sufficent.
#' @return the [httr::response] object for the request (invisibly)
#' @export
#' @examples
#' \donttest{
#'
#' register("https://zenodo.org/record/3678928/files/vostok.icecore.co2")
#' }
#'
register <- function(url, registries = default_registries(), ...) {
  local_out <- NULL
  remote_out <- NULL

  if (any(grepl("^https://hash-archive.org", registries))) {
    remote_out <- register_remote(url)
  }

  local <- registries[dir.exists(registries)]
  local_out <- lapply(local, function(dir) register_local(url, dir = dir))
  out <- unique(c(remote_out, unlist(local_out)))
  out
}


#' default registries
#'
#' A helper function to conviently load the default registries
#' @details This function is primarily useful to restrict the
#' scope of `[query]` or `[register]` to, e.g. either just the
#' remote registry or just the local registry.  Note that a user
#' can alter the registry on the fly by passing local paths and/or the
#' URL (`https://hash-archive.org`) directly.
#'
#' @examples
#' ## Both defaults
#' default_registries()
#'
#' ## Only the fist one (local registry)
#' default_registry()[1]
#' \donttest{
#' ## Alter the defaults with env var.
#' ## here we set two local registries as the defaults
#' Sys.setenv(CONTENTURI_REGISTRIES = "store/, store2/")
#' default_registries()
#'
#' Sys.unsetenv(CONTENTURI_REGISTRIES)
#' }
#' @noRd
# @export
default_registries <- function() {
  registries <- strsplit(
    Sys.getenv(
      "CONTENTURI_REGISTRIES",
      paste(app_dir(),
        "https://hash-archive.org",
        sep = ", "
      )
    ),
    ", "
  )[[1]]

  registries
}


################################## remote registry ############################

#' register a URL with hash-archive.org
#'
#' @inheritParams register
#' @return the [httr::response] object for the request (invisibly)
#' @importFrom httr GET
#' @importFrom openssl base64_decode
#' @importFrom httr content GET stop_for_status
#' @noRd
#  @export
#' @examples
#' \donttest{
#'
#' register_remote(
#'   "https://zenodo.org/record/3678928/files/vostok.icecore.co2"
#' )
#' }
#'
register_remote <- function(url) {
  archive <- "https://hash-archive.org"
  endpoint <- "api/enqueue"
  request <- paste(archive, endpoint, url, sep = "/")
  response <- httr::GET(request)
  httr::stop_for_status(response)

  result <- httr::content(response, "parsed", "application/json")
  out <- format_hashachiveorg(result)

  out$identifier
}




################## local registry #################

#' register a URL in a local registry
#'
#'
#' @return the [httr::response] object for the request (invisibly)
#' @importFrom httr GET
#' @importFrom openssl base64_decode
#' @importFrom httr content GET stop_for_status
#' @noRd
#' @examples
#' \donttest{
#'
#' register_local(
#'   "https://zenodo.org/record/3678928/files/vostok.icecore.co2"
#' )
#' }
#'
register_local <- function(url, dir = app_dir()) {
  # (downloads resource to temp dir only)
  id <- content_uri(url)
  
  registry_add(
    dir,
    id,
    url,
    Sys.time()
  )

  id
}



registry_create <- function(dir = app_dir()) {
  path <- fs::path_abs(fs::path("data", "registry.tsv.gz"), dir)
  if (!fs::dir_exists(fs::path_dir(path))) {
    fs::dir_create(fs::path_dir(path))
  }
  if (!fs::file_exists(path)) {
    fs::file_create(path)
    r <- data.frame(identifier = NA, source = NA, date = NA)
    readr::write_tsv(r[0, ], path)
  }
  path
}


registry_add <- function(dir = app_dir(), identifier, source, date = NA) {
  registry <- registry_create(dir)
  readr::write_tsv(data.frame(identifier, source, date),
    registry,
    append = TRUE
  )
}

# @importFrom mime guess_type
entry_metadata <- function(x) {
  list(
    identifier = content_uri(x),
    #       type = mime::guess_type(x),
    date = Sys.time()
    # note that we aren't recording source x,
    # which is a temporary file location.
  )
}

## a formatter for data returned by hash-archive.org
format_hashachiveorg <- function(x) {
  hash <- openssl::base64_decode(sub("^sha256-", "", x$hashes[[3]]))
  identifier <- add_prefix(paste0(as.character(hash), collapse = ""))
  list(
    identifier = identifier,
    source = x$url,
    date = .POSIXct(x$timestamp, tz = "UTC")
  )
  ## Note that hash-archive.org also provides:
  ## type, status, and other hash formats
  ## We do not return these
}
