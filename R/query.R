
#' query a Content URI or a URL with remote and/or local registries
#'
#' DEPRECATED, please use [sources()] or [history_url()]
#' @param uri a content identifier or a regular URL for a data file
#' @inheritParams register
#' @param ... additional arguments
#' @return a data frame with matching results
#' @export
#'
query <- function(uri, registries = default_registries(), ...) {
  
  
  if(is_url(uri)){
    history_url(uri, registries = registries, ...)
  } else {
    sources(uri, registries = registries, ...)
  }
    
}





