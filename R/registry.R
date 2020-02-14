#' register a URL with remote and/or local registries
#' 
#' @param url a URL for a data file 
#' @param registries list of registries at which to register the URL
#' @param ... additional arguments to `[register_local]` or `[register_remote]`.
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

  if("local" %in% registries) out <- register_local(url, ...)
  if("remote" %in% registries) out <- register_remote(url, ...)
  out
}


#' lookup a Content URI or a URL with remote and/or local registries
#' 
#' @param uri a Content URI or a regular URL for a data file 
#' @param registries list of registries at which to register the URL
#' @param ... additional arguments to `[lookup_local]` or `[lookup_remote]`.
#' @return a data frame with matching results
#' @export
#' @examples 
#' \donttest{
#'   
#'  ## A content hash
#'  lookup("hash://sha256/9412325831dab22aeebdd674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37")
#'  ## Or a (registered) URL
#'  lookup("http://cdiac.ornl.gov/ftp/trends/co2/vostok.icecore.co2")
#'   
#'   }
#'
lookup  <- function(uri, registries = c("local", "remote"), ...){
  remote_out <- NULL
  local_out <- NULL
  if("remote" %in% registries) remote_out <- lookup_remote(uri, ...)
  if("local" %in% registries) local_out <- lookup_local(uri, ...)
  
  list(remote_out, local_out)
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
#'  register_remote("http://cdiac.ornl.gov/ftp/trends/co2/vostok.icecore.co2")
#'   
#'   }
#'   
register_remote <- function(url){
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
#' 
#' # Can also lookup a URL to see if it has been registered:
#' 
#' 
#' }
#' @importFrom httr GET content
#' @importFrom jsonlite fromJSON
lookup_remote <- function(hash){ 
  archive <- "https://hash-archive.org"
  endpoint <- "api/sources"
  request <- paste(archive, endpoint, hash, sep = "/")
  response <- httr::GET(request)
  jsonlite::fromJSON(httr::content(response, as = "text"))
}





################## local registry #################

#' register a URL (or local file) in a local registry
#' 
#' 
#' @param x a URL or the path to a local file
#' @param dir the path we should use for permanent / on-disk storage of the registry. An appropriate
#' default will be selected (also configurable using the environmental variable `CONTENTURI_HOME`),
#' if not specified.
#' @details If `x` is a URL and `store = TRUE`, both the URL and the local
#'  storage path will be registered. If `x` is a URL and `store = FALSE`,
#'  only the URL location will be registered and the downloaded copy of the 
#'  object will be deleted after it has been registered.  If `x` is a local
#'  path and `store = FALSE`, this function will throw an error.
#' @return the [httr::response] object for the request (invisibly)
#' @importFrom httr GET
#' @importFrom openssl base64_decode
#' @importFrom httr content GET stop_for_status
#' 
#' @export
#' @examples 
#' \donttest{
#'   
#'  register_local("http://cdiac.ornl.gov/ftp/trends/co2/vostok.icecore.co2")
#'  
#'  vostok_co2 <- system.file("extdata", "vostok.icecore.co2", package = "hashuri")
#'  register_local(vostok_co2)
#'   
#'   }
#'   
register_local <- function(url, dir = app_dir()){
  registry <- registry_create(dir)
  x <- download_resource(url)
  meta <- entry_metadata(x)
  
  registry_add(registry, 
               meta$content_uri, 
               url, 
               meta$date,
               meta$type,
               meta$length)  
  
}
  

#' look up a Content URI or URL in the local registry
#' @inheritParams lookup
#' @inheritParams register_local
#' @return a data frame with matching results
#' @export
#' @examples 
#' \donttest{
#'   
#'  ## A content hash
#'  lookup_local("hash://sha256/9412325831dab22aeebdd674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37")
#'  ## Or a (registered) URL
#'  lookup_local("http://cdiac.ornl.gov/ftp/trends/co2/vostok.icecore.co2")
#'   
#'   }
lookup_local <- function(x, dir = app_dir()){
  registry <- registry_create(dir)
  if(is_content_uri(x))
    registry_get_hash(x, registry)
  else
    registry_get_location(x, registry)
}





#' @importFrom readr read_tsv write_tsv
#' @importFrom dplyr filter
registry_get_hash <- function(x, registry){
  df <- readr::read_tsv(registry, col_types = "ccDci")
  dplyr::filter(df, content_uri == x)
}

registry_get_location <- function(x, registry){
  location <- NULL # NSE
  df <- readr::read_tsv(registry, col_types = "ccDci")
  dplyr::filter(df, location == x)
}



## For the moment this is a 
registry_create <- function(dir = app_dir()){
  path <- file.path(dir, "registry.tsv")
  if(!file.exists(path)){
    file.create(path, showWarnings = FALSE)
    r <- data.frame(content_uri = NA, location = NA, date = NA, type = NA, length = NA)
    readr::write_tsv(r, path)
  }
  path
}

## Should we try and guess type from location?  
## mime::guess_type(location)
registry_add <- function(path, content_uri, location, date = NA, type = NA, length = NA){
  readr::write_tsv(data.frame(content_uri, location, date, type, length), path, append = TRUE)
}

#' @importFrom mime guess_type
entry_metadata <- function(x){    
  list(content_uri = content_uri(x),
       type = mime::guess_type(x),
       length = file.size(x),
       date = Sys.Date()
  )
}



#' @export
print.content_registry_entry <- function(x){
  # Could optionally display return information about type, size, etc
  hash <- openssl::base64_decode(sub("^sha256-", "", x$hashes[[3]]))
  paste0("hash://sha256/", paste0(as.character(hash), collapse = "")) 
}



