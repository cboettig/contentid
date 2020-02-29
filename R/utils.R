
#' @importFrom tools file_ext
file_ext <- function(x) {
  ext <- tools::file_ext(x)
  ## if compressed, chop off that and try again
  if (ext %in% c("gz", "bz2", "xz", "zip")) {
    ext <- tools::file_ext(gsub("\\.([[:alnum:]]+)$", "", x))
  }
  ext
}


## Download a resource to temporary local path, if necessary
#' @importFrom curl curl_download
download_resource <- function(x) {
  ## x is a local file
  if (file.exists(x)) {
    path <- x
  }

  ## x is a URL
  if (is_url(x)) {
    tmp <- tempfile(fileext = file_ext(x))
    curl::curl_download(x, tmp)
    path <- tmp
  }
  path
}

## These should be much more general!
add_prefix <- function(x) paste0("hash://sha256/", x)
strip_prefix <- function(x) gsub("^hash://sha256/", "", x)
is_content_uri <- function(x) grepl("^hash://sha256/", x)
is_url <- function(x) grepl("^(https?|ftps?)://.*$", x)

## A configurable default location for persistent data storage
#' @importFrom rappdirs user_data_dir
app_dir <- function(dir = Sys.getenv(
                      "CONTENTURI_HOME",
                      rappdirs::user_data_dir("contenturi")
                    )) {
  if (!fs::dir_exists(dir)) fs::dir_create(dir)
  dir
}
