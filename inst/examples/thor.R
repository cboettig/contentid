library(contentid)
library(readr)
library(thor)
library(dplyr)
deeplinker_registry <- resolve("hash://sha256/86df0d24994a34dfc5e638f8b378c1b6d52ff1a051c12d93aa04984c15bf9624")

library(arkdb)


db <- local_db()

## readr fails, it doesn't like the multibyte string in this file...
## note we could stream this, a la arkdb
df <- read.table(deeplinker_registry, 
                 col.names = c("url", "identifier"),
                 stringsAsFactors = FALSE) %>% 
  as_tibble()
df %>% filter(grepl("http://api.gbif.org/v1/occurrence/download/request/", url)) %>% distinct()


pryr::object_size(df) ## note this is noticably bigger with stringsAsFactors = FALSE




library(thor)
curl::curl_download("https://data.carlboettiger.info/data/86/df/86df0d24994a34dfc5e638f8b378c1b6d52ff1a051c12d93aa04984c15bf9624", "test.tsv.gz")
df <- read.table("test.tsv.gz", col.names = c("url", "id"), stringsAsFactors = FALSE)

library(dplyr)
df %>% mutate(host = gsub("(http://.*)/.*$", "\\1", url)) %>% count(host, sort = TRUE)


env <- thor::mdb_env(tempfile())
env$mput(df$id, df$url)
#Error in thor_mput(txn_ptr, db$.ptr, key, value, overwrite, append) : 
#  Error in mdb: MDB_MAP_FULL: Environment mapsize limit reached: thor_mput -> mdb_put (code: -30792)
