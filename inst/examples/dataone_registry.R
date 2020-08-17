

#' @examples \donttest{
#' id <- paste0("hash://md5/e27c99a7f701dab97b7d09c467acf468")
#' sources_dataone(id)
#' }
sources_dataone <- function(id, baseURL = "https://cn.dataone.org/cn/"){
  hash <- gsub("^hash://\\w+/", "", id)
  query <- paste0(baseURL, "/v2/query/solr/","?q=checksum:",hash,
                  "&fl=identifier,size,formatId,checksum,checksumAlgorithm,",
                  "replicaMN,dataUrl&rows=10&wt=json")
  resp <- httr::GET(query)
  out <- httr::content(resp)
  sources <- lapply(out$response$docs, `[[`,"dataUrl")[[1]]
  size <- lapply(out$response$docs, `[[`,"size")[[1]]
  
  data.frame(id = id, source = sources, date = Sys.Date(), size = size)
}


retrieve_dataone <- function(id, baseURL = "https://cn.dataone.org/cn/"){
  df <- sources_dataone(id, baseURL)
  df$source
}

## We can also "register" an identifier at dataone by depositing the data object.
## This requires the `dataone` R package and an authentication token -- so
## rather beyond the scope of a small `contentid` package.
register_dataone <- function(file){
  
}


