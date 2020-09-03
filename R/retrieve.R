
#' Retrieve files from the local cache
#' 
#' @param id a [content_id]
#' @inheritParams store
#' @return path to a local copy of the file. 
#' 
#' @export
#' @seealso store
#' @examples
#'
#' \dontshow{ ## Real users won't use a temporary dir
#' Sys.setenv("CONTENTID_REGISTRIES" = tempdir())
#' }
#' 
#' # Store & retrieve local file
#' vostok_co2 <- system.file("extdata", "vostok.icecore.co2",
#'                           package = "contentid")
#'  id <- store(vostok_co2)
#'  retrieve(id)
#'  
#' \donttest{
#'  # Store and retrieve content from a URL 
#' id <- store(paste0("https://knb.ecoinformatics.org/knb/d1/mn/v2/object/",
#' "ess-dive-457358fdc81d3a5-20180726T203952542"))
#' retrieve(id)
#' }
#'
#' \dontshow{ ## Real users won't use a temporary dir
#' Sys.unsetenv("CONTENTID_REGISTRIES")
#' }
#' 
retrieve <- function(id, dir = content_dir()) {
  
  # vectorize 
  vapply(id, function(id){
    id <- as_hashuri(id)
    if(is.na(id)){
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
  }, character(1L), USE.NAMES = FALSE)
}


store_list <- function(dir = content_dir()){
  fs::dir_info(path = fs::path(dir, "data"), recurse = TRUE, type = "file")
}

store_delete <- function(ids, dir = content_dir()){
  lapply(ids, function(id){ 
    path <- content_based_location(id, dir)
    fs::file_delete(path)
  })
}
