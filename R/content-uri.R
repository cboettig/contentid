## FIXME consider vectorizing these functions properly

#' Generate a content uri for a local file
#' @param path path to the file
#' @param raw logical, whether the content should be for the raw file or contents, see [base::file]
#' @param ... additional arguments to [base::file]
#' @details 
#' 
#' See <https://github.com/hash-uri/hash-uri> for an overview of the content uri format.
#' 
#' Compressed file streams will have different raw (binary) and uncompressed hashes.
#' Set `raw = FALSE` will allow [file] connection to uncompress common
#' compression streams before calculating the hash, but this will also
#' be slower.  
#' 
#' @return a content uri identifier (which can be resolved by [request_url])
#' 
#' @examples 
#' path <- tempfile("iris", , ".csv")
#' write.csv(iris, path)
#' content_uri(path)
#' 
#' ## Note that a different serialization gives a different hash:
#' path_txt <- tempfile("iris", , ".txt")
#' write.table(iris, path_txt)
#' content_uri(path_txt)
#' 
#'    
#' @export
#' @importFrom openssl sha256  
content_uri <- function(path, raw = TRUE, ...){
  con <- lapply(path, base::file, raw = raw, ...)
  ## Should support other hash types
  hash <- lapply(con, openssl::sha256)

  paste0("hash://sha256/", unlist(lapply(hash, as.character)))
}


## Okay, surely we want to be able to serialize R objects too?  or not -- unclear what that means.