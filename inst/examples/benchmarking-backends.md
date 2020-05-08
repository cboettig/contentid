
Benchmark some possible backends for the registry.

``` r
library(bench)
library(contentid) # remotes::install_github("cboettig/contentid", upgrade = TRUE)
```

## Parsing directly

``` r
# ref <- contentid::resolve("hash://sha256/86df0d24994a34dfc5e638f8b378c1b6d52ff1a051c12d93aa04984c15bf9624")
ref <- contentid::resolve("hash://sha256/598032f108d602a8ad9d1031a2bdc4bca1d5dca468981fa29592e1660c8f4883")
df <- read.delim(ref, stringsAsFactors = FALSE)
```

# In-memory queries

Focus on a key-value pairing here

``` r
df <- dplyr::select(df, url = contentURL, id = checksum)
ex <- sample(df$url, 1e3)
```

## Base R

``` r
bench_time({ # 173ms
  id0 <- df[df$url %in% ex,]$id
})
```

    ## process    real 
    ##   215ms   215ms

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
bench_time({ # 
  id1 <- df %>% filter(url %in% ex) %>% pull(id)
})
```

    ## process    real 
    ##   220ms   220ms

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
    ##   292ms   292ms

``` r
identical(id0, id2)
```

    ## [1] TRUE

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
    ## 292.7ms   17.8s

``` r
identical(sort(id0), sort(id3))
```

    ## [1] TRUE

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
    ##   5.3ms  5.31ms

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
    ##   672ms   675ms

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
    ##   3.75s   3.43s

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
ddir <- tempfile()
con <- DBI::dbConnect( duckdb::duckdb() , dbdir = ddir)
DBI::dbWriteTable(con, "df", df)

bench_time({
  id6 <- tbl(con, "df") %>% inner_join(tibble(url = ex), by="url", copy = TRUE) %>% pull(id)
})
```

    ## process    real 
    ##   563ms   589ms

``` r
bench_time({
  id6b <- tbl(con, "df") %>%  filter(url %in% ex) %>% pull(id)
})
```

    ## process    real 
    ##   523ms   539ms

``` r
dbDisconnect(con, shutdown=TRUE)
```

``` r
identical(id0, id6)
```

    ## [1] FALSE

``` r
identical(id0, id6b)
```

    ## [1] TRUE

``` r
#fs::dir_info(ddir) %>% pull(size) %>% sum()
```

## `MonetDBLite`

  - On disk, standard DBI interface.
  - no longer on
CRAN

<!-- end list -->

``` r
# install.packages("MonetDBLite", repo = "https://cboettig.github.io/drat")
library(MonetDBLite)
mdir <- tempfile()
con <- DBI::dbConnect( MonetDBLite() , dbname = mdir)
DBI::dbWriteTable(con, "df", df)

bench_time({
  id7 <- tbl(con, "df") %>% inner_join(tibble(url = ex), copy = TRUE) %>% pull(id)
})
```

    ## Joining, by = "url"

    ## process    real 
    ##   872ms   194ms

``` r
bench_time({
  id7b <- tbl(con, "df") %>%  filter(url %in% ex) %>% pull(id)
})
```

    ## process    real 
    ##   1.58m   5.81s

``` r
dbDisconnect(con, shutdown=TRUE)
rm(con)
```

``` r
identical(id0, id7)
```

    ## [1] TRUE

``` r
identical(id0, id7b)
```

    ## [1] TRUE

``` r
#fs::dir_info(mdir) %>% pull(size) %>% sum()
```
