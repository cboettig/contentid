
# Rate limit remaining is:

swh_ratelimit <- function() {
  head <- httr::HEAD("https://archive.softwareheritage.org/api/1/")
  message(paste0(head$headers$`x-ratelimit-remaining`, "/",
                 head$headers$`x-ratelimit-limit`, " remaining"))
  
  reset <- as.integer(head$headers$`x-ratelimit-reset`)
  diff <- lubridate::as_datetime(reset) - Sys.time()
  if(diff > 0)
  message(paste("rate limit reset in", format(diff)))
}
# swh_ratelimit()
