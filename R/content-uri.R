## FIXME consider vectorizing these functions properly


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
#' content_uri(path)
#'
#' ## Note that a different serialization gives a different hash:
#' path_txt <- tempfile("iris", , ".txt")
#' write.table(iris, path_txt)
#' content_uri(path_txt)
#' 
content_uri <- function(file, open = "", raw = TRUE) {
  
  
  con <- stream_connection(file, open = open, raw = raw)
  ## Could support other hash types
  hash <- openssl::sha256(con)
  paste0("hash://sha256/", as.character(hash))
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

## Okay, surely we want to be able to serialize R objects too?  or not -- unclear what that means.
