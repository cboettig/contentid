
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
is_url <- function(x) grepl("^((http|ftp)s?|sftp)://", x)

## A configurable default location for persistent data storage
#' @importFrom rappdirs user_data_dir
app_dir <- function(dir = Sys.getenv(
                      "CONTENTURI_HOME",
                      rappdirs::user_data_dir("contenturi")
                    )) {
  if (!fs::dir_exists(dir)) fs::dir_create(dir)
  dir
}


read_stream <- function(file, open = "rb", raw = TRUE){
  
  if (inherits(file, "connection")) {
    return(file)
  }
  
  ## URL connection
  if (is_url(file)) {
    if (requireNamespace("curl", quietly = TRUE)) {
      con <- curl::curl(file)
    }
    else {
      message("`curl` package not installed, falling back to using `url()`")
      con <- url(file)
    }
    return(con)
  }
  
  ## Path Name
  if (is.character(file)) {
    file <- file(file, open = open, raw = raw) 
    ## cannot close on exit, but we register a finalizer?
    env <-  parent.env(environment())
    reg.finalizer(env, function(env) close(file))
  }
  if (!inherits(file, "connection")) 
    stop("'file' must be a character string or connection")
  
  ## Do we want to open the file? maybe not
  # if (!isOpen(file, open)) {
  #  open(file, open = open, raw = raw)
  #  env <- parent.env(environment())
  #  reg.finalizer(env, function(env) close(file))
  # }
  file
}

