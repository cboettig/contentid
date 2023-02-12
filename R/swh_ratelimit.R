
# Rate limit remaining is:

#' software heritage rate limit
#' @return remaining, total, and time until next reset are invisibly
#' returned as a data.frame.
#' @param verbose show messages about current rate limits?
#' Software Heritage has a rate limit that can interfere with common queries
#' (resolve sources, register) when large numbers of queries are made.
#' contentid functions will not automatically check against wait limits,
#' but may fall back to other registeries when available. 
#' @export
swh_ratelimit <- function(verbose=TRUE) {
  head <- httr::HEAD("https://archive.softwareheritage.org/api/1/")
  
  remaining <- as.integer(head$headers$`x-ratelimit-remaining`)
  total <- head$headers$`x-ratelimit-limit`
  
  if(verbose) {
    message(paste0(remaining, "/", total, " remaining"))
  }
  
  reset <- as.integer(head$headers$`x-ratelimit-reset`)
  wait <- as.POSIXlt(reset, origin="1970-01-01 UTC") - Sys.time()
  if(wait > 0){
    if(verbose) {
      message(paste("rate limit reset in", format(wait)))
    }
  }
  
  return(invisible(data.frame(remaining=remaining,
                              total=total,
                              wait=format(wait))))
}
# swh_ratelimit()
