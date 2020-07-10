library(httr)
library(tidyverse)
library(tidyselect)
library(jsonlite)
library(xml2)
library(purrr)
library(vroom)
library(contentid)


## Set this to your perfered location (or use `contentid::content_dir()`)
Sys.setenv("CONTENTID_HOME" = "/minio/content-store")

## local registry will be based in CONTENTID_HOME now.  Also set default registry to be local only?
## Script will only store hash table here, objects are only streamed & not stored.
## Sys.setenv("CONTENTID_REGISTRIES" = "/minio/content-store")

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
vroom::vroom_write(dataone, "dataone.tsv.gz")
         
# Cache a copy                                                     
id_dataone <- contentid::store("dataone.tsv.gz")
id_dataone

############################################################################

## Many of the DataONE Member Nodes throw CURL errors due to expired TLS certificates etc.  
## Filter these cases out so we don't waste a lot of time attempting to access them.
## Dryad content URLs have all moved without redirects, so filter them out too

## loads registered snapshot (see dataone.R)
ref <- contentid::resolve("hash://sha256/769b1c83c9a4518f4863349af2774c00bfbaefa36b6daeed4c77c3bda220e241")
dataone <- vroom::vroom(ref, col_select = c(contentURL, baseURL)) 


baseURLs <- dataone %>% 
  filter(!grepl("dryad", contentURL))  %>% 
  select(baseURL) %>% 
  distinct() 

resp <- purrr::map(baseURLs[[1]], purrr::safely(httr::GET, list(status_code = -1)))
err_msg <- as.character(purrr::map(purrr::map(resp, "error"), "message"))

problems <- data.frame(domain = baseURLs[[1]], err_msg, stringsAsFactors = FALSE) %>% 
  filter(!grepl("^NULL", err_msg)) %>% 
  select(baseURL = domain)

dataone_good <- dataone %>% 
  select(baseURL, contentURL) %>% 
  anti_join(problems)  %>%
  select(contentURL) %>% 
  filter(!grepl("^NA/", contentURL))

#sum(grepl("usherbrooke", dataone$contentURL)) ## expect 0


## Store clean snapshot: only the good contentURLs 
vroom::vroom_write(dataone_good, "dataone_good.tsv.gz")
id_dataone_good <- contentid::store("dataone_good.tsv.gz")
id_dataone_good


###########################################################################################                                 
## start clean, support restarting
###########################################################################################
rm(list=ls())



library(dplyr)
###########################################

## Re-load contentURLs from id_dataone_good
ref <- contentid::resolve("hash://sha256/2e8be75709f6d0fce51c23cf2e799e9ba8673e5cb8fdf3204a863cc1a81d381a", store=TRUE)
dataone_good <- vroom::vroom(ref, delim = "\t", col_select = c(contentURL)) 
dataone_good <-  dplyr::filter(dataone_good, !grepl("dryad", contentURL)) 

## Restart method
if(!file.exists("progress.tsv"))
  readr::write_tsv(data.frame(contentURL = NA), "progress.tsv")

done <- readr::read_tsv("progress.tsv", col_types = "c")
contentURLs <- dplyr::anti_join(dataone_good, done)[[1]]
#rm(dataone_good); rm(done)


for(x in contentURLs){
  message(x)
  readr::write_tsv(data.frame(contentURL = x), "progress.tsv", append=TRUE)
  id <- contentid::register(x,  c("https://hash-archive.carlboettiger.info", "https://hash-archive.org"))
  message(id)
}



#######################################################################################
tsv <- "/minio/content-store/registry.tsv"
## Re-load contentURLs from id_dataone_good
ref <- contentid::resolve("hash://sha256/2e8be75709f6d0fce51c23cf2e799e9ba8673e5cb8fdf3204a863cc1a81d381a")
dataone_good <- vroom::vroom(ref, delim = "\t", col_select = c(contentURL)) 
dataone_good <-  dplyr::filter(dataone_good, !grepl("dryad", contentURL)) 
## Skip any URLs we have already registered
done <- vroom::vroom(tsv)
contentURLs <- dplyr::anti_join(dataone_good, done, by = c(contentURL = "source"))[[1]]

#rm(dataone_good); rm(done)

for(x in contentURLs){
  message(x)
  Sys.sleep(1)
  id <- contentid::register(x,  tsv, algos = c("md5","sha1","sha256"))
}

