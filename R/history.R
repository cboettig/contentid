
#' List all content identifiers that have been seen at a given URL
#' 
#' @param url A URL for a data file
#' @inheritParams register
#' @param ... additional arguments
#' @return a data frame with all content identifiers that have been seen
#' at a given URL.  If the URL is version-stable, this should be a single 
#' identifier.  Note that if multiple identifiers are listed, older content
#' may no longer be available, though there is a chance it has been registered
#' to a different url and can be resolved with `[sources]`.
#' @seealso sources
#' @export
#' @examples
#' \donttest{
#' 
#' history("https://zenodo.org/record/3678928/files/vostok.icecore.co2")
#' 
#' }
#'
history <- function(url, registries = default_registries(), ...){
  
  ha_out <- NULL
  reg_out <- NULL

  ## Remote host registries  (hash-archive.org type only)
  if (any(is_url(registries))){
    remote <- registries[is_url(registries)]
    ha_out <- lapply(remote, function(host) history_ha(url, host = host))
    ha_out <- do.call(rbind, ha_out)
  }
  
  
  local <- registries[dir.exists(registries)]
  reg_out <- lapply(local, function(dir) history_tsv(url, dir = dir))
  reg_out <- do.call(rbind, reg_out)
  rbind(ha_out, reg_out)
  
  
}


## Consider a DBI-backed registry
