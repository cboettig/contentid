## Store should also register the uri in a local registry


#' @importFrom curl curl_download
store_shelve <- function(x, dir = store_dir()){
  
  ## x is a local file
  if(file.exists(x)) path <- x
  
  ## x is a URL
  if(is_url(x)){
    tmp <- tempfile()
    curl::curl_download(x, tmp)
    path <- tmp
  }  
    
  hash <- content_uri(path)
  dest <- hash_path(hash, dir)
  file.copy(path, dest)
}

store_retrieve <- function(x, dir = store_dir()){
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




hash_path <- function(hash, dir = store_dir()){
  ## use 2-level nesting
  hash <- strip_prefix(hash)
  sub1 <- gsub("^(\\w{2}).*", "\\1", hash)
  sub2 <- gsub("^(\\w{2})(\\w{2}).*", "\\2", hash)
  base <- file.path(dir,sub1, sub2)
  dir.create(base, FALSE, TRUE)
  file.path(base, hash)
}

strip_prefix <- function(x) gsub("^https://sha256/", "", x)
is_content_uri <- function(x) grepl("^https://sha256/", x)
is_url <- function(x) grepl("^(https?|ftps?)://.*$", x)

## A configurable default location for persistent data storage
#' @importFrom rappdirs user_data_dir
store_dir <- function(dir = Sys.getenv("CONTENTURI_HOME", 
                                       rappdirs::user_data_dir())
                      ){
                         dir
                       }


registry_dir <- store_dir # for now


# first cache content for all urls locally, then register them locally. Registry non-file urls remotely. 
# returns a table of hash_uri | url with remote and local urls 
