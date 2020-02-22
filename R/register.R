#' register a URL with remote and/or local registries
#' 
#' @param url a URL for a data file 
#' @param registries list of registries at which to register the URL
#' @param ... additional arguments to `[register_local]` or `[register_remote]`.
#' @details Local registries can be specified as one or more file paths where local
#' registries should be created.  Usually a given application will want to register in
#' only one local registry.  For most use cases, the default registry should be sufficent.
#' @return the [httr::response] object for the request (invisibly)
#' @export
#' @examples 
#' \donttest{
#'   
#'  register("https://zenodo.org/record/3678928/files/vostok.icecore.co2")
#'   
#'   }
#'   
register <- function(url, registries = default_registries(), ...){

  local_out <- NULL
  remote_out <- NULL
  
  if(any(grepl("^https://hash-archive.org", registries))) remote_out <- register_remote(url)
  
  local <-registries[dir.exists(registries)]
  local_out <- lapply(local, function(dir) register_local(url, dir = dir))
  out <- unique(c(remote_out, unlist(local_out)))
  out
}


default_registries <- function(){
  strsplit(
    Sys.getenv("CONTENTURI_REGISTRIES",
               paste(app_dir(), "https://hash-archive.org/api",
                     sep = ", ")
               ),
    ", ")[[1]]
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
#'  register_remote("https://zenodo.org/record/3678928/files/vostok.icecore.co2")
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
  out <- format_hashachiveorg(result)
  
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
#'  register_local("https://zenodo.org/record/3678928/files/vostok.icecore.co2")
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
               meta$date)
  
  meta$identifier
  
}
  


## For the moment this is a 
registry_create <- function(dir = app_dir()){
  path <- file.path(dir, "registry.tsv.gz")
  if(!file.exists(path)){
    file.create(path, showWarnings = FALSE)
    r <- data.frame(identifier = NA, source = NA, date = NA)
    readr::write_tsv(r[0,], path)
  }
  path
}

## Should we try and guess type from location?  
## mime::guess_type(location)
## 
registry_add <- function(registry, identifier, source, date = NA){
  readr::write_tsv(data.frame(identifier, source, date), registry, append = TRUE)
}

# @importFrom mime guess_type
entry_metadata <- function(x){    
  list(identifier = content_uri(x),
#       type = mime::guess_type(x),
       date = Sys.time()
       # note that we aren't recording source x, which is a temporary file location
  )
}

## a formatter for data returned by hash-archive.org
format_hashachiveorg <- function(x){
  
  hash <- openssl::base64_decode(sub("^sha256-", "", x$hashes[[3]]))
  identifier <- paste0("hash://sha256/", paste0(as.character(hash), collapse = "")) 
  list(identifier = identifier, 
       source = x$url, 
       date = .POSIXct(x$timestamp, tz = "UTC")
       )
  ## Note that hash-archive.org also provides: type, status, and other hash formats
  ## We do not return these
}


