library(httr)
library(purrr)
library(tibble)
library(readr)
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

local <- contenturi:::default_registries()[[1]]
register_ <- purrr::possibly(function(x) contenturi::register(x, registries = local),
                             otherwise = as.character(NA))



fs::dir_create("dataone")
plan(multiprocess)

ids <- furrr::future_map_chr(contentURLs, register_, .progress=TRUE)


## examine the results
# library(dplyr)
# input <- tibble(source = contentURLs)
# reg <- read_tsv(contenturi:::tsv_init())
# knb_mapped <- dplyr::left_join(input, reg) 
#
# Store results
# store("knb_registry.tsv.gz", "/zpool/content-store/")
# readr::write_tsv(knb_mapped, "/zpool/content-store/knb_registry.tsv.gz")
#
#



