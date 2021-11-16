
#' List all content identifiers that have been seen at a given URL
#' 
#' [history_url] is the complement of [sources], in that it filters a table
#' of content identifier : url : date entries by the url. 
#' 
#' @param url A URL for a data file
#' @inheritParams register
#' @param ... additional arguments
#' @return a data frame with all content identifiers that have been seen
#' at a given URL.  If the URL is version-stable, this should be a single 
#' identifier.  Note that if multiple identifiers are listed, older content
#' may no longer be available, though there is a chance it has been registered
#' to a different url and can be resolved with [sources].
#' @seealso sources
#' @details [history_url()] only applies to registries that contain mutable URLs,
#' i.e. hash-archive and local registries which merely record the contents last
#' seen at any URL.  Such URLs may have the same or different content at a later
#' date, or may fail to resolve.  In contrast, archives such as DataONE or 
#' Zenodo that resolve identifiers to source URLs control both the registry and 
#' the content storage, and thus only report URLs where content is currently found.
#' While Download URLs from archives may move and old URLs may fail, a download URL
#' never has "history" of different content (e.g. different versions) served 
#' from the same access URL.  
#' @export
#' @aliases history_url, query_history
#' @importFrom methods is
#' @examplesIf interactive()
#' 
#' 
#' \dontshow{ ## Real users won't use a temporary dir
#' Sys.setenv("CONTENTID_REGISTRIES" = tempdir())
#' Sys.setenv("CONTENTID_HOME" = tempdir())
#' }
#' 
#' \donttest{ 
#' history_url(paste0("https://zenodo.org/api/files/5967f986-b599-4492-9a08",
#' "-94ce32323dc2/vostok.icecore.co2"), 
#' registries = "https://hash-archive.carlboettiger.info")
#' }
#' 
#' \dontshow{ ## Real users won't use a temporary dir
#' Sys.unsetenv("CONTENTID_REGISTRIES")
#' Sys.unsetenv("CONTENTID_HOME")
#' } 
#'
history_url <- function(url, registries = default_registries(), ...){
  
  ha_out <- NULL
  tsv_out <- NULL
  lmdb_out <- NULL
  
  registries <- expand_registry_urls(registries)
  types <- detect_registry_type(registries)
  
  
  ## Call sources_fn on each recognized registry type
  out <- lapply(types, function(type){
    active_registries <- registries[types == type]
    generic_history(url, registries = active_registries, type = type)
  })
  
  do.call(rbind, out)
}

query_history <- history_url

## Map (closure) to select the history_* function for the type
known_history <- function(type){ 
  switch(type,
         "hash-archive" = history_ha,
         "tsv" = history_tsv,
         "lmdb" = history_lmdb,
         function(url, host) NULL
  )
}
generic_history <- function(url, registries, type){
  out <- lapply(registries, 
                function(host){
                  tryCatch(known_history(type)(url, host),
                           error = function(e) warning(e),
                           finally = NULL)
                })
  do.call(rbind,out)
}


