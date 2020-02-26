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
#' @return a content identifier uri
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
#' @export
#' @importFrom openssl sha256
content_uri <- function(path, raw = TRUE, ...) {
  con <- lapply(path, base::file, raw = raw, ...)
  ## Should support other hash types
  hash <- lapply(con, openssl::sha256)

  paste0("hash://sha256/", vapply(hash, as.character, character(1L)))
}


## Hash archive computes and stores hashes as this:
content_hashes <- function(path, ...) {
  cons <- lapply(path, base::file, raw = raw, open = "rb")
  hashes <- lapply(
    cons,
    function(con) {
      c(
        md5 = paste0("md5-", openssl::base64_encode(openssl::md5(con))),
        sha1 = paste0("sha1-", openssl::base64_encode(openssl::sha1(con))),
        sha256 = paste0("sha256-", openssl::base64_encode(openssl::sha256(con))),
        sha384 = paste0("sha384-", openssl::base64_encode(openssl::sha384(con))),
        sha512 = paste0("sha512-", openssl::base64_encode(openssl::sha512(con)))
      )
    }
  )
  lapply(cons, close)
  hashes
}

## Okay, surely we want to be able to serialize R objects too?  or not -- unclear what that means.
