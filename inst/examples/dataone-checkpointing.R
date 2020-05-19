#remotes::install_github("cboettig/contentid", upgrade = TRUE)

tsv <- "/zpool/content-store/registry.tsv"
Sys.setenv("CONTENTID_REGISTRIES" = tsv)

## Re-load contentURLs from id_dataone_good
ref <- contentid::resolve("hash://sha256/b6728ebe185cb324987b380de74846a94a488ed3b34f10643cbe6f3d29792c73", "https://hash-archive.org")
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




############################################

ref <- contentid::resolve("hash://sha256/b6728ebe185cb324987b380de74846a94a488ed3b34f10643cbe6f3d29792c73", "https://hash-archive.org")
dataone_good <- vroom::vroom(ref, delim = "\t", col_select = c(contentURL)) 
dataone_good <-  dplyr::filter(dataone_good, !grepl("dryad", contentURL)) 

## Restart method
if(!file.exists("progress.tsv"))
  readr::write_tsv(data.frame(contentURL = NA), "progress.tsv")

done <- readr::read_tsv("progress.tsv", col_types = "c")
contentURLs <- dplyr::anti_join(dataone_good, done)[[1]]
#rm(dataone); rm(done)


for(x in contentURLs){
    message(x)
    Sys.sleep(1)
    readr::write_tsv(data.frame(contentURL = x), "progress.tsv", append=TRUE)
    id <- contentid::register(x,  c("https://hash-archive.carlboettiger.info", "https://hash-archive.org"))
    message(id)
}






















#########################################################




library(fs)
library(dplyr)
library(vroom)
library(contentid)

Sys.setenv("CONTENTID_REGISTRIES" = "/zpool/content-store")

registry_checkpoint <- contentid::resolve("hash://sha256/9b80bda501ca42e4b1d40f9bbc791b9703051703445ad369b7ee1a7e15fa986e", "https://hash-archive.org")
done <- vroom::vroom(paste0(contentid:::default_registries()[[1]], "/data/registry.tsv.gz"))

## Lots of errors on small files
d1_ref <- contentid::resolve("hash://sha256/598032f108d602a8ad9d1031a2bdc4bca1d5dca468981fa29592e1660c8f4883")
dataone <- vroom::vroom(d1_ref, delim = "\t") %>% mutate(size = fs::as_fs_bytes(size))

d1_reg <- left_join(
  done %>% select(-size),
  dataone,
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


