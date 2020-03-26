
#' Generate a content uri for a local file
#' @param file path to the file, URL, or a [base::file] connection
#' @param open The mode to open text, see details for `Mode` in [base::file].
#' @param raw Logical, should compressed data be left as compressed binary?
#' @details
#'
#' See <https://github.com/hash-uri/hash-uri> for an overview of the
#'  content uri format and comparison to similar approaches.
#'
#' Compressed file streams will have different raw (binary) and uncompressed
#'  hashes. Set `raw = FALSE` to allow [base::file] connection to uncompress 
#'  common compression streams before calculating the hash, but this will
#'  be slower.
#'
#' @return a content identifier uri
#' 
#' @export
#' @importFrom openssl sha256
#' 
#' @examples
#' path <- tempfile("iris", , ".csv")
#' write.csv(iris, path)
#' content_id(path)
#'
#' ## Note that a different serialization gives a different hash:
#' path_txt <- tempfile("iris", , ".txt")
#' write.table(iris, path_txt)
#' content_id(path_txt)
#' 
content_id <- function(file, open = "", raw = TRUE){
  
  # cannot vapply a connection
  if(inherits(file, "connection")) 
    return(content_id_(file, open, raw))
  
  vapply(file, content_id_, character(1L), 
         open = open, raw = raw, USE.NAMES = FALSE) 
}



content_id_ <- function(file, open = "", raw = TRUE) {
  
  code <- check_url(file)
  if(code >= 400L) return(NA_character_)
  
  con <- stream_connection(file, open = open, raw = raw)
  
  ## Could support other hash types
  hash <- openssl::sha256(con)
  paste0("hash://sha256/", as.character(hash))
}


#' @importFrom httr HEAD status_code http_status
check_url <- function(file, warn = TRUE){
  if(!is.character(file)) return(200L)  # Connection objects
  if(!is_url(file)) return(200L)        # local file paths
  resp <- httr::HEAD(file)
  code <- httr::status_code(resp)
  status <- httr::http_status(resp)
  if(code >= 400L && warn){
      warning(status$message, call. = FALSE)
  }
  code
}


## Hash archive computes and stores hashes as this:
content_hashes <- function(path) {
  cons <- lapply(path, stream_connection, raw = raw)
  hashes <- lapply(
    cons,
    function(con) {
     c(
      md5 = paste0("md5-",
                   openssl::base64_encode(openssl::md5(con))),
      sha1 = paste0("sha1-", 
                    openssl::base64_encode(openssl::sha1(con))),
      sha256 = paste0("sha256-",
                      openssl::base64_encode(openssl::sha256(con))),
      sha384 = paste0("sha384-",
                      openssl::base64_encode(openssl::sha384(con))),
      sha512 = paste0("sha512-",
                      openssl::base64_encode(openssl::sha512(con)))
      )
    }
  )
  lapply(cons, close)
  hashes
}
