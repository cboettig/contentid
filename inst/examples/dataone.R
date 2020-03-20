library(httr)
library(purrr)
library(tibble)
library(contenturi)

resp <- httr::GET("https://cn.dataone.org/cn/v2/query/solr/?q=datasource:*KNB&fl=identifier,checksum,checksumAlgorithm,replicaMN&wt=json")
result <- httr::content(resp, "parsed")
numFound <- result[[2]][["numFound"]]
rows <- 1000 # rows per page
n_calls <- numFound %/% rows

query <- paste0("https://cn.dataone.org/cn/v2/query/solr/?q=datasource:*KNB&fl=identifier,checksum,checksumAlgorithm,replicaMN&wt=json",
"&start=", rows*(0:n_calls), "&rows=", rows)

records <- lapply(query, httr::GET)
content <- lapply(records, httr::content, "parsed")

df <- purrr::map_dfr(content, function(x){ 
  purrr::map_dfr(x$response$docs, function(y){
    tibble::tibble(identifier = y$identifier, checksum = y$checksum, checksumAlgorithm = y$checksumAlgorithm)
  })
})


knb_base <- "https://knb.ecoinformatics.org/knb/d1/mn/v2/object/"
contentURLs <- paste0(knb_base, df$identifier)

# https://knb.ecoinformatics.org/knb/d1/mn/v2/object/resourceMap_knb.92033.3

library(furrr)
plan(multiprocess)

furrr::future_map_chr(contentURLs, contenturi::register, .progress=TRUE)


knb <- tibble::tibble(identifier = ids, source = contentURLs, date = Sys.time())
write_tsv(knb, "knb.tsv.gz")


