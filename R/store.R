## Store should also register the uri in a local registry


#' Store files in a local cache 
#' 
#' Resources at a specified URL will be downloaded and copied into the local storage
#' Local paths will simply be copied into local storage.  For either source, an entry
#' is added to the registry under the content hash identifier.
#' 
#' @param x a URL or path to a local file
#' @inheritParams register_local
#' @return the content-based identifier
#' @export 
#' 
#' @examples 
#' 
#'  vostok_co2 <- system.file("extdata", "vostok.icecore.co2", package = "contenturi")
#'  store(vostok_co2)
#'  
#'  \donttest{
#'  store("http://cdiac.ornl.gov/ftp/trends/co2/vostok.icecore.co2")
#' }
#' 
store <- function(x, dir = app_dir()){
  # Consider vectorizing of x?
  
  ## ick extra logic so we can register the url location as well, 
  ## (without duplicating calls to download or hash)
  url <- NULL
  if(is_url(x)){
    url <- x
    x <- download_resource(x)
  } 
  
  ## Compute the Content Hash URI and other metadata
  meta <- entry_metadata(x)
  
  ## initialize a handle to the registry
  registry <- registry_create(dir)
  
  ## Register the URL as a location
  if(!is.null(url)){
    registry_add(registry, 
                 meta$identifier, 
                 url, 
                 meta$date)  
  }
  
  ## Here we actually copy the data into the local store
  stored_path <- store_shelve(x, meta$identifier, dir = dir)
  
  ## And we register that location as well
  
  registry_add(registry, 
               meta$identifier, 
               stored_path, 
               meta$date)   
  
  meta$identifier

}


## Shelve the object based on its content_uri
store_shelve <- function(file, hash = NULL, dir = app_dir()){
  
  ## In general these steps will have been performed already:
  file <- download_resource(file)
  if(is.null(hash)) 
    hash <- content_uri(file)
  
  ## Determine the storage location and move the file to that location
  dest <- hash_path(hash, dir)
  file.copy(file, dest, overwrite = TRUE) # Technically should silently skip overwrite instead
  
  dest
}


store_retrieve <- function(x, dir = app_dir()){
  if(!is_content_uri(x)) stop(paste(x, "is not a recognized content uri"), call. = FALSE)
  
  path <- hash_path(x)
  
  if(!file.exists(path)){
    return(warning(paste("No stored file found for", x,
                         "in", dir), 
                   call. = FALSE)
           )
  }
  path
}



hash_path <- function(hash, dir = app_dir()){
  ## use 2-level nesting
  hash <- strip_prefix(hash)
  sub1 <- gsub("^(\\w{2}).*", "\\1", hash)
  sub2 <- gsub("^(\\w{2})(\\w{2}).*", "\\2", hash)
  base <- file.path(dir,sub1, sub2)
  dir.create(base, FALSE, TRUE)
  file.path(base, hash)
}


# first cache content for all urls locally, then register them locally. Registry non-file urls remotely. 
# returns a table of hash_uri | url with remote and local urls 
