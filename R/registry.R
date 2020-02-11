

#' register a URL with hash-archive.org
#' 
#' @param url a download URL for a data file
#' @return the [httr::response] object for the request (invisibly)
#' @importFrom httr GET
#' @importFrom openssl base64_decode
#' @importFrom httr content GET stop_for_status
#' 
#' @export
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
register_url <- function(url){
  archive <- "https://hash-archive.org"
  endpoint <- "api/enqueue"
  request <- paste(archive, endpoint, url, sep="/")
  response <- httr::GET(request)
  httr::stop_for_status(response)
  
  result <- httr::content(response, "parsed", "application/json")
  
  # Could optionally display return information about type, size, etc
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
#' sources <- resolve_hash(
#' "hash://sha256/9412325831dab22aeebdd674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37")
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


## Should we be able to `resolve_url` too?  Or is verb wrong? `lookup_url`?

