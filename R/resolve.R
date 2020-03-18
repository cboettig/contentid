#' Resolve content from a content identifier
#'
#' Requested content can be found at mutiple locations:
#'  cached to disk, or available at one or more URLs.  This function
#'  provides a mechanism to always return a single, local path to the
#'  content requested, (provided the content identifier can be found in
#'  at least one of the registries).
#'
#' @param id A content identifier, see `[content_uri]`
#' @param verify logical, default `[TRUE]`. Should we verify that
#'  downloaded content matches the requested hash?
#' @param verify_local logical, default `[FALSE]`. Should we verify
#'  that local content matches the requested hash?
#'  contenturi's `store` is indexed by content identifier,
#'  so we can skip this step if we trust the integrity of
#'  the local disk storage.
#' @param store logical, should we add remotely downloaded copy to the local store?
#' @param dir path to the local store directory
#' @inheritParams query
#' @details Local storage
#'  is checked first as it will allow us to bypass downloading content
#'  when a local copy is available. If no local copy is found but 
#'  one or more remote URLs are registered for the hash, downloads 
#'  from these will be attempted in order from most recent first.
#' @seealso query query_local query_remote
#' @examples
#'
#' # ensure some content in local storage for testing purposes:
#' vostok_co2 <- system.file("extdata", "vostok.icecore.co2",
#'                           package = "contenturi")
#' store(vostok_co2)
#'
#' 
#' resolve(paste0(
#'  "hash://sha256/9412325831dab22aeebdd6",
#'  "74b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37")
#' )
#' 
#' @export
resolve <- function(id,
                    registries = default_registries(),
                    verify = TRUE,
                    verify_local = FALSE,
                    store = FALSE,
                    dir = content_dir(),
                    ...) {
  
  prefer = c("local", "remote")
  df <- query(id, registries, ...)
  ## rev() so higher priority -> higher number (we sort descending)
  df$registry <- factor(NA, levels = rev(prefer))

  ## Annotate local vs remote entries
  urls <- is_url(df$source)
  suppressWarnings({ # Will use NA if prefer has only one type
    df[urls, "registry"] <- "remote"
    df[!urls, "registry"] <- "local"
  })
  ## Drop sources not listed in prefer
  ## (i.e. ignore remotes  if we prefer only local)
  df <- df[df$registry %in% prefer, ]

  ## Sort first by registry preference, then by date
  df <- df[order(df$registry, df$date, decreasing = TRUE), ]
  path <- attempt_source(df, verify = verify, verify_local = verify_local)

  if(store){
    store(path, dir = dir)
    path <- retrieve(id, dir = dir) 
  }
  
  path
}


attempt_source <- function(entries, verify = TRUE, verify_local = FALSE) {
  N <- dim(entries)[1]
  if (N < 1) {
    return(NULL)
  }

  ## We only care about unique sources!  should collapse the list
  entries <- unique(entries[c("identifier", "source")])

  for (i in 1:N) {
    source_loc <- tryCatch( {
        download_resource(entries[[i, "source"]])
      },
      error = function(e) NULL,
      finally = NULL
    )
    if (is.null(source_loc)) {
      next
    }

    ##
    if (verify) {
      if (is_url(entries[i, "source"]) && verify_local) {
        id <- content_uri(source_loc)
        if (id == entries[i, "identifier"]) {
          return(source_loc)
        }
      }
    }
    return(source_loc)
  }
}
