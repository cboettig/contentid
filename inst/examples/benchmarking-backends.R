
ref <- contentid::resolve("hash://sha256/86df0d24994a34dfc5e638f8b378c1b6d52ff1a051c12d93aa04984c15bf9624")


library(bench)

bench_time( # 5.8s
df <- read.table(ref, col.names = c("url", "id"), stringsAsFactors = FALSE)
)
bench_time({ # 11.6s
    shadow <- tempfile(fileext = ".tsv.gz")
    fs::link_create(ref,shadow)
    df <- readr::read_tsv(shadow, col_names = c("url", "id"), col_types = "cc")
})
bench_time( # 1.7s
  df <- vroom::vroom(ref, col_names = c("url", "id"))
)




ex <- sample(df$id, 1e6)

bench_time({ # 173ms
  urls0 <- df[df$id %in% ex,]$url
})


library(thor)
## set map size to ~ 4GB to be safe
## NOTE-- content-hashes are not good unique keys -- same content may be found at multiple URLs
## Thor persists to local db, but whole DB must be able to fit in RAM?
env <- thor::mdb_env(tempfile(), mapsize = 1048576*4e3)
env$mput(df$id, df$url)

bench_time({ # 997ms 
  urls1 <- env$mget(ex) %>% as.character()
})


library(dplyr)
bench_time({ # 137ms
  urls2 <- df %>% filter(id %in% ex) %>% pull(url)
})

## inner join is slower, and not literally the same thing
bench_time({
  urls2b <- df %>% inner_join(tibble(id = ex)) %>% pull(url)
})


library(disk.frame)
df_con <- disk.frame::as.disk.frame(df)
bench::bench_time({ ## 1.64s
  urls5 <- df_con %>% filter(id %in% ex) %>% collect() %>% pull(url)
})

library(arrow)
pqt <- file.path(tempfile(), "arrow_dir", "df.parquet")
dir <- dirname(pqt)
dir.create(dir, recursive = TRUE)
write_parquet(df, pqt)

## in memory data.frame from parquet
bench_time({#  1.3s
df_pqt <- read_parquet(pqt)
})

## parquet on disk w/ dplyr semantics
con_arw <- arrow::open_dataset(dir)
bench_time({  # 8.8s
  # WTF WHERE IS MY DATA?  returns empty tibble
  urls6 <- con_arw %>% 
    # inner_join(tibble(id = ex), copy=TRUE) %>%  ## NO inner join
    #filter(id %in% ex) %>%                       ## filter doesn't have %in% maybe?
    collect() %>% pull(url)
})  
  


# install.packages("duckdb", repos=c("http://download.duckdb.org/alias/master/rstats/", "http://cran.rstudio.com"))
library(duckdb)
dir <- tempfile()
con <- DBI::dbConnect( duckdb::duckdb() , dbdir = dir)
DBI::dbWriteTable(con, "df", df)

bench_time({
  urls3 <- tbl(con, "df") %>% inner_join(tibble(id = ex), by="id", copy = TRUE) %>% pull(url)
})
dbDisconnect(con, shutdown=TRUE)





library(MonetDBLite)
dir <- tempfile()
con <- DBI::dbConnect( MonetDBLite() , dbname = dir)
DBI::dbWriteTable(con, "df", df)

bench_time({
  urls4 <- tbl(con, "df") %>% inner_join(tibble(id = ex), copy = TRUE) %>% pull(url)
})

dbDisconnect(con, shutdown=TRUE)
rm(con)


## fails
#bench_time({
#  urls3b <- tbl(con, "df") %>% filter(id %in% ex) %>% pull(url)
#})

#DBI::dbWriteTable(con, "ex", tibble(id = ex))
#bench_time({
#  urls3b <- tbl(con, "df") %>% inner_join(tbl(con, "ex"), by="id") %>% pull(url)
#})


