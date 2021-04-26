
#' Generate a content uri for a local file
#' @param file path to the file, URL, or a [base::file] connection
#' @param raw Logical, should compressed data be left as compressed binary?
#' @param algos Which algorithms should we compute contentid for? Default 
#' "sha256", see details.
#' @param as.data.frame should the output be coerced into a data.frame? 
#' Default is `FALSE` if only one algorithm is computed, otherwise `TRUE`.
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
#' @return a content identifier URI  If multiple algorithms
#' are requested, `content_id` will return a data.frame with one
#' column per algorithm and one row for each input file.  Otherwise
#' it will return a character vector with one identifier URI for 
#' each input file.  See argument `as.data.frame` above.
#' 
#' @export
#' @importFrom openssl sha256
#' 
#' @examples
#' 
#' ## local file
#' path <- system.file("extdata", "vostok.icecore.co2", package = "contentid")
#' content_id(path)
#' \donttest{
#' 
#' content_id(paste0("https://knb.ecoinformatics.org/knb/d1/mn/v2/object/",
#'                   "ess-dive-457358fdc81d3a5-20180726T203952542"))
#' }
#' 
#' 
content_id <- function(file, 
                       algos = default_algos(),
                       raw = TRUE,
                       as.data.frame = length(algos) > 1
                       ){
  
  # cannot vapply a connection
  if(inherits(file, "connection")){ 
    out <- content_id_(file, algos = algos, raw = raw)
    
  } else {
    
    out <- vapply(file, 
                  content_id_, 
                  character(length(algos)),
                  algos = algos,
                  raw = raw) 
  }
  
 
  
  if(as.data.frame){
    m <- matrix(t(out), nrow = length(file), ncol = length(algos))
    df <- as.data.frame(m, 
                        row.names = NULL, 
                        stringsAsFactors = FALSE)
    colnames(df) <- algos
    df
  } else {
    unname(out)
  }
}



content_id_ <- function(file,
                        algos = default_algos(),
                        raw = TRUE
                        ) {
  
  code <- check_url(file)
  if(code >= 400L){
    warning(paste(file, "had error code", code), call. = FALSE)
    return(rep(NA_character_, length(algos)))
  }
  
  con <- stream_connection(file, raw = raw)
  
  if(!is_valid.connection(con)){ 
    paste(file, "is not a valid connection", call.=FALSE)
    return(rep(NA_character_, length(algos)))
  }
  
  hashes <- try_multihash(con, algos = algos)
  
  out <- paste("hash:/", 
               names(hashes), 
               vapply(hashes, as.character, character(1L)), 
               sep="/")
  names(out) <- names(hashes)
  out
}

#' @importFrom utils packageVersion
try_multihash <- function(con, algos){
  
  version <- utils::packageVersion("openssl")
  if(utils::packageVersion("openssl") > package_version("1.4.1")){
    multihash <- getExportedValue("openssl", "multihash")
    return(multihash(con, algos = algos))
  }
  
  ## fallback if multihash is not avialable
  if(length(algos) > 1) 
    warning("openssl version > 1.4.1 required for multihash\n",
            "computing only the sha256 hash instead.\n", call. = FALSE)
  
  out <- rep(NA_character_, length(algos))
  names(out) <- algos
  out <- as.data.frame(as.list(out))
  sha256 <- as.character(openssl::sha256(con))
  out$sha256 <- sha256
  out
  
}


#' @importFrom httr HEAD status_code http_status
check_url <- function(file){
  if(!is.character(file)) return(200L)  # Connection objects
  if(!is_url(file)){
    if(file.exists(file)){ 
      return(200L) 
    } else {
      return(404L)
    }
  }
  ver <- curl::curl_version()
  handle <- curl::new_handle(nobody = TRUE, 
                             customrequest = "GET")
  if(utils::compareVersion(ver$version, "7.68.0") >= 0){
    handle <- curl::handle_setopt(handle, http09_allowed = TRUE)
  }
  resp <- tryCatch(
    curl::curl_fetch_memory(file, handle),
    error = function(e) {
      warning(as.character(e), call. = FALSE)
      return(list(status_code = 404))
    },
    finally = list(status_code = 404)
  )
  if(! "status_code" %in% names(resp))  return(404L)
  code <- resp$status
  code
}


default_algos <- function(algos = "sha256"){
  algos <- paste0(algos, collapse=",")
  out <- strsplit(Sys.getenv("CONTENTID_ALGOS", algos), 
                  ",")[[1]]
  
  if(!("sha256" %in% out)){
    warning(paste0("adding the required sha256 algo"), call. = FALSE) 
    out <- c("sha256", out)
  }
  out
}

