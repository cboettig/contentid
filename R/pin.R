

pin <- function(uri, dir = app_dir()){
  
  ## If URI is a local path
  
  
  ## if uri is hashURI, we check if we have a local copy.
  if(is_content_uri(uri)){
    
    hash <- content_uri(uri)
    path <- hash_path(hash, dir)
    ## if we have a local copy, return that path.
    if(file.exists(path)){
      return(path)
    } else {
      
      ## try to look up a URI for the hash, and continue with that
      uri <- lookup(uri)$url[1]  ## ick we can do better than this
    }
    
    ## URI is not at hashuri: 
    
    ## if we don't have a local copy: download, hash, and store object
    ## check registry
    ## download to store_dir
    ## compute hash
    ## rename / move file
    
    
    ## if uri is resolvable URL, we need to download it and hash it.  
    ##  (but not download it if we have a copy already?  do we check the etag?)
    
  }
}  
