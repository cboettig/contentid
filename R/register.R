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
#' @examples
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

  if (any(grepl("hash-archive", registries))) {
    remote <- registries[grepl("hash-archive", registries)]  
    ha_out <- vapply(remote, 
                     function(host) register_ha(url, host = host, ...),
                     character(1L)
                     )

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

#' default registries
#'
#' A helper function to conviently load the default registries
#' @details This function is primarily useful to restrict the
#' scope of [query_sources] or [register] to, e.g. either just the
#' remote registry or just the local registry.  Note that a user
#' can alter the registry on the fly by passing local paths and/or the
#' URL (`https://hash-archive.org`) directly.
#'
#' @examples
#' ## Both defaults
#' default_registries()
#'
#' ## Only the fist one (local registry)
#' default_registry()[1]
#' \donttest{
#' ## Alter the defaults with env var.
#' ## here we set two local registries as the defaults
#' Sys.setenv(CONTENTID_REGISTRIES = "store/, store2/")
#' default_registries()
#'
#' Sys.unsetenv(CONTENTID_REGISTRIES)
#' }
#' @noRd
# @export
default_registries <- function() {
  registries <- strsplit(
    Sys.getenv(
      "CONTENTID_REGISTRIES",
      paste(
        
        default_tsv(),                           ## local registry
        "https://hash-archive.org",              ## Hash Archives
        "https://archive.softwareheritage.org",  ## Only for query, not register
        content_dir(),                           ## Local stores
        sep = ", "
      )
    ),
    ", "
  )[[1]]

  registries
}



