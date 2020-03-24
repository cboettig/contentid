## https://hash-archive.org API provides three endpoints:
## sources, history, and enqueue (register) that we plug into our generic functions

sources_ha <- function(id, host = "https://hash-archive.org"){
  ## don't require hash://sha256 format -- hash archive understands many other formats
  #if(!is_content_uri(id)) stop(paste("id", id, "is not a valid content URI"), call. = FALSE)
  hash_archive_api(id, "api/sources", host)
}

history_ha <- function(url, host = "https://hash-archive.org"){
  if(!is_url(url)) stop(paste("url", url, "is not a valid URL"), call. = FALSE)
  
  hash_archive_api(url, "api/history", host)
}

register_ha <- function(url, host = "https://hash-archive.org") {
  
  if(grepl("^ftp", url)){
    warning(paste("hash-archive.org cannot retreive data from ftp...\n",
                  "skipping", url))
    return(as.character(NA))
  }
  
  endpoint <- "api/enqueue"
  request <- paste(host, endpoint, url, sep = "/")
  response <- httr::GET(request)
  httr::stop_for_status(response)
  result <- httr::content(response, "parsed", "application/json")
  

  out <- format_hashachiveorg(result)
  out$identifier
}




#' @importFrom httr GET content stop_for_status
hash_archive_api <- function(query, endpoint, host = "https://hash-archive.org"){
  request <- paste(host, endpoint, query, sep = "/")
  response <- httr::GET(request)
  httr::stop_for_status(response)
  
  result <- httr::content(response, "parsed", "application/json")
  out <- lapply(result, format_hashachiveorg)
  
  ## base alternative dplyr::bind_rows
  do.call(rbind, lapply(out, as.data.frame, stringsAsFactors = FALSE))
}


## a formatter for data returned by hash-archive.org
#' @importFrom openssl base64_decode
format_hashachiveorg <- function(x) {
  hash <- openssl::base64_decode(sub("^sha256-", "", x$hashes[[3]]))
  identifier <- add_prefix(paste0(as.character(hash), collapse = ""))
  list(
    identifier = identifier,
    source = x$url,
    date = .POSIXct(x$timestamp, tz = "UTC")
  )
  ## Note that hash-archive.org also provides:
  ## (1) type, (2) status, and other hash-flavors
  ## We do not return these
}

