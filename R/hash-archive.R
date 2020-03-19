

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

sources_ha <- function(id, host = "https://hash-archive.org"){
  if(!is_content_uri(id)) stop(paste("id", id, "is not a valid content URI"), call. = FALSE)
  hash_archive_api(id, "api/sources", host)
}

history_ha <- function(url, host = "https://hash-archive.org"){
  if(!is_url(url)) stop(paste("url", url, "is not a valid URL"), call. = FALSE)
  
  hash_archive_api(url, "api/history", host)
}

