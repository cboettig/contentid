

MIXED <- c("tsv", "lmdb") # Can store local paths or URLS
REMOTES <- c("hash-archive", "softwareheritage", "dataone", "zenodo")

#' List all known URL sources for a given Content URI
#' 
#' @param id a content identifier
#' @inheritParams register
#' @param cols names of columns to keep. Default are `source` and `date`.
#'  See details.
#' @param all should we query remote registries even if a local source is found?
#'  Default TRUE
#' @param ... additional arguments
#' @return a data frame with all registration events when a URL or 
#' a local path (including the local store) have contained the corresponding
#' content.
#' @seealso history register store
#' @details possible columns are (in order): `identifier`, `source`, `date`,
#' `size`, `status`, `md5`, `sha1`, `sha256`, `sha384`, `sha512` 
#' 
#' @export
#' @importFrom curl has_internet
#' @aliases sources, query_sources
#' @examplesIf interactive()
#' 
#' \dontshow{ ## Real users won't use a temporary dir
#' Sys.setenv("CONTENTID_REGISTRIES" = tempdir())
#' Sys.setenv("CONTENTID_HOME" = tempdir())
#' }
#' \donttest{
#'
#' id <- paste0("hash://sha256/9412325831dab22aeebdd",
#'              "674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37")
#' sources(id)
#' 
#' }
#' \dontshow{ ## Real users won't use a temporary dir
#' Sys.unsetenv("CONTENTID_REGISTRIES")
#' Sys.unsetenv("CONTENTID_HOME")
#' }
sources <- function(id, 
                          registries = default_registries(),
                          cols = c("source", "date"), 
                          all = TRUE,
                          ...){
  
  registries <- expand_registry_urls(registries)
  types <- detect_registry_type(registries)
  
  ## Try local stores first (content_store type)
  active_registries <- registries[types == "content_store"]
  out <- generic_source(id, registries = active_registries, type = "content_store")
  
  ## Check remote sources only if no hits, or all sources are requested
  if(all(is.na(out$source)) | all) {
    remote <- types[types %in% c(MIXED,REMOTES)]
    ## Call sources_fn on each recognized registry type
    remote_out <- lapply(remote, function(type){
      active_registries <- registries[types == type]
      generic_source(id, registries = active_registries, type = type)
    })
    remote_out <- do.call(rbind, remote_out)
  out <- rbind(out, remote_out)
  }

  # filter out:
  # - duplicate id-source pairs, 
  # - any urls later seen with different content
  # - sort by local-first, then by date
  filter_sources(out, registries, cols)
}

query_sources <- sources

## Map (closure) to select the sources_* function for the type
known_sources <- function(type){ 
  switch(type,
         "hash-archive" = sources_ha,
         "dataone" = sources_dataone,
         "zenodo" = sources_zenodo,
         "softwareheritage" = sources_swh,
         "tsv" = sources_tsv,
         "lmdb" = sources_lmdb,
         "content_store" = sources_store,
         function(id, host) NULL
  )
}
## Try known sources of a given type
## lapply+rbind to support, e.g. two .tsv registries (same type)
generic_source <- function(id, registries, type){
  out <- lapply(registries, 
                function(host){
                  tryCatch(known_sources(type)(id, host),
                           error = function(e) warning(e),
                           finally = NULL)
                })
  do.call(rbind,out)
}



## Map short names into recognized URL endpoints
expand_registry_urls <- function(registries) {
  registries[grepl("^dataone$", registries)] <- "https://cn.dataone.org"
  registries[grepl("^hash-archive$", registries)] <- "https://hash-archive.org"
  registries[grepl("softwareheritage", registries)] <- "https://archive.softwareheritage.org"
  registries[grepl("zenodo", registries)] <- "https://zenodo.org"
  registries
}
## Map URLs and paths to corresponding short names
detect_registry_type <- function(registries) {
  registries[grepl("dataone", registries)] <- "dataone"
  registries[grepl("hash-archive", registries)] <- "hash-archive"
  registries[grepl("softwareheritage", registries)] <- "softwareheritage"
  registries[grepl("zenodo", registries)] <- "zenodo"
  registries[is_path_tsv(registries)] <- "tsv"
  registries[is(registries, "mdb_env")] <- "lmdb"
  registries[dir.exists(registries)] <- "content_store"
  registries
}



# For a single identifier, some registries (tsv and hash-archive) can contain
# many entries resolving that same ID to the same URL (on different dates -- i.e.
# different "sightings" of the data at the same spot.)  We only want the most recent.
# 
# Some registries (tsv and hash-archive) will report URLs which are later observed
# to be failing (i.e. have different content or error msg).  Checking query_history
# on the URL first confirms if the URL still contains the desired content.  
#
# Lastly, we want to sort local matches first, and then sort by date of most recent first
# 
filter_sources <- function(df, 
                           registries = default_registries(), 
                           col = c("source", "date")
                           ){
  
  if(is.null(df)) return(df)
  if(nrow(df) == 0) return(df)
  
  ## drop data without sources
  df <- df[!is.na(df$source),]
  
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
  
  out[col]
  
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



sources_store <- function(id, dir = content_dir()){
  source = content_based_location(id, dir)
  if(file.exists(source)){
    registry_entry(id = id, 
                   source = source, 
                   date = fs::file_info(source)$modification_time
                   )
  } else {
    registry_entry(id = id, status=404)
  }
}

