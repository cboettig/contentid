#' Purge older files from the local cache.
#' 
#' Deletes oldest files until cache size is below the threshold size.
#' Additionally, users can specify a maximum age in days to delete all
#' files older than the threshold, which can speed up file purge in large
#' stores. Setting either age and threshold to 0 will purge everything from 
#' cache.
#' 
#' Default behavior will keep `contentid`'s local store size below 1 GB.
#' Note that `contentid` functions do not automatically call purge_cache(),
#' this must be handled by user workflows.
#' @param age Maximum age in days
#' @param threshold Threshold size, accepts `[fs::fs_bytes]` notation.
#' @inheritParams store
#' @return invisibly returns dir path
#' @export
purge_cache <- function(threshold="1G", age = Inf, dir = content_dir()){

  ## Purge anything older than a certain date:
  index <- update_index(dir)
  stale <- index$modification_time <= (Sys.time() - age)
  if(any(stale))
    fs::file_delete(index[stale,]$path)
  
  ## Purge oldest files until below threshold
  i <- 1
  index <- update_index(dir)
  while(sum(index$size) > threshold){
    fs::file_delete(index$path[i])
    i <- i+1
  }
  invisible(dir)
}



update_index <- function(dir){
  index <- fs::dir_info(dir, regexp = "\\w{2}/\\w{2}/.+", recurse = TRUE)
  index <- index[index$type != "directory",]
  index[order(index$modification_time),]
}

