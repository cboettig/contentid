
## helper functions to avoid documentation errors

ping <- function(url){
  all(vapply(url, 
         function(u){
           tryCatch(
           httr::status_code(httr::HEAD(u)) < 300,
           error = function(e) FALSE,
           finally = FALSE)
           },
         logical(1))
  )
  
    
}

#' has_resource
#' 
#' Helper function to ensure examples do not execute when internet 
#' resource is temporarily unavailable, as in such cases rendering
#' the example does not provide a reliable check.  This allows 
#' examples ("tests") to "fail gracefully".
#' @param url vector of URL resources required
#' @examples 
#' has_resource("https://google.com")
#' 
#' @export
has_resource <- function(url = NULL){
  if(!is.null(url))
    curl::has_internet() && ping(url)
  else 
    curl::has_internet()
}
  
