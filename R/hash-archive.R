## https://hash-archive.org API provides three endpoints:
## sources, history, and enqueue (register) that we plug into our generic functions

sources_ha <- function(id, host = "https://hash-archive.org", ...){
  ## don't require hash://sha256 format -- hash archive understands many other formats
  #if(!is_content_id(id)) stop(paste("id", id, "is not a valid content URI"), call. = FALSE)
  hash_archive_api(id, "api/sources", host)
}

history_ha <- function(url, host = "https://hash-archive.org", ...){
  if(!is_url(url)) stop(paste("url", url, "is not a valid URL"), call. = FALSE)
  
  hash_archive_api(url, "api/history", host)
}

## use ... to swallow additional args
register_ha <- function(url, host = "https://hash-archive.org", ...) {
  
  if(grepl("^ftp", url)){
    warning(paste("hash-archive.org cannot retreive data from ftp...\n",
                  "skipping", url))
    return(NA_character_)
  }
  
  if(!is_url(url)) return(NA_character_)
  
  endpoint <- "api/enqueue"
  request <- paste(host, endpoint, url, sep = "/")
  limit <- getOption("contentid_register_timeout", 2)
  response <- tryCatch(
    httr::GET(request, httr::timeout(limit)),
    error = function(e){
      warning(paste(e), call. = FALSE)
      NA
    },
    finally = NA
  )
  if(all(is.na(response))) return(NA_character_)
  httr::stop_for_status(response)
  result <- httr::content(response, "parsed", "application/json")
  

  out <- format_hashachiveorg(result)
  out$identifier
}




#' @importFrom httr GET content stop_for_status
hash_archive_api <- function(query, endpoint, host = "https://hash-archive.org"){
  
  # Host un-resolvable
  status <- check_url(host)
  if(status >= 400) return(data.frame())
  
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
  
  if(length(x$hashes) == 0)
    return(  registry_entry(NA_character_, x$url,
                            date = .POSIXct(x$timestamp, tz = "UTC"), 
                            size = x$length, status = x$status)
    )
  
  hash <- openssl::base64_decode(sub("^sha256-", "", x$hashes[[3]]))
  identifier <- add_prefix(paste0(as.character(hash), collapse = ""))
  
  registry_entry(identifier, 
                 x$url,
                 date = .POSIXct(x$timestamp, tz = "UTC"), 
                 size = x$length,
                 status = x$status,
                 md5 = x$hashes[[1]],
                 sha1 = x$hashes[[2]],
                 sha256 = x$hashes[[3]],
                 sha384 = x$hashes[[4]],
                 sha512 = x$hashes[[5]])
  
  ## Note that hash-archive.org also provides:
  ## (1) type, (2) status (3) size
}

