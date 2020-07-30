
#' List all content identifiers that have been seen at a given URL
#' 
#' [query_history] is the complement of [query_sources], in that it filters a table
#' of content identifier : url : date entries by the url. 
#' 
#' @param url A URL for a data file
#' @inheritParams register
#' @param ... additional arguments
#' @return a data frame with all content identifiers that have been seen
#' at a given URL.  If the URL is version-stable, this should be a single 
#' identifier.  Note that if multiple identifiers are listed, older content
#' may no longer be available, though there is a chance it has been registered
#' to a different url and can be resolved with [query_sources].
#' @seealso sources
#' @export
#' @importFrom methods is
#' @examples

#' \dontshow{ ## Real users won't use a temporary dir
#' Sys.setenv("CONTENTID_REGISTRIES" = tempdir())
#' }
#' 
#' \donttest{ 
#' query_history(paste0("https://knb.ecoinformatics.org/knb/d1/mn/v2/object/",
#' "ess-dive-457358fdc81d3a5-20180726T203952542"))
#' }
#' 
#' \dontshow{ ## Real users won't use a temporary dir
#' Sys.unsetenv("CONTENTID_REGISTRIES")
#' }
#' 
#'
query_history <- function(url, registries = default_registries(), ...){
  
  ha_out <- NULL
  tsv_out <- NULL
  lmdb_out <- NULL

  ## Remote host registries  (hash-archive.org type only)
  if (any(grepl("hash-archive.org", registries))){
    remote <- registries[grepl("hash-archive.org", registries)]  
    ha_out <- lapply(remote, function(host) history_ha(url, host = host))
    ha_out <- do.call(rbind, ha_out)
  }
  
  if(any(is(registries, "mdb_env"))){
    local <- registries[is(registries, "mdb_env")]
    lmdb_out <- lapply(local, function(lmdb) history_lmdb(url, lmdb))
    lmdb_out <- do.call(rbind, lmdb_out)
  }
  
  
  ## Local, tsv-backed registries
  if(any(is_path_tsv(registries))){
    local <- registries[is_path_tsv(registries)]
    tsv_out <- lapply(local, function(tsv) history_tsv(url, tsv = tsv))
    tsv_out <- do.call(rbind, tsv_out)
  }
  
  rbind(ha_out, tsv_out, lmdb_out)
  
}
