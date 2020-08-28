

#' Store files in a local cache
#'
#' Resources at a specified URL will be downloaded and copied
#'  into the local content-based storage. Local paths will simply
#'  be copied into local storage. Identical content is not duplicated.
#'
#' @param x a URL, [connection], or file path.
#' @param dir the path we should use for permanent / on-disk storage
#'  of the registry. An appropriate default will be selected (also 
#'  configurable using the environmental variable `CONTENTID_HOME`),
#'  if not specified.
#' @return the content-based identifier
#' @seealso retrieve
#' @export
#'
#' @examples
#' \dontshow{ ## Real users won't use a temporary dir
#' Sys.setenv("CONTENTID_REGISTRIES" = tempdir())
#' Sys.setenv("CONTENTID_HOME" = tempdir())
#' }
#' # Store & retrieve local file
#' vostok_co2 <- system.file("extdata", "vostok.icecore.co2",
#'                           package = "contentid")
#'  id <- store(vostok_co2)
#'  retrieve(id)
#'  
#' \donttest{
#'  # Store and retrieve content from a URL 
#' id <- store(paste0("https://knb.ecoinformatics.org/knb/d1/mn/v2/object/",
#' "ess-dive-457358fdc81d3a5-20180726T203952542"))
#' retrieve(id)
#' }
#'
#' \dontshow{ ## Real users won't use a temporary dir
#' Sys.unsetenv("CONTENTID_REGISTRIES")
#' Sys.unsetenv("CONTENTID_HOME")
#' }
#' 
## Shelve the object based on its content_id
store <- function(x, dir = content_dir()) {
  
  ## Handle paths, connections, urls. assure download only once.
  con <- stream_connection(x, download = TRUE)
  filepath <- local_path(con)

  ## Compute the sha256 content identifier
  id <- content_id(con, algos = "sha256")[["sha256"]]
  
  ## Trivial content-based storage system:
  ## Store at a path based on the content identifier
  dest <- content_based_location(id, dir)
  fs::dir_create(fs::path_dir(dest))
  
  ## Here we actually copy the data into the local store
  ## Using paths and file.copy() is faster than streaming
  if(!fs::file_exists(dest))
    fs::file_copy(filepath, dest)
  
  ## Alternately, for an open connection, but slower
  # stream_binary(con, dest)
  
  id
}



# hate to add a dependency but `fs` is so much better about file paths
#' @importFrom fs path_rel path
content_based_location <- function(hash, dir = content_dir()) {
  ## use 2-level nesting
  hash <- strip_prefix(hash)
  sub1 <- substr(hash, 1, 2)
  sub2 <- substr(hash, 3, 4)
  base <- fs::path_abs(fs::path("data", sub1, sub2), start = dir)
  fs::dir_create(base)
  path <- fs::path(base, hash)
  fs::path_abs(path, dir)
}



## extract the local path of a connection object
local_path <- function(con){
  ## stopifnot(class(con) == c("file", "connection"))
  summary(con)$description
}





# first cache content for all urls locally, then register them locally.
# Registry non-file urls remotely.
# returns a table of hash_uri | url with remote and local urls
