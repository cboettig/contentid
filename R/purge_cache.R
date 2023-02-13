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
#' @param verbose show deleted file paths?
#' @inheritParams store
#' @return invisibly returns directory path
#' @export
purge_cache <- function(threshold="1G",
                        age = Inf, 
                        dir = content_dir(),
                        verbose = TRUE){

  ## Purge anything older than a certain date:
  index <- update_index(dir)
  used <- sum(index$size)
  if(verbose) {
    message(paste(fs::as_fs_bytes(used), "in use"))
  }
  
  
  stale <- index$modification_time <= (Sys.time() - age)
  if(any(stale)) {
    path <- index[stale,]$path
    for(p in path) {
      if(fs::file_exists((p))){ 
        if(verbose) message(paste("deleting", p))
        fs::file_delete(p)
      }
    }
  }
  
  ## Purge oldest files until below threshold
  index <- update_index(dir)

  threshold <- fs::as_fs_bytes(threshold)
  if(used < threshold) {
    return(invisible(dir))
  }
  
  cumulative <- cumsum(index$size)
  remove <- index$path[!(cumulative > threshold)]
  
  for(path in remove){
    if(fs::file_exists((path))){ 
      if(verbose) message(paste("deleting", path))
      fs::file_delete(path)
    }
  }
  
  
  if(verbose) {
    index <- update_index(dir)
    used <- sum(index$size)
    message(paste(fs::as_fs_bytes(used), "now in use"))
  }
  
  invisible(dir)
}



update_index <- function(dir = content_dir()){
  index <- fs::dir_info(dir, regexp = "\\w{2}/\\w{2}/.+",
                        recurse = TRUE, type="file")
  #index <- index[index$type != "directory",]
  index[order(index$modification_time),]
}

