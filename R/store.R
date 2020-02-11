# first cache content for all urls locally, then register them locally. Registry non-file urls remotely. 
# returns a table of hash_uri | url with remote and local urls 


pin <- function(uri, contentRegistry, contentStore = hashuri_dir()){
  
  ## if uri is hashURI, we check if we have a local copy.
  if(is_hashuri(uri)){
    
    hash <- content_uri(uri)
    path <- hash_path(hash, contentStore)
    ## if we have a local copy, return that path.
    
    if(file.exists(path)){
      return(path)
    } else {
      ## try to look up a URI for the hash, and continue with that
      uri <- resolve_hash(uri)$url[1]  ## ick we can do better than this
    }
 
  ## URI is not at hashuri: 
  
  ## if we don't have a local copy: download, hash, and store object
    ## check registry
    ## download to hashuri_dir
    ## compute hash
    ## rename / move file
  
  
  ## if uri is resolvable URL, we need to download it and hash it.  
  ##  (but not download it if we have a copy already?  do we check the etag?)
  
  }
}  

hash_path <- function(hash, dir = hashuri_dir()){
  file.path(dir, strip_prefix(hash))
}

is_hashuri <- function(uri) grepl("^https://sha256/", uri)

strip_prefix <- function(hash) gsub("^https://sha256/", "", hash)

cache_content <- function(content, hash, dir = hashuri_dir()){
  
  # life is easier when we hardwire the scheme and prefix, see issue #1
  hash <- strip_prefix(hash)
  
  ## Download content
  
  
  ## We might want the local content cache to create nested sub-directories from the hashes
  ## (like preston does?) for scalable performance?
  
}


## A configurable default location for persistent data storage
#' @importFrom rappdirs user_data_dir
hashuri_dir <- function(dir = 
                          Sys.getenv("HASHURI_DIR", 
                                     rappdirs::user_data_dir()
                                     )
                        ){
  dir
}