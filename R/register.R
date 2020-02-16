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
  out <- as_dublincore(result)
  
  out$identifier
  
}




################## local registry #################

#' register a URL in a local registry
#' 
#' 
#' @param url a URL to a remote data resource
#' @param dir the path we should use for permanent / on-disk storage of the registry. An appropriate
#' default will be selected (also configurable using the environmental variable `CONTENTURI_HOME`),
#' if not specified.
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
#'   }
#'   
register_local <- function(url, dir = app_dir()){
  registry <- registry_create(dir)
  # (downloads resource to temp dir only)
  x <- download_resource(url)
  meta <- entry_metadata(x)
  
  registry_add(registry, 
               meta$identifier, 
               url, 
               meta$date,
               meta$type,
               meta$extent)
  
  meta$identifier
  
}
  


## For the moment this is a 
registry_create <- function(dir = app_dir()){
  path <- file.path(dir, "registry.tsv")
  if(!file.exists(path)){
    file.create(path, showWarnings = FALSE)
    r <- data.frame(identifier = NA, source = NA, date = NA, type = NA, extent = NA)
    readr::write_tsv(r, path)
  }
  path
}

## Should we try and guess type from location?  
## mime::guess_type(location)
## 
registry_add <- function(registry, identifier, source, date = NA, type = NA, extent = NA){
  readr::write_tsv(data.frame(identifier, source, date, extent, type), registry, append = TRUE)
}

#' @importFrom mime guess_type
entry_metadata <- function(x){    
  list(identifier = content_uri(x),
       type = mime::guess_type(x),
       extent = file.size(x),
       date = Sys.Date()
  )
}

as_dublincore <- function(x){
  
  hash <- openssl::base64_decode(sub("^sha256-", "", x$hashes[[3]]))
  identifier <- paste0("hash://sha256/", paste0(as.character(hash), collapse = "")) 
  size <- x$length
  class(size) <- "fs_bytes"
  list(identifier = identifier, 
       source = x$url, 
       date = .POSIXct(x$timestamp, tz = "UTC"),
       extent = size,
       type = x$type)
}


