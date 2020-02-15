#' Retrieve an object using the content identifier
#' 
#' Requested content can frequently be found at mutiple locations: cached to disk,
#' or available at one or more URLs.  This function provides a mechanism to always
#' return a single, local path to the content requested, (provided the content identifier
#' can be found in at least one of the registries). 
#' 
#' @param uri A content identifier or URL
#' @param prefer Order of preference if multiple matches are found. See details.
#' @param verify logical, default `[TRUE]`. Should we verify the 
#' returned content matches the requested hash?
#' @inheritParams query
#' @details preference
#' @seealso query
#' @export
retrieve <- function(uri, 
                     prefer = c("local", "url"), 
                     verify = TRUE,
                     registries = c("remote", "local"), ...){
  
  df <- query(uri, registries, ...)
  
  ## Sort by date
  
  ## select most recent URL or local path
  
  if(verify){
    ## If we are downloading the resource
    download_resource(url)
    
    ## Fallback to next avialable source if download_resource fails?
    
    ## Does verify also update the registry if downloading from a URL?
  }
  ## Download and verify?
  
}


