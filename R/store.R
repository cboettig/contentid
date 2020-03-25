

#' Store files in a local cache
#'
#' Resources at a specified URL will be downloaded and copied
#'  into the local content-based storage. Local paths will simply
#'  be copied into local storage. Identical content is not duplicated.
#'
#' @param x a URL, [connection], or file path.
#' @param dir the path we should use for permanent / on-disk storage
#'  of the registry. An appropriate default will be selected (also 
#'  configurable using the environmental variable `CONTENTURI_HOME`),
#'  if not specified.
#' @return the content-based identifier
#' @seealso retrieve
#' @export
#'
#' @examples
#'
#' # Store & retrieve local file
#' vostok_co2 <- system.file("extdata", "vostok.icecore.co2",
#'                           package = "contentid")
#'  id <- store(vostok_co2)
#'  retrieve(id)
#'  
#' \donttest{
#'  # Store and retrieve content from a URL 
#' id <- store("https://zenodo.org/record/3678928/files/vostok.icecore.co2")
#' retrieve(id)
#' }
#'
## Shelve the object based on its content_id
store <- function(x, dir = content_dir()) {
  
  ## Handle paths, connections, urls. assure download only once.
  con <- stream_connection(x, download = TRUE)
  on.exit(close(con))
  
  ## Compute the content identifier
  id <- content_id(con)
  
  ## Trivial content-based storage system:
  ## Store at a path based on the content identifier
  dest <- content_based_location(id, dir)
  
  ## Here we actually copy the data into the local store
  ## Using paths and file.copy() is faster than streaming
  if(!fs::file_exists(dest))
    fs::file_copy(local_path(con), dest)
  
  ## Alternately, for an open connection, but slower
  # stream_binary(con, dest)
  
  id
}



# hate to add a dependency but `fs` is so much better about file paths
#' @importFrom fs path_rel path
content_based_location <- function(hash, dir = content_dir()) {
  ## use 2-level nesting
  hash <- strip_prefix(hash)
  sub1 <- gsub("^(\\w{2}).*", "\\1", hash)
  sub2 <- gsub("^(\\w{2})(\\w{2}).*", "\\2", hash)
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
