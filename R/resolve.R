#' Resolve content from a content identifier
#'
#' Requested content can be found at mutiple locations:
#'  cached to disk, or available at one or more URLs.  This function
#'  provides a mechanism to always return a single, local path to the
#'  content requested, (provided the content identifier can be found in
#'  at least one of the registries).
#'
#' @param id A content identifier, see [content_id]
#' @param verify logical, default [TRUE]. Should we verify that
#'  content matches the requested hash?
#' @param store logical, should we add remotely downloaded copy to the local store?
#' @param dir path to the local store directory. Defaults to first local registry given to
#'  the `registries` argument. 
#' @inheritParams query
#' @details Local storage
#'  is checked first as it will allow us to bypass downloading content
#'  when a local copy is available. If no local copy is found but 
#'  one or more remote URLs are registered for the hash, downloads 
#'  from these will be attempted in order from most recent first.
#' @seealso query query_local query_remote
#' @examplesIf interactive()
#' \dontshow{ ## Real users won't use a temporary dir
#' Sys.setenv("CONTENTID_REGISTRIES" = tempdir())
#' Sys.setenv("CONTENTID_HOME" = tempdir())
#' }
#' # ensure some content in local storage for testing purposes:
#' vostok_co2 <- system.file("extdata", "vostok.icecore.co2",
#'                           package = "contentid")
#' store(vostok_co2)
#'
#' \donttest{
#' resolve(paste0(
#'  "hash://sha256/9412325831dab22aeebdd6",
#'  "74b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37")
#' )
#' }
#' \dontshow{ ## Real users won't use a temporary dir
#' Sys.unsetenv("CONTENTID_REGISTRIES")
#' Sys.unsetenv("CONTENTID_HOME")
#' }
#' 
#' 
#' @export
resolve <- function(id,
                    registries = default_registries(),
                    verify = TRUE,
                    store = FALSE,
                    dir = content_dir(),
                    ...) {
  
  df <- sources(id, registries, cols=c("identifier", "source", "date"), 
                      all = FALSE, ...)
  
  if(is.null(df) || nrow(df) == 0){
    warning(paste("No sources found for", id))
    return(NA_character_)
  }
  
  path <- attempt_source(df, verify = verify)
  
  if(valid_store_path(id, path)){
    store <- FALSE # No need to rehash valid store
  }
  if(store){
    algo <- extract_algo(id)
    id_sha256 <- store(path, dir = dir, algos = algo)
    path <- retrieve(id_sha256, dir = dir) 
  }
  
  if(is.null(path)){
    warning(paste("No sources found for", id))
    return(NA_character_)
  }
  
  path
}

valid_store_path <- function(id, path){
  basename(path) == basename(id)
}

attempt_source <- function(entries, verify = TRUE) {
  N <- dim(entries)[1]
  
  if (N < 1) {
    return(NULL)
  }

  entries <- unique(entries[c("identifier", "source")])

  for (i in 1:N) {
    source_loc <- tryCatch( {
        download_resource(entries[[i, "source"]])
      },
      error = function(e) NA_character_,
      finally = NA_character_
    )
    if (is.null(source_loc)){
      next
    }
    if (is.na(source_loc)) {
      next
    }

    ##  Skip re-hashing of content-store-sources
    if (valid_store_path(entries$identifier[[i]],
                        entries$source[[i]])
        ) {
      verify = FALSE
    } 
    
    if (verify) {
        algo <- sub(hashuri_regex, "\\1", entries[i, "identifier"])
        ## verification is always sha256-based.  
        id <- content_id(source_loc, algo)
        if (id == entries[i, "identifier"]) {
          return(source_loc)
        } else {
          next
        }
    }
    if(is.null(source_loc))
      stop(paste("no sources for", entries$identifier[[1]],
                    "found at any source:", entries$source))
    return(source_loc)
  }
}


