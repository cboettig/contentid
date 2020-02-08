## FIXME consider vectorizing these functions properly

#' Generate a hash uri for a local file
#' @param path path to the file
#' @param raw logical, whether the hash should be for the raw file or contents, see [base::file]
#' @param ... additional arguments to [base::file]
#' @details 
#' 
#' See <https://github.com/hash-uri/hash-uri> for an overview of the hash uri format.
#' 
#' Compressed file streams will have different raw (binary) and uncompressed hashes.
#' Set `raw = FALSE` will allow [file] connection to uncompress common
#' compression streams before calculating the hash, but this will also
#' be slower.  
#' 
#' @return a hash uri identifier (which can be resolved by [request_url])
#' 
#' @examples 
#' path <- tempfile("iris", , ".csv")
#' write.csv(iris, path)
#' hash_uri(path)
#' 
#' ## Note that a different serialization gives a different hash:
#' path_txt <- tempfile("iris", , ".txt")
#' write.table(iris, path_txt)
#' hash_uri(path_txt)
#' 
#'    
#' @export
#' @importFrom openssl sha256  
hash_uri <- function(path, raw = TRUE, ...){
  con <- lapply(path, base::file, raw = raw, ...)
  ## Should support other hash types
  hash <- lapply(con, openssl::sha256)

  paste0("hash://sha256/", unlist(lapply(hash, as.character)))
}

## FIXME: Implement a local registry with persistent sources?


#' register a URL with hash-archive.org
#' 
#' @param url a download URL for a data file
#' @return the [httr::response] object for the request (invisibly)
#' @importFrom httr GET
#' 
#' @export
#' 
#' @examples 
#' \donttest{
#'   
#'   global_mean_temp <- 
#'   paste0("https://data.giss.nasa.gov/",
#'          "gistemp/graphs/graph_data/",
#'          "Global_Mean_Estimates_based_on_Land_and_Ocean_Data/graph.txt")
#'  
#'  register_url(global_mean_temp)
#'   
#'   }
#'   
#'   @importFrom openssl base64_decode
#'   @importFrom httr content GET stop_for_status
register_url <- function(url){
  archive <- "https://hash-archive.org"
  endpoint <- "api/enqueue"
  request <- paste(archive, endpoint, url, sep="/")
  response <- httr::GET(request)
  httr::stop_for_status(response)
  
  result <- httr::content(response, "parsed", "application/json")
  
  # Could optionally disply return information about type, size, etc
  hash <- openssl::base64_decode(sub("^sha256-", "", result$hashes[[3]]))
  paste0("hash://sha256/", paste0(as.character(hash), collapse = ""))
  
  ## hash-archive returns JSON containing the base-64 encoded URIs.
  ## we could parse these and return them as text hash URIs with openssl::base64_decode
}

#' return registered downloadable URLs for the resource
#' @param hash A hash URI, or download URL of a resource
#' 
#' @return a data frame with columns for `url`, `timestamp`, 
#' `status`, `type` (mimeType), `length` (bytes), and `hashes`
#' @export
#' @examples \donttest{
#' sources <- resolve_hash("hash://sha256/9412325831dab22aeebdd674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37")
#' 
#' # try reading in the first source
#' df <- read.table(sources$url[1])
#' }
#' @importFrom httr GET content
#' @importFrom jsonlite fromJSON
resolve_hash <- function(hash){ 
  archive <- "https://hash-archive.org"
  endpoint <- "api/sources"
  request <- paste(archive, endpoint, hash, sep = "/")
  response <- httr::GET(request)
  jsonlite::fromJSON(httr::content(response, as = "text"))
  
  # readLines(curl::curl(request))
  #httr::content(response, as = "parsed", "application/json")
}

