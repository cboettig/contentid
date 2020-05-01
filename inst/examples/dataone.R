library(httr)
library(tidyverse)
library(tidyselect)
library(jsonlite)
library(xml2)
library(purrr)
library(furrr)
library(vroom)
library(contentid)


## Set this to your perfered location (or use `contentid::content_dir()`)
## Script will only store hash table here, objects are only streamed & not stored.
local_registry <- "/zpool/content-store"



## Do full DataONE
dataone_solr_api <- "https://cn.dataone.org/cn/v2/query/solr/"
## or do just KNB with:
# knb_solr_api <- "https://knb.ecoinformatics.org/knb/d1/mn/v2/query/solr/"

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


## Here we go, page through full SOLR query
records <- lapply(query, httr::GET)



content <- lapply(records, httr::content, "parsed")
df <- purrr::map_dfr(content, function(x){ 
  purrr::map_dfr(x$response$docs, function(y){
    tibble::tibble(identifier = y$identifier, checksum = y$checksum, 
                   checksumAlgorithm = y$checksumAlgorithm,
                   size = y$size,formatId = y$formatId, 
                   dateModified = y$dateModified,
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

dataone <-
  dataone %>%
  left_join(nodes) %>% 
  mutate(contentURL = paste0(baseURL, 
                             "/v2/object/", 
                             xml2::url_escape(identifier))) 

## let's do the small ones first.
dataone <- dataone %>% arrange(size)
readr::write_tsv(dataone, "dataone.tsv.gz")
         
# Cache a copy                                                     
id_dataone <- contentid::store("dataone.tsv.gz", local_registry)
id_dataone

############################################################################

## Many of the DataONE Member Nodes throw CURL errors due to expired TLS certificates etc.  
## Filter these cases out so we don't waste a lot of time attempting to access them.
## Dryad content URLs have all moved without redirects, so filter them out too

baseURLs <- dataone %>% 
  filter(!grepl("dryad", contentURL))  %>% 
  select(baseURL) %>% 
  distinct() 

resp <- map(baseURLs[[1]], purrr::safely(httr::GET, list(status_code = -1)))
err_msg <- as.character(lapply(lapply(resp, "error"), "message"))

problems <- data.frame(domain = baseURLs[[1]], err_msg, stringsAsFactors = FALSE) %>% 
  filter(!grepl("^NULL", err_msg)) %>% 
  select(baseURL = domain)

dataone_good <- dataone %>% 
  select(baseURL, contentURL) %>% 
  anti_join(problems)  %>%
  select(contentURL) %>% 
  filter(!grepl("^NA/", contentURLs))

#sum(grepl("usherbrooke", dataone$contentURL)) ## expect 0


## Store clean snapshot: only the good contentURLs 
readr::write_tsv(dataone_good, "dataone_good.tsv.gz")
id_dataone_good <- contentid::store("dataone_good.tsv.gz", local_registry)
id_dataone_good


###########################################################################################                                 
## start clean, support restarting
###########################################################################################
rm(list=ls())


## Re-load contentURLs from id_dataone_good
ref <- contentid::resolve("hash://sha256/c7b8f1033213f092df630e9fc26cd6d941f2002c95ab829f0180903bc0cdcd50")
contentURLs <- vroom::vroom(ref, col_select = c(contentURL))[[1]]

## Skip any URLs we have already registered
done <- vroom::vroom(paste0(local_registry, "/data/registry.tsv.gz"))
contentURLs <- dplyr::anti_join(dataone, done, by = c(contentURL = "source"))[[1]]
rm(dataone); rm(done)



## errors as NAs
register_local_progress <- function(x){
  tryCatch(
    contentid::register(x,
                        local_registry,
                        algos = c("md5","sha1","sha256")),
    error = function(e) NA_character_,
    finally = NA_character_
  )
}

### AND here we go!
library(furrr)
plan(multicore)
out <- furrr::future_map_chr(contentURLs, register_local_progress, .progress = TRUE)



## Also, register these URLs with hash-archive.org
out <- furrr::future_map_chr(contentURLs, contentid::register, registries = "https://hash-archive.org", .progress = TRUE)
