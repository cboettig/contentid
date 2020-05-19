
#' List all known URL sources for a given Content URI
#' 
#' @param id a content identifier
#' @inheritParams register
#' @param cols names of columns to keep. Default are `source` and `date`.  See details.
#' @param ... additional arguments
#' @return a data frame with all registration events when a URL or 
#' a local path (including the local store) have contained the corresponding content.
#' @seealso history register store
#' @details possible columns are (in order): `identifier`, `source`, `date`,
#' `size`, `status`, `md5`, `sha1`, `sha256`, `sha384`, `sha512` 
#' 
#' @export
#' @examples
#' \donttest{
#'
#' id <- paste0("hash://sha256/9412325831dab22aeebdd",
#'              "674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37")
#' query_sources(id)
#' 
#' }
#'
query_sources <- function(id, 
                          registries = default_registries(),
                          cols = c("source", "date"), 
                          ...){
  
  ha_out <- NULL
  tsv_out <- NULL
  lmdb_out <- NULL
  store_out <- NULL
  swh_out <- NULL
  
  ## Remote hash-archive.org type registries
  if (any(grepl("hash-archive.org", registries))){
    remote <- registries[grepl("hash-archive.org", registries)]
    ## Note: vectorization is unncessary here since currently only recognizes hash-archive.org domain
    ha_out <- lapply(remote, function(host) sources_ha(id, host = host))
    ha_out <- do.call(rbind, ha_out)
  }
  
  if (any(grepl("softwareheritage.org", registries))){
    remote <- registries[grepl("softwareheritage.org", registries)]
    ## Note: vectorization is unncessary here since currently only recognizes one domain
    swh_out <- lapply(remote, function(host) sources_swh(id, host = host))
    swh_out <- do.call(rbind, swh_out)
  }
  
  ## Local, tsv-backed registries
  if(any(is_path_tsv(registries))){
    local <- registries[is_path_tsv(registries)]
    tsv_out <- lapply(local, function(tsv) sources_tsv(id, tsv))
    tsv_out <- do.call(rbind, tsv_out)
  }
  
  ## Local, LMDB-backed registries
  if(any(is(registries, "mdb_env"))){
    local <- registries[is(registries, "mdb_env")]
    lmdb_out <- lapply(local, function(lmdb) sources_lmdb(id, lmdb))
    lmdb_out <- do.call(rbind, lmdb_out)
  }
  
  
  ## local stores are automatically registries as well
  if(any(dir.exists(registries))){
    stores <- registries[dir.exists(registries)]
    store_out <- lapply(stores, function(dir) sources_store(id, dir = dir))
    store_out <- do.call(rbind, store_out)
  }
  
  ## format return to show only most recent
  out <- rbind(ha_out, store_out, tsv_out, swh_out, lmdb_out)
  filter_sources(out, registries, cols)

}


filter_sources <- function(df, 
                           registries = default_registries(), 
                           cols = c("source", "date")
                           ){
  
  if(is.null(df)) return(df)
  
  id_sources <- most_recent_sources(df)
  
  ## Now, check history for all these URLs and see if the content is current 
  url_sources <- id_sources$source[is_url(id_sources$source)]
  history <- do.call(rbind, lapply(url_sources, query_history, registries = registries))
  
  recent_history <- most_recent_sources(history)
  out <- most_recent_sources(rbind(recent_history, id_sources))
  
  
  ## Sort local sources first. 
  ## (sort is stable so preserves previous order on ties)
  urls <- is_url(out$source)
  out <- out[order(urls),]
  
  ## Drop file paths that no longer exist -- maybe better to leave this to the user
  # missing <- !file.exists( out[!urls,]$source )
  # out[!urls,]$status[missing] <- NA_character_
  
  ## Drop sources where most recent call failed to resolve.  
  ## Alternately, we should return these, but:
  ## (1) list them last, and (2) list the status code too
  out$status[out$status >= 400L] <- NA_integer_
  out <- out[!is.na(out$status), ]
  row.names(out) <- NULL
  
  out[cols]
  
}

most_recent_sources <- function(df){
  
  if(is.null(df)) return(df)
  if(nrow(df) == 0) return(df)
  
  reg <- df[order(df$date, decreasing = TRUE),]
  unique_sources <- unique(reg$source)
  
  out <- registry_entry(id = reg$identifier[[1]], 
                        source = unique_sources, 
                        date = as.POSIXct(NA))
  
  for(i in seq_along(unique_sources)){
    out[i,] <- reg[reg$source == unique_sources[i], ][1,]
  }
  out
}




## could do more native implementation without the bagit-based i/o
## This reflects that the local store is implicitly a registry
sources_store <- bagit_query

