# Exploring potential new concepts / work in progress

library(contentid) # bc we're just in inst/examples/, not R/

#' Memoise file-based workflows
#'  
#' Memoise functions that take file-based workflows: file in, file out
#' If the input file is already in the registry, the function `f` is
#' simply not evaluated. 
#' This assumes that the output it generates 
#'
#' @examples
#' csv_to_json <- function(path, output = "out.json"){
#'    df <- read_csv(path)
#'    json <- jsonlite::to_json(df)
#'    write_json(json, output)
#' }
#'
#' mem_csv_to_json <- memoise_prov(csv_to_json)
#'  
memoise_prov <- function(f, 
                         paths, 
                         ..., 
                         registries = default_registries()) {
  # See if paths are in local content registry
  
  
  ## involves downloading the files... may as well use store?
  ids <- content_id(f)
  
  
  if(has_paths) return(invisible(TRUE))
  # If paths are not found
  f(paths, ...)
}


#' Check if a URL or path is present in a local metadata registry
previously_seen <- function(x, tsv = default_tsv()) {
  df <- history_tsv(x, tsv)
  
  
}

x <- "https://minio.cirrus.carlboettiger.info/shared-data/fishbase/fb_parquet_2021-06/species.parquet"

# Should we try and store these metadata?
# Consider content-type, last-modified, etag, content-length to decide if is the same object?
x <- "https://minio.thelio.carlboettiger.info/shared-data/dataone-hashes.tsv"

url_meta <- function(x){
  resp <- httr::HEAD(x)
  meta <- httr::headers(resp)
  tibble::tibble(source = x, 
                 size = meta$`content-length`, 
                 etag = meta$etag, 
                 type = meta$`content-type`,
                 date = meta$`last-modified`)
}


fs_meta <- function(x){
  meta <- fs::file_info(x)
  tibble::tibble(source = x, 
                 size = meta$size, 
                 date = meta$modification_time)
}

