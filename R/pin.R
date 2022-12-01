
#' Access the latest content at a URL (DEPRECATED)
#' 
#'  This will download the requested object to a local cache and return the local path of the 
#'  object.  first time it is run, and then use a local cache
#'  unless content has changed. This behavior is similar to `pins::pin()`,
#'  but uses cryptographic content hashes. Because content hashes are computed in a fast public 
#'  content registry, this will usually be faster than downloading on a local connection,
#'  but slower than checking eTags in headers.  Use [resolve]
#' @seealso resolve
#' @param url a URL to a web resource
#' @param verify logical, default TRUE. Should we verify the content identifier (SHA-256 hash)
#' of content at the URL before we look for a local cache?
#' @inheritParams resolve 
#' @details at this time, verify mode cannot process FTP resources.
#' Use verify = FALSE to enable a fast read from cache. This essentially allows
#' a URL to act as an identifier, and is a good choice for URLs known to be version
#' stable.  If verify = FALSE, this will merely attempt to find a local copy of data
#' previously associated (registered) at that URL. It will not attempt
#' to compute the content identifier of the content at the URL, thus the
#' local copy may or may not match the content at that address.
#' @export 
#'
pin <- function(url, 
                verify = TRUE, 
                dir = content_dir(), 
                registries = "https://hash-archive.org") {
  
  if(!verify){
    return(unverified_resolver(url, dir))
  }
  
  # Have hash-archive.org compute the identifier. Its high bandwidth
  # and fast processors will probably do so faster than local computation
  
  id <- register(url, registries = registries)
  if(is.na(id)){
    warning(paste("Unable to register", url), call.=FALSE)
    return(NA)
  }
  ## resolve the current content id.  If it matches a cached copy, resolve
  ## will use that.  If it does not, resolve will download the latest version
  resolve(id, registries = registries, store = TRUE, dir = dir)
}



unverified_resolver <- function(url, dir = content_dir()){
  
    id <- store(url, dir = dir)
    resolve(id, dir = dir)
  
}

