rm(list=ls())
library(dplyr)
#remotes::install_github("cboettig/contentid@more-tests", upgrade = TRUE)

Sys.setenv("CONTENTID_REGISTRIES" = "/zpool/content-store")
## Re-load contentURLs from id_dataone_good
ref <- contentid::resolve("hash://sha256/b6728ebe185cb324987b380de74846a94a488ed3b34f10643cbe6f3d29792c73")
dataone_good <- vroom::vroom(ref, delim = "\t", col_select = c(contentURL)) %>% 
  filter(! grepl("dryad", contentURL)) %>% 
  filter( ! grepl("https://arcticdata.io/metacat/d1/mn", contentURL))

## Skip any URLs we have already registered
done <- vroom::vroom(paste0(contentid:::default_registries()[[1]], "/data/registry.tsv.gz"))
contentURLs <- dplyr::anti_join(dataone_good, done, by = c(contentURL = "source"))[[1]]

rm(dataone_good); rm(done)

## errors as NAs
register_local_progress <- function(x){
  tryCatch(
    contentid::register(x,
                        algos = c("md5","sha1","sha256")),
    error = function(e) NA_character_,
    finally = NA_character_
  )
}

parallel::mclapply(contentURLs, register_local_progress, mc.cores = 2)




##

library(fs)
library(dplyr)
library(vroom)
library(contentid)

Sys.setenv("CONTENTID_REGISTRIES" = "/zpool/content-store")

done <- vroom::vroom(paste0(contentid:::default_registries()[[1]], "/data/registry.tsv.gz"))

## Lots of errors on small files
d1_ref <- contentid::resolve("hash://sha256/598032f108d602a8ad9d1031a2bdc4bca1d5dca468981fa29592e1660c8f4883")
dataone <- vroom::vroom(d1_ref, delim = "\t") %>% mutate(size = fs::as_fs_bytes(size))

d1_reg <- left_join(
  done %>% select(-size),
  dataone %>% select(contentURL, size),
  by = c("source" = "contentURL")
  )

d1_reg %>% 
  vroom::vroom_write("~/dataone_registry.tsv.gz")

id <- contentid::store("~/dataone_registry.tsv.gz", "/zpool/content-store/")
id

"https://data.carlboettiger.info/data/7a/62/7a62443df4472c1c340ef6e60f3949e9e79be73d3d7e60897107fb25d9bb3552"


d1_reg %>% count(status)
d1_reg %>% group_by(status) %>% summarise(total_size = sum(size, na.rm = TRUE))
dataone %>% filter( ! grepl("https://arcticdata.io/metacat/d1/mn", contentURL)) %>% summarise(total = sum(size))

d1_in <- dataone %>% left_join(select(done, -size, -identifier), by = c(contentURL = "source"))


