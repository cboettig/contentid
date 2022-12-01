
## Access content from a simple content-based store like "data.carlboettiger.info" or "deeplinker.bio"
## This provides trivial implementations for query_sources() and `retreive()` for such stores
## These methods require only `httr` and base R functions, no `contentid` functions.

## generic
query_sources.httpstore <- function(id, host, path_fn = identity){
  query <- paste(host, path_fn(id), sep = "/")
  resp <- httr::HEAD(query)
  code <- httr::status_code(resp)
  if(code >= 400L) return(NA_character_)

  # contentid:::registry_entry(id = id, source = query)

  data.frame(identifier = id, source = query, status = code, date = Sys.time())
}

retrieve.httpstore <- function(id, host, path_fn){
  sources_httpstore(id, host, path_fn)$source
}

strip_prefix <- function(x) sub("^hash://sha256/", "", x)
hash_path <- function(id){
  x <- strip_prefix(id)
  paste(substr(x, 1, 2),
        substr(x, 3, 4),
        x, sep = "/")

}



sources_boettiger <- function(id){
  query_sources.httpstore(id, host = "https://data.carlboettiger.info/data", path_fn = hash_path)
}

sources_deeplinker <- function(id){
  query_sources.httpstore(id, host = "https://deeplinker.bio", path_fn = strip_prefix)
}


## examples:

id <- "hash://sha256/496f800620dced0b1da54cfde869055c87d8199b192e4e92305308f0d1253f29"
sources_boettiger(id)

id2 <- "hash://sha256/fcc80ef5d19f6ae67a9966551bc8229d8113d9bbc4f6554e798bb1cdc071ab64"
sources_deeplinker(id2)

## unregistered content returns NA:
sources_boettiger(id2)

id3 <- 
sources_deeplinker(id3)

#contentid::query_sources(id3, "https://hash-archive.org")
#data <- contentid::resolve("hash://sha256/d981008d7c7dddd827bcba16087a9c88cf233567d4751f67bb7f96e0756f2c9c")
#unzip(data)
#eml <- EML::read_eml("eml.xml")
#occurance <- readr::read_tsv("occurrence.txt", quote="")

## Because these stores are read-only, we cannot register.httpstore() or store.httpstore)
