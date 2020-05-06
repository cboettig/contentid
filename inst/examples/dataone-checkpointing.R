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



## Lots of errors on small files
d1_ref <- contentid::resolve("hash://sha256/598032f108d602a8ad9d1031a2bdc4bca1d5dca468981fa29592e1660c8f4883")
dataone<- vroom::vroom(d1_ref, delim = "\t")
contentURLs <- 
  tibble(contentURL = contentURLs) %>% 
  inner_join(dataone)  %>%
  mutate(size = as_fs_bytes(size)) 
#%>% 
#  filter(size < as_fs_bytes("1M")) %>%
#  pull(contentURL) 
#rm(dataone)
