library(httr)
library(tidyverse)
library(tidyselect)
library(jsonlite)
library(xml2)


library(contentid)


#knb_solr_api <- "https://knb.ecoinformatics.org/knb/d1/mn/v2/query/solr/"

# central node
dataone_solr_api <- "https://cn.dataone.org/cn/v2/query/solr/"

q <- paste0(dataone_solr_api,
       "?q=*:*&fl=",
       "identifier,checksum,checksumAlgorithm,replicaMN,size,formatId,dateModified",
       "&wt=json")
resp <- httr::GET(q)
result <- httr::content(resp, "parsed")
numFound <- result[[2]][["numFound"]]
rows <- 1000 # rows per page
n_calls <- numFound %/% rows

query <- paste0(q, "&start=", rows*(0:n_calls), "&rows=", rows)


records <- lapply(query, httr::GET)
content <- lapply(records, httr::content, "parsed")

df <- purrr::map_dfr(content, function(x){ 
  purrr::map_dfr(x$response$docs, function(y){
    tibble::tibble(identifier = y$identifier, checksum = y$checksum, checksumAlgorithm = y$checksumAlgorithm,
                   size = y$size,formatId = y$formatId, dateModified = y$dateModified,
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

#########
#dataone %>% count(node, sort = TRUE)

## See table of node base_urls etc at https://cn.dataone.org/cn/v2/node
member_nodes <- GET("https://cn.dataone.org/cn/v2/node")
xml <- content(member_nodes)

nodes <- tibble(node = xml_find_all(xml, "//identifier") %>%  xml_text(),
                baseURL = xml_find_all(xml, "//baseURL") %>%  xml_text()) 

## WTF URLencode is not vectorized and doesn't error or warn on vector.. 
## also damn slow, maybe regex would be faster here.  
# url_encode <- function(x) map_chr(x, utils::URLencode, reserved = TRUE)

dataone <-
  dataone %>%
  left_join(nodes) %>% 
  mutate(contentURL = paste0(baseURL, 
                             "/v2/object/", xml2::url_escape(identifier))) 



# contentid::store("dataone.tsv.gz", "/zpool/content-store/")
# id: "hash://sha256/f445beccc9c13d03580ee689bbe25ac2dccf52a179ad7fa0b02ade53f772c66e" stored


## inspect 
# dataone %>% count()
# dataone %>% summarise(total = sum(size))

## let's do the small ones first.
dataone <- dataone %>% arrange(size)
readr::write_tsv(dataone, "dataone.tsv.gz")
                                                              
contentid::store("dataone.tsv.gz")                          
# "hash://sha256/c7b8f1033213f092df630e9fc26cd6d941f2002c95ab829f0180903bc0cdcd50"

#######################################                                 
## start clean
######################################

## still doesn't free memory!
rm(list=ls())
gc()
rstudioapi::restartSession()

#dataone <- vroom::vroom(ref, n_max = 100)
#head(dataone)

library(contentid)

ref <- resolve("hash://sha256/c7b8f1033213f092df630e9fc26cd6d941f2002c95ab829f0180903bc0cdcd50")
#dataone <- readr::read_tsv()
contentURLs <- vroom::vroom(ref, col_select = c(contentURL))[[1]]


## Add progress
p2 <- dplyr::progress_estimated(length(contentURLs))
register_remote_progress <- function(x){
  p2$tick()$print()
  register(x, "https://hash-archive.org")
}

## Register at hash-archive.org (slow!)
for(x in contentURLs) register_remote_progress(x)





## Add progress
p1 <- dplyr::progress_estimated(length(contentURLs))
register_local_progress <- function(x){
  p1$tick()$print()
  register(x, "/zpool/content-store")
}
## Register locally
ids <- purrr::map_chr(contentURLs, register_local_progress)




## examine the results
# library(dplyr)
# input <- tibble(source = contentURLs)
# reg <- read_tsv(contentid:::tsv_init())
# knb_mapped <- dplyr::left_join(input, reg) 
#
# Store results
# store("knb_registry.tsv.gz", "/zpool/content-store/")
# readr::write_tsv(knb_mapped, "/zpool/content-store/knb_registry.tsv.gz")
#
#



