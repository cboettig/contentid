
#' Retrieve files from the local cache
#' 
#' @param id a [content_id]
#' @inheritParams store
#' @return path to a local copy of the file. 
#' 
#' @export
#' @seealso store
#' @examplesIf interactive()
#'
#' \dontshow{ ## Real users won't use a temporary dir
#' Sys.setenv("CONTENTID_REGISTRIES" = tempdir())
#' Sys.setenv(CONTENTID_HOME=tempdir())
#' }
#' 
#' # Store & retrieve local file
#' vostok_co2 <- system.file("extdata", "vostok.icecore.co2",
#'                           package = "contentid")
#'  id <- store(vostok_co2)
#'  retrieve(id)
#'
#' \dontshow{ ## Real users won't use a temporary dir
#' Sys.unsetenv("CONTENTID_REGISTRIES")
#' Sys.unsetenv("CONTENTID_HOME")
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
      return(NA_character_)
    }
    
    ## We could call `file(path)` instead, but would make assumptions about how
    ## we were reading the content that are better left to the user?
    path
  }, character(1L), USE.NAMES = FALSE)
}



# function not in use...
store_list <- function(dir = content_dir(), algos = default_algos()){
  # include symlinks? 
  fs::dir_info(path = fs::path(dir, algos), recurse = TRUE, type = "file")
}



store_delete <- function(ids, dir = content_dir()){
  lapply(ids, function(id){ 
    path <- content_based_location(id, dir)
    fs::file_delete(path)
  })
}
