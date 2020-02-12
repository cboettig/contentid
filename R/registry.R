#' register a URL with remote and/or local registries
#' 
#' @param url a URL for a data file 
#' @param registries list of registries at which to register the URL
#' @param ... additional arguments to `[local_registry]` or `[remote_registry]`.
#' @return the [httr::response] object for the request (invisibly)
#' @export
#' @examples 
#' \donttest{
#'   
#'  register("http://cdiac.ornl.gov/ftp/trends/co2/vostok.icecore.co2")
#'   
#'   }
#'   
register <- function(url, registries = c("local", "remote"), ...){
  if("remote" %in% registries) remote_register(url, ...)
  if("local" %in% registries) local_register(url, ...)
}



lookup  <- function(url, registries = c("local", "remote"), ...){
  if("remote" %in% registries) remote_lookup(url, ...)
  if("local" %in% registries) local_lookup(url, ...)
}



################################## remote registry ############################

#' register a URL with hash-archive.org
#' 
#' @inheritParams register
#' @return the [httr::response] object for the request (invisibly)
#' @importFrom httr GET
#' @importFrom openssl base64_decode
#' @importFrom httr content GET stop_for_status
#' 
#' @export
#' @examples 
#' \donttest{
#'   
#'  remote_register("http://cdiac.ornl.gov/ftp/trends/co2/vostok.icecore.co2")
#'   
#'   }
#'   
remote_register <- function(url){
  archive <- "https://hash-archive.org"
  endpoint <- "api/enqueue"
  request <- paste(archive, endpoint, url, sep="/")
  response <- httr::GET(request)
  httr::stop_for_status(response)
  
  result <- httr::content(response, "parsed", "application/json")
  
  # Could optionally display return information about type, size, etc
  hash <- openssl::base64_decode(sub("^sha256-", "", result$hashes[[3]]))
  paste0("hash://sha256/", paste0(as.character(hash), collapse = ""))
  
}

#' return registered downloadable URLs for the resource from hash-archive.org
#' @param hash A hash URI, or download URL of a resource
#' 
#' @return a data frame with columns for `url`, `timestamp`, 
#' `status`, `type` (mimeType), `length` (bytes), and `hashes`
#' @export
#' @examples \donttest{
#' sources <- lookup_remote(
#' "hash://sha256/9412325831dab22aeebdd674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37")
#' 
#' # try reading in the first source
#' df <- read.table(sources$url[1])
#' }
#' @importFrom httr GET content
#' @importFrom jsonlite fromJSON
remote_lookup <- function(hash){ 
  archive <- "https://hash-archive.org"
  endpoint <- "api/sources"
  request <- paste(archive, endpoint, hash, sep = "/")
  response <- httr::GET(request)
  jsonlite::fromJSON(httr::content(response, as = "text"))
}


################## local registry #################


local_register <- function(x, dir = registry_dir()){
  
}

local_lookup <- function(x, dir = registry_dir()){
  
}



## For the moment this is a 
registry_create <- function(dir = registry_dir()){
  file.create(file.path(dir, "registry"), showWarnings = FALSE)
}




