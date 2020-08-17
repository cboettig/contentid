
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
  path <- NULL
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
is_url <- function(x) grepl("^((http|ftp)s?|sftp)://", x)



stream_connection <- function(file, download = FALSE, raw = TRUE){
  
  if (inherits(file, "connection")) {
    return(file)
  }
  
  ## URL connection
  if (is_url(file)) {
      if(!download) return( curl::curl(file) )
      file <- curl::curl_download(file, tempfile())
  }
  
  ## Path Name
  if (is.character(file)) {
    file <- file(file, raw = raw) 
  }
  if (!inherits(file, "connection")) 
    stop("'file' must be a character string or connection")
  
  file
}


is_valid.connection <- function(x){
  usumm <- tryCatch(unlist(summary(x)), error = function(e) { })
  if (is.null(usumm)) {
    cl <- oldClass(x)
    cl <- cl[cl != "connection"]
    if (length(cl)){
      return(FALSE)
    }
  } else {
    TRUE
  }
}




## stream_binary() is a streaming-based implementation of base::file.copy() / fs::file_copy()

## Here we go.  Really quite worried this is a slower / more memory-intensive way to file.copy
## f <- curl::curl_download("https://github.com/boettiger-lab/taxadb-cache/releases/download/2019/dwc_gbif.tsv.bz2", tempfile())
# bench::mark({ fs::file_copy(f, tempfile()) })
# bench::mark({ stream_binary(file(f, "rb"), tempfile()) })

## much faster with higher `n` but involves more memory use
stream_binary <- function(input, dest, n = 1e5){
  if(!isOpen(input, "rb")){
    open(input, "rb")
    on.exit(close(input))
  }
  output <- file(dest, "wb")
  on.exit(close(output), add = TRUE)
  while(length(obj <- readBin(input, "raw", n = n))){
    writeBin(obj, output, useBytes = TRUE)
  } 
  dest
}



