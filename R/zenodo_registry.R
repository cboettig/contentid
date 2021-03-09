# md5 only for now
# id <- "hash://md5/eb5e8f37583644943b86d1d9ebd4ded5"
sources_zenodo <- function(id, host = "https://zenodo.org"){
  query <- "/api/records/?q=_files.checksum:"
  hash <- strip_prefix(id)
  algo <- extract_algo(id)
  checksum <- paste0('"', algo, ":", hash, '"')
  url <- paste0(host, query, checksum)
  resp <- httr::GET(url)
  sources <- httr::content(resp)
  if(length(sources) == 0){
    return(null_query())
  } 
  sources <- sources[[1]]
  
  ## The associated record may also have other files, match by id: 
  ids <- vapply(sources$files, `[[`, character(1L), "checksum")
  file <- sources$files[ids == hash][[1]]
  
  download_url <- file$links$download
  size <- file$filesize
  date <- sources$created
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


