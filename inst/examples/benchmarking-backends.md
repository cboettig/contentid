
Benchmark some possible backends for the registry.

``` r
library(bench)
library(contentid) # remotes::install_github("cboettig/contentid", upgrade = TRUE)

knitr::opts_chunk$set(error=TRUE)
```

## Parsing directly

``` r
ref <- contentid::resolve("hash://sha256/598032f108d602a8ad9d1031a2bdc4bca1d5dca468981fa29592e1660c8f4883")
df <- read.delim(ref, stringsAsFactors = FALSE)


df <- dplyr::select(df, url = contentURL, id = checksum)
ex <- sample(df$url, 1e6)
```

## Base R

``` r
bench_time({
  id0 <- df[df$url %in% ex,]$id
})
```

    ## process    real 
    ##   651ms   652ms

## `dplyr`

``` r
library(dplyr)
```

    ## 
    ## Attaching package: 'dplyr'

    ## The following objects are masked from 'package:stats':
    ## 
    ##     filter, lag

    ## The following objects are masked from 'package:base':
    ## 
    ##     intersect, setdiff, setequal, union

``` r
bench_time({
  id1 <- df %>% filter(url %in% ex) %>% pull(id)
})
```

    ## process    real 
    ##   662ms   663ms

``` r
identical(id0, id1)
```

    ## [1] TRUE

``` r
## inner join is slower, and not literally the same thing
bench_time({
  id2 <- df %>% inner_join(tibble(url = ex)) %>% pull(id)
})
```

    ## Joining, by = "url"

    ## process    real 
    ##   2.36s   2.37s

``` r
identical(id0, id2)
```

    ## [1] FALSE

## `disk.frame`

A `fst`-file backed on disk storage with light-weigth dplyr semantics.

``` r
library(disk.frame, warn.conflicts = FALSE, quietly = TRUE)
```

    ## Registered S3 method overwritten by 'pryr':
    ##   method      from
    ##   print.bytes Rcpp

    ## 
    ## ## Message from disk.frame:
    ## We have 1 workers to use with disk.frame.
    ## To change that, use setup_disk.frame(workers = n) or just setup_disk.frame() to use the defaults.
    ## 
    ## 
    ## It is recommended that you run the following immediately to set up disk.frame with multiple workers in order to parallelize your operations:
    ## 
    ## 
    ## ```r
    ## # this will set up disk.frame with multiple workers
    ## setup_disk.frame()
    ## # this will allow unlimited amount of data to be passed from worker to worker
    ## options(future.globals.maxSize = Inf)
    ## ```

``` r
setup_disk.frame()
```

    ## The number of workers available for disk.frame is 12

``` r
#options(future.globals.maxSize = Inf) # wow memory issues quickly
```

``` r
df_con <- disk.frame::as.disk.frame(df)
bench::bench_time({ ##
  id3 <- df_con %>% filter(url %in% ex) %>% collect() %>% pull(id)
})
```

    ## process    real 
    ##   1.59m   3.49m

``` r
identical(sort(id0), sort(id3))
```

    ## [1] TRUE

## Thor

``` r
library(thor)
## set map size to ~ 4GB to be safe
## Thor persists to local db, but whole DB must be able to fit in RAM?
dbfile <- tempfile()
env <- thor::mdb_env(dbfile, mapsize = 1048576*4e3)
env$mput(df$url, df$id)
```

    ## NULL

``` r
bench_time({ # 
  id4 <- env$mget(ex) %>% as.character()
})
```

    ## process    real 
    ##   2.01s   2.01s

``` r
#identical(id0, id4)

fs::dir_info(dbfile) %>% pull(size) %>% sum()
```

    ## 894M

## `arrow`

  - Can use `.parquet` instead of `.tsv` as base file, is slightly
    faster than `vroom` on compressed `tsv`. (Reads in as a standard
    `data.frame`)
  - Offers on-disk option that we can query with `dplyr` syntax (can we
    forgo the `dplyr` dependency though?)  
  - the `dplyr` syntax is not DBI-based, and very hit-or-miss. `filter(x
    %in% ...)` semantics don’t always work (but don’t error?).
    `inner_join()` not implemented…

<!-- end list -->

``` r
library(arrow)
```

    ## 
    ## Attaching package: 'arrow'

    ## The following object is masked from 'package:utils':
    ## 
    ##     timestamp

``` r
library(dplyr, warn.conflicts = FALSE, quietly = TRUE)
pqt <- file.path(tempfile(), "arrow_dir", "df.parquet")
dir <- dirname(pqt)
dir.create(dir, recursive = TRUE)
write_parquet(df, pqt)

## parquet on disk w/ dplyr semantics
con_arw <- arrow::open_dataset(dir)
bench_time({  # 8.8s
  id5 <- con_arw %>% 
    # inner_join(tibble(url = ex), copy=TRUE) %>%  ## NO inner join
    filter(url %in% ex) %>% 
    collect() %>% pull(id)
})  
```

    ## process    real 
    ##   21.2s   20.6s

``` r
identical(id0, id5)
```

    ## [1] TRUE

``` r
## an in memory data.frame from parquet, but reading is quite fast!
bench_time({#  1.3s
df_pqt <- read_parquet(pqt)
})
```

    ## process    real 
    ##   3.15s    2.9s

``` r
fs::file_size(pqt)
```

    ## 562M

## `duckdb`

  - On disk, standard DBI interface.
  - not on
CRAN

<!-- end list -->

``` r
# install.packages("duckdb", repos=c("http://download.duckdb.org/alias/master/rstats/", "http://cran.rstudio.com"))
library(duckdb)
```

    ## Loading required package: DBI

``` r
ddir <- fs::path(fs::path_temp(), "duckdb", "duckdb1")
fs::dir_create(fs::path_dir(ddir))
con <- DBI::dbConnect( duckdb::duckdb(), dbdir = ddir)
DBI::dbWriteTable(con, "df", df)

bench_time({
  id6 <- tbl(con, "df") %>% inner_join(tibble(url = ex), by="url", copy = TRUE) %>% pull(id)
})
```

    ## process    real 
    ##   1.56s   1.59s

``` r
identical(id0, id6)
```

    ## [1] FALSE

``` r
bench_time({
  id6b <- tbl(con, "df") %>%  filter(url %in% ex) %>% pull(id)
})
```

    ## Error in .local(conn, statement, ...): duckdb_prepare_R: Failed to prepare query SELECT "id"
    ## FROM "df"
    ## WHERE ("url" IN ('https://merritt-aws.cdlib.org:8084/mn/v2/object/ark%3A%2F13030%2Fm5m32tpn%2F3%2Fcadwsap-s3610110-006-main.csv', 'https://cn.dataone.org/cn/v2/object/doi%3A10.6085%2FAA%2FALEXXX_015MTBD003R00_20051021.50.3', 'https://arcticdata.io/metacat/d1/mn/v2/object/urn%3Auuid%3A99277a51-a5ed-40b7-bb4d-9c1e9d1fae8a', 'https://datadryad.org/mn/v2/object/https%3A%2F%2Fdoi.org%2F10.5061%2Fdryad.5gk51p0%3Fformat%3Dd1rem%26ver%3D2018-08-21T23%3A18%3A15.438%2B00%3A00', 'https://gmn.lternet.edu/mn/v2/object/https%3A%2F%2Fpasta.lternet.edu%2Fpackage%2Freport%2Feml%2Flter-landsat-ledaps%2F6127%2F1', 'https://cn.dataone.org/cn/v2/object/http%3A%2F%2Fdx.doi.org%2F10.5061%2Fdryad.gj51n%2F1%3Fver%3D2016-03-01T19%3A23%3A37.195-05%3A00', 'https://data.piscoweb.org/catalog/d1/mn/v2/object/doi%3A10.6085%2FAA%2FBBYX00_XXXITBDXLSR03_20060227.40.1', 'https://pangaea-orc-1.dataone.org/mn/v2/object/1cdd1b536b1556ecd6734364fe47a8de', 'http

``` r
identical(id0, id6b)
```

    ## Error in identical(id0, id6b): object 'id6b' not found

``` r
dbDisconnect(con, shutdown=TRUE)
fs::dir_info(fs::path_dir(ddir)) %>% pull(size) %>% sum()
```

    ## 562M

## `MonetDBLite`

  - On disk, standard DBI interface.
  - no longer on
CRAN

<!-- end list -->

``` r
# install.packages("MonetDBLite", repo = "https://cboettig.github.io/drat")
library(MonetDBLite)
library(DBI)
library(dplyr)

mdir <- tempfile()
con2 <- DBI::dbConnect( MonetDBLite() , dbname = mdir)
DBI::dbWriteTable(con2, "df", df)

bench_time({
  id7 <- tbl(con2, "df") %>% inner_join(tibble(url = ex), copy = TRUE) %>% pull(id)
})
```

    ## Joining, by = "url"

    ## process    real 
    ##   7.64s   1.44s

``` r
identical(id0, id7)
```

    ## [1] FALSE

``` r
### fails if ex is a big vector

# bench_time({
#  id7b <- tbl(con2, "df") %>%  filter(url %in% ex) %>% pull(id)
#  })
# identical(id0, id7b)
```

``` r
DBI::dbDisconnect(con2, shutdown=TRUE)
rm(con2)
```

``` r
fs::dir_info(mdir, recurse=TRUE) %>% pull(size) %>% sum()
```

    ## 519M
