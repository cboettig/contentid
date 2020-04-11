#' register a URL with remote and/or local registries
#'
#' @param url a URL for a data file (or list of URLs)
#' @param registries list of registries at which to register the URL
#' @param ... additional arguments
#' @details Local registries can be specified as one or more file paths
#'  where local registries should be created.  Usually a given application
#'  will want to register in only one local registry.  For most use cases,
#'  the default registry should be sufficent.
#' @return the [httr::response] object for the request (invisibly)
#' @importFrom stats na.omit
#' @export
#' @examples
#' \donttest{
#'
#' register("https://zenodo.org/record/3678928/files/vostok.icecore.co2")
#' }
#'
register <- function(url, registries = default_registries(), ...) { 
  
  vapply(url, register_, character(1L), registries = registries, ..., USE.NAMES = FALSE)

}


register_ <- function(url, registries = default_registries(), ...) { 
  local_out <- NULL
  ha_out <- NULL

  if (any(grepl("hash-archive.org", registries))) {
    
    remote <- registries[grepl("hash-archive.org", registries)]  
    ha_out <- vapply(remote, 
                     function(host) register_ha(url, host = host),
                     character(1L)
                     )

  }

  local <- registries[dir.exists(registries)]
  local_out <- vapply(local, 
                      function(dir) register_tsv(url, dir = dir),
                      character(1L))
  
  ## should be same hash returned from each registration
  out <- assert_unique_id(c(local_out, ha_out))
  out
}

assert_unique_id <- function(x) {
  out <- as.character(stats::na.omit(unique(x)))
  if(length(out) == 0L) return(NA_character_)
  out
}

#' default registries
#'
#' A helper function to conviently load the default registries
#' @details This function is primarily useful to restrict the
#' scope of [query_sources] or [register] to, e.g. either just the
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
#' Sys.setenv(CONTENTID_REGISTRIES = "store/, store2/")
#' default_registries()
#'
#' Sys.unsetenv(CONTENTID_REGISTRIES)
#' }
#' @noRd
# @export
default_registries <- function() {
  registries <- strsplit(
    Sys.getenv(
      "CONTENTID_REGISTRIES",
      paste(content_dir(),
        "https://hash-archive.org",
        "https://archive.softwareheritage.org",
        sep = ", "
      )
    ),
    ", "
  )[[1]]

  registries
}



