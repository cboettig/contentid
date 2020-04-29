




library(contentid)
library(vroom)
library(dplyr)
library(parallel)
library(purrr)
library(httr)


#########################

### SKIP this block, start with pre-filtered version below ##

## loads registered snapshot (see dataone.R)
ref <- contentid::resolve("hash://sha256/598032f108d602a8ad9d1031a2bdc4bca1d5dca468981fa29592e1660c8f4883", registries = "/zpool/content-store")
dataone <- vroom::vroom(ref, col_select = c(contentURL, baseURL)) %>% filter(!grepl("dryad", contentURL))

## Discover and prune failing domains
baseURLs <- dataone %>% select(baseURL) %>% distinct() 
resp <- map(baseURLs[[1]], purrr::safely(httr::GET, list(status_code = -1)))
err_msg <- as.character(map(map(resp, "error"), "message"))
problems <- data.frame(domain = baseURLs[[1]], err_msg, stringsAsFactors = FALSE) %>% filter(!grepl("^NULL", err_msg))
dataone_good <- dataone %>% anti_join(select(problems, domain), by = c("baseURL" = "domain"))  %>% select(contentURL)
#sum(grepl("usherbrooke", dataone$contentURL)) ## expect 0


## Store clean snapshot: only the good contentURLs 
readr::write_tsv(dataone_good, "dataone_good.tsv.gz")
contentid::store("dataone_good.tsv.gz", "/zpool/content-store")

rm(baseURLS); rm(resp); rm(err_msg); rm(problems);  gc()

######################
library(contentid)
library(vroom)
library(dplyr)
library(parallel)
library(purrr)
library(httr)

## Start with registered contentURL list and omit the ones already in registry:

ref2 <- contentid::resolve("hash://sha256/2b961ccaac6068ed42ea34c1968d237af1b81cd16511ee0848e3ed5f0e573656", registries = "/zpool/content-store")
dataone <- vroom::vroom(ref2, col_select = c(contentURL))

done <- vroom::vroom("/zpool/content-store/data/registry.tsv.gz")

contentURLs <- dplyr::anti_join(dataone, done, by = c(contentURL = "source"))[[1]]
rm(dataone); rm(done); gc()


bad <- grepl("^NA/", contentURLs)
contentURLs <- contentURLs[!bad]

p1 <- dplyr::progress_estimated(length(contentURLs))
register_local_progress <- function(x){
  p1$tick()
  if(p1$i %% 5000 == 0) gc() # not clear that this helps any...
  
  tryCatch(
    register(x,
                    "/zpool/content-store",
                    algos = c("md5","sha1","sha256")),
           error = function(e) NA_character_,
           finally = NA_character_)
  
}

### May run out of memory
library(furrr)
plan(multicore)
furrr::future_map_chr(contentURLs, register_local_progress, .progress = TRUE)

## Hmm, this seems to leak memory too, only slower than furrr.  seeems to download data slower than furrr too...
 
#mclapply(contentURLs, register_local_progress, mc.cores =  parallel::detectCores())




## Register locally
#i <- p1$i + 1 # resume
#for(x in contentURLs[i:length(contentURLs)]) register_local_progress(x)

######################



library(contentid)
library(vroom)
library(dplyr)

ref <- contentid::resolve("hash://sha256/c7b8f1033213f092df630e9fc26cd6d941f2002c95ab829f0180903bc0cdcd50")
contentURLs <- vroom::vroom(ref, col_select = c(contentURL)) %>% filter(!grepl("dryad", contentURL)) %>% pull(contentURL)

gc()

p2 <- dplyr::progress_estimated(length(contentURLs))
register_remote_progress <- function(x){
  p2$tick()$print()
  tryCatch(register(x,
                    "https://hash-archive.org"),
           error = function(e) NA_character_,
           finally = NA_character_)
}

library(parallel)
mclapply(contentURLs, register_remote_progress, mc.cores = parallel::detectCores())





