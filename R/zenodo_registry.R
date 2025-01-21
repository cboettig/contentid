# md5 only for now
# id <- "hash://md5/eb5e8f37583644943b86d1d9ebd4ded5"
# sources_zenodo(id)
sources_zenodo <- function(id, host = "https://zenodo.org"){
  query <- "/api/records?q=files.entries.checksum:"
  hash <- strip_prefix(id)
  algo <- extract_algo(id)
  
#  if(!grepl("md5", algo)){
#    if(getOption("verbose", FALSE))
#    message("Zenodo only supports MD5 checksums at this time")
#    return(null_query())
#  }
  
  checksum <- curl::curl_escape(paste0('"', algo, ":", hash, '"'))
  url <- paste0(host, query, checksum, '&allversions=true')
  
  sources <- tryCatch({
    resp <- httr::GET(url)
    httr::stop_for_status(resp)
    sources <- httr::content(resp)
    },
    error = function(e){
      warning(e)
      list()
    },
    finally = list()
  )
  
  if(length(sources) == 0){
    return(null_query())
  } 
  
  if(sources$hits$total == 0){
    return(null_query())
  } 
  
  matches <- sources$hits$hits[[1]]

  ## The associated record may also have other files, match by id: 
  ids <- vapply(matches$files, `[[`, character(1L), "checksum")
  raw_ids <- gsub("\\w+:", "", ids)
  item <- matches$files[raw_ids == hash]
  
  if(length(item) != 1) {
    stop(paste("ids", paste0(ids, collapse=", "), "not matching hash", hash))
  }
  file <- item[[1]]
  
  download_url <- file$links$self
  size <- file$size
  date <- matches$created
  out <- registry_entry(id, source = download_url, size =size, date = date)
  out
}

# @examples \donttest{
# id <- "hash://md5/e27c99a7f701dab97b7d09c467acf468"
# sources_zenodo(id)
# }
# 
retrieve_zenodo <- function(id, host = "https://zenodo.org"){
  df <- sources_zenodo(id, host)
  df$source
}

## We can also "register" an identifier at zenodo by depositing the data object.
## rather beyond the scope of a small `contentid` package.


