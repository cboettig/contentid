


# @examples \donttest{
# id <- "hash://md5/e27c99a7f701dab97b7d09c467acf468"
# sources_dataone(id)
# }
sources_dataone <- function(id, host = "https://cn.dataone.org"){
  hash <- gsub("^hash://\\w+/", "", id)
  query <- paste0(host, "/cn/v2/query/solr/","?q=checksum:",hash,
                  "&fl=identifier,size,formatId,checksum,checksumAlgorithm,",
                  "replicaMN,dataUrl&rows=10&wt=json")
  
  sources <- tryCatch({
    resp <- httr::GET(query)
    out <- httr::content(resp)
    sources <- lapply(out$response$docs, `[[`,"dataUrl")
  },
    error = function(e){ 
      message(e)
      list()
    },
    finally = list()
  )
  if(length(sources) == 0){
    return(null_query())
  } 
  sources <- sources[[1]]
  size <- lapply(out$response$docs, `[[`,"size")[[1]]
  out <- registry_entry(id, source = sources, date = Sys.time(), size = size)
  out
}

# @examples \donttest{
# id <- paste0("hash://md5/e27c99a7f701dab97b7d09c467acf468")
# sources_dataone(id)
# }
# 
retrieve_dataone <- function(id, host = "https://cn.dataone.org"){
  df <- sources_dataone(id, host)
  df$source
}

## We can also "register" an identifier at dataone by depositing the data object.
## This requires the `dataone` R package and an authentication token -- so
## rather beyond the scope of a small `contentid` package.


