
#' Access the latest content at a URL
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
#' @examples \donttest{
#' 
#' url <- paste0("https://data.giss.nasa.gov/gistemp/graphs/graph_data/",
#'        "Global_Mean_Estimates_based_on_Land_and_Ocean_Data/graph.txt")
#'        
#' x <- pin(url)
#' 
#' ## Faster if we're okay assuming URL is content-stable
#' x <- pin(url, verify = FALSE)
#' }
pin <- function(url, verify = TRUE, dir = content_dir()) {
  
  if(!verify){
    return(unverified_resolver(url, dir))
  }
  
  # Have hash-archive.org compute the identifier. Its high bandwidth
  # and fast processors will probably do so faster than local computation
  
  id <- register(url, registries = "https://hash-archive.org")
  
  ## resolve the curent content id.  If it matches a cached copy, resolve
  ## will use that.  If it does not, resolve will download the latest version
  resolve(id, store = TRUE, dir = dir)
}



unverified_resolver <- function(url, dir){
  url_history <- query(url) # should take a list of registries!
  
  ## No url_history for this URL
  if(nrow(url_history) == 0){
    message("No history for the URL in the registry.\n Downloading to local store now...")
    id <- store(url, dir = dir)
    return(resolve(id, store = TRUE, dir = dir))
  }
  
  ids <- unique(url_history$identifier)
  
  ## Only one content id registered, so let's just go with that
  if(length(ids) == 1){
    message(paste("Found registered content with id\n", ids, 
                  "\n Did not verify this ID matches content at\n", url,
                  "\n but resolving anyway since unverified copy requested..."))
    return(resolve(ids, store = TRUE, dir = dir))
  }
  
  ## We have multiple registered ids. What should we do?
  ##   What if we have a local copy, but there's newer content registered?  
  ##   Let's just grab the most rescent one
  id <- url_history[order(url_history$date, decreasing = TRUE),]$identifier[[1]]
  
  message(paste("Multiple versions of content have been registered at\n",
                url, "\n  Trying the most recent content with id\n", id,
                "\n Request a specific version using its content identifer instead."))
  
  return(resolve(id, store = TRUE, dir = dir))
  
}

