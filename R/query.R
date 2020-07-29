
#' query a Content URI or a URL with remote and/or local registries
#'
#' @param uri a content identifier or a regular URL for a data file
#' @inheritParams register
#' @param ... additional arguments
#' @return a data frame with matching results
#' @export
#' @examples
#' \donttest{
#'
#' ## By content identifier
#' query(paste0("hash://sha256/9412325831dab22aeebdd",
#'              "674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37"))
#' ## By (registered) URL
#' query(paste0("https://knb.ecoinformatics.org/knb/d1/mn/v2/object/",
#' "ess-dive-457358fdc81d3a5-20180726T203952542"))
#' }
#'
query <- function(uri, registries = default_registries(), ...) {
  
  
  if(is_url(uri)){
    query_history(uri, registries = registries, ...)
  } else {
    query_sources(uri, registries = registries, ...)
  }
    
}





