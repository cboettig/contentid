library(httr)
library(tidyverse)
library(tidyselect)
library(contenturi)

resp <- httr::GET("https://cn.dataone.org/cn/v2/query/solr/?q=*:*&fl=identifier,checksum,checksumAlgorithm,replicaMN&wt=json")
result <- httr::content(resp, "parsed")
numFound <- result[[2]][["numFound"]]
rows <- 1000 # rows per page
n_calls <- numFound %/% rows

query <- paste0("https://cn.dataone.org/cn/v2/query/solr/?q=*:*&fl=identifier,checksum,checksumAlgorithm,replicaMN&wt=json",
"&start=", rows*(0:n_calls), "&rows=", rows)

records <- lapply(query, httr::GET)
content <- lapply(records, httr::content, "parsed")

df <- purrr::map_dfr(content, function(x){ 
  purrr::map_dfr(x$response$docs, function(y){
    tibble::tibble(identifier = y$identifier, checksum = y$checksum, checksumAlgorithm = y$checksumAlgorithm, 
                   replicaMN = paste(y$replicaMN, collapse = ","))
  })
})

rep = c("rep1", "rep2", "rep3", "rep4", "rep5", "rep6", "rep7", "rep8", "rep9", "rep10", "rep11")
dataone <- df %>%
  tidyr::separate(replicaMN, 
                  all_of(rep),
                  sep = ",") %>% 
  tidyr::pivot_longer(rep, names_to = "rep", values_to = "node") %>%
  filter(!is.na(node)) %>% select(-rep)
  
readr::write_tsv(dataone, "dataone.tsv.gz")

dataone %>% count(node, sort = TRUE)

## See table of node base_urls etc at https://cn.dataone.org/cn/v2/node

knb <- dataone %>% filter(node == "urn:node:KNB")

knb_base <- "https://knb.ecoinformatics.org/knb/d1/mn/v2/object/"
contentURLs <- paste0(knb_base, knb$identifier)

# https://knb.ecoinformatics.org/knb/d1/mn/v2/object/resourceMap_knb.92033.3

## define fail-safe flavors for the 401 errors
local <- contenturi:::default_registries()[[1]]
register_local <- purrr::possibly(function(x) contenturi::register(x, registries = local),
                             otherwise = as.character(NA))


register_remote <- purrr::possibly(function(x) contenturi::register(x, registries = "https://hash-archive.org"),
                                  otherwise = as.character(NA))


fs::dir_create("dataone")
plan(multiprocess)

## Register locally
ids <- furrr::future_map_chr(contentURLs, register_local, .progress=TRUE)

## Register at hash-archive.org (slower)
ids2 <- furrr::future_map_chr(contentURLs, register_remote, .progress=TRUE)


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



