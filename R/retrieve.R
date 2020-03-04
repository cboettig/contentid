
#' Retrieve files from the local cache
#' 
#' @param id a [content_uri]
#' @inheritParams store
#' @return path to a local copy of the file. 
#' 
#' @export
#' @seealso store
#' @examples
#'
#' # Store & retrieve local file
#' vostok_co2 <- system.file("extdata", "vostok.icecore.co2",
#'                           package = "contenturi")
#'  id <- store(vostok_co2)
#'  retrieve(id)
#'  
#' \donttest{
#'  # Store and retrieve content from a URL 
#' id <- store("https://zenodo.org/record/3678928/files/vostok.icecore.co2")
#' retrieve(id)
#' }
#'
retrieve <- function(id, dir = app_dir()) {
  if (!is_content_uri(id)){ 
    stop(paste(id, "is not a recognized content uri"), call. = FALSE)
  }
  
  path <- content_based_location(id, dir)
  
  if (!file.exists(path)) {
    warning(paste("No stored file found for", id, "in", dir), call. = FALSE)
    return(NULL)
  }
  
  ## We could call `file(path)` instead, but would make assumptions about how
  ## we were reading the content that are better left to the user?
  path
}


store_list <- function(dir = app_dir()){
  fs::dir_info(path = fs::path(dir, "data"), recurse = TRUE, type = "file")
}

store_delete <- function(ids, dir = app_dir()){
  lapply(ids, function(id){ 
    path <- content_based_location(id, dir)
    fs::file_delete(path)
  })
}
