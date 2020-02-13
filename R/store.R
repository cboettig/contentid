## Store should also register the uri in a local registry

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
