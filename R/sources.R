
#' List all known URL sources for a given Content URI
#' 
#' @param id a content identifier
#' @inheritParams register
#' @param ... additional arguments
#' @return a data frame with all registration events when a URL or 
#' a local path (including the local store) have contained the corresponding content.
#' @seealso history register store
#' @export
#' @examples
#' \donttest{
#'
#' id <- paste0("hash://sha256/9412325831dab22aeebdd",
#'              "674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37")
#' sources(id)
#' 
#' }
#'
sources <- function(id, registries = default_registries(), ...){
  
  ha_out <- NULL
  reg_out <- NULL
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
  local <- registries[dir.exists(registries)]
  reg_out <- lapply(local, function(dir) sources_tsv(id, dir = dir))
  reg_out <- do.call(rbind, reg_out)
  
  ## local stores are automatically registries as well
  store_out <- lapply(local, function(dir) sources_store(id, dir = dir))
  store_out <- do.call(rbind, store_out)
  
  
  rbind(ha_out, store_out, reg_out)
  
  
}



## could do more native implementation without the bagit-based i/o
sources_store <- bagit_query

