#' register a URL with remote and/or local registries
#'
#' @param url a URL for a data file (or list of URLs)
#' @param registries list of registries at which to register the URL
#' @param ... additional arguments
#' @details Local registries can be specified as one or more file paths
#'  where local registries should be created.  Usually a given application
#'  will want to register in only one local registry.  For most use cases,
#'  the default registry should be sufficient.
#' @return the [httr::response] object for the request (invisibly)
#' @importFrom stats na.omit
#' @export
#' @examplesIf interactive()
#' 
#' 
#' \dontshow{ ## Real users won't use a temporary dir
#' Sys.setenv("CONTENTID_REGISTRIES" = tempdir())
#' }
#'  
#' \donttest{
#' 
#' register(paste0("https://knb.ecoinformatics.org/knb/d1/mn/v2/object/",
#' "ess-dive-457358fdc81d3a5-20180726T203952542"))
#' }
#'
#' \dontshow{ ## Real users won't use a temporary dir
#' Sys.unsetenv("CONTENTID_REGISTRIES")
#' }
#' 
#'
register <- function(url, registries = default_registries(), ...) { 
  
  vapply(url, register_, character(1L), registries = registries, ..., USE.NAMES = FALSE)

}


register_ <- function(url, registries = default_registries(), ...) { 
  
  tsv_out <- NULL
  ha_out <- NULL
  lmdb_out <- NULL
  registries <- expand_registry_urls(registries)
  

  if(curl::has_internet()){
    if (any(grepl("hash-archive", registries))) {
      if(!file.exists(url)){ # don't register local files
        remote <- registries[grepl("hash-archive", registries)]  
        ha_out <- vapply(remote, 
                         function(host) register_ha(url, host = host, ...),
                         character(1L)
                         )

      }
    }
  }
  if(any(is_path_tsv(registries))){
    local <- registries[is_path_tsv(registries)]
    tsv_out <- vapply(local, 
                      function(tsv) register_tsv(url, tsv = tsv, ...),
                      character(1L)
                      )
  }
  
  if(any(is(registries, "mdb_env"))){
    local <- registries[is(registries, "mdb_env")]
    lmdb_out <- vapply(local, 
                      function(lmdb) register_lmdb(url, lmdb, ...),
                      character(1L)
    )
  }
  
  
  ## should be same hash returned from each registration
  out <- assert_unique_id(c(tsv_out, ha_out, lmdb_out))
  out
  
}

is_path_tsv <- function(x){ grepl("[.]tsv$", x) }

assert_unique_id <- function(x) {
  out <- as.character(stats::na.omit(unique(x)))
  if(length(out) == 0L) return(NA_character_)
  out
}




