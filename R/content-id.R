
#' Generate a content uri for a local file
#' @param file path to the file, URL, or a [base::file] connection
#' @param open The mode to open text, see details for `Mode` in [base::file].
#' @param raw Logical, should compressed data be left as compressed binary?
#' @param algos Which algorithms should we compute contentid for? Default "sha256",
#' see details.
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
#' @importFrom openssl sha256 multihash
#' 
#' @examples
#' 
#' ## local file
#' path <- system.file("extdata", "vostok.icecore.co2", package = "contentid")
#' content_id(path)
#' \donttest{
#' 
#' content_id("http://cdiac.ornl.gov/ftp/trends/co2/vostok.icecore.co2")
#' }
#' 
#' 
content_id <- function(file, 
                       open = "", 
                       raw = TRUE, 
                       algos = default_algos()
                       ){
  
  # cannot vapply a connection
  if(inherits(file, "connection")) 
    return(content_id_(file, open, raw))
  
  vapply(file, content_id_, character(1L), 
         open = open, raw = raw, USE.NAMES = FALSE) 
}



content_id_ <- function(file, open = "", raw = TRUE,
                        algos = c("md5", "sha1", "sha256", "sha384", "sha512")
                        ) {
  
  code <- check_url(file)
  if(code >= 400L) return(NA_character_)
  
  con <- stream_connection(file, open = open, raw = raw)
  
  hashes <- openssl::multihash(con, algos =algos)
  
  out <- paste("hash:/", 
               names(hashes), 
               vapply(hashes, as.character, character(1L)), 
               sep="/")
  names(out) <- names(hashes)
  out
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


default_algos <- function(algos = "sha256"){
  algos <- paste0(algos, collapse=",")
  strsplit(
    Sys.getenv("CONTENTID_ALGOS", 
               algos,
               #c("md5,sha1,sha256,sha384,sha512")
               ), 
    ",")[[1]]
}