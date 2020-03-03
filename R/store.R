## Store should also register the uri in a local registry


#' Store files in a local cache
#'
#' Resources at a specified URL will be downloaded and copied
#'  into the local storage. Local paths will simply be copied
#'  into local storage.  For either source, an entry
#'  is added to the registry under the content hash identifier.
#'
#' @param x a URL or path to a local file
#' @param dir the path we should use for permanent / on-disk storage
#'  of the registry. An appropriate default will be selected (also 
#'  configurable using the environmental variable `CONTENTURI_HOME`),
#'  if not specified.
#' @return the content-based identifier
#' @export
#'
#' @examples
#'
#' vostok_co2 <- system.file("extdata", "vostok.icecore.co2",
#'                           package = "contenturi")
#' store(vostok_co2)
#' \donttest{
#' store("https://zenodo.org/record/3678928/files/vostok.icecore.co2")
#' }
#'
store <- function(x, dir = app_dir()) {
  # Consider vectorizing of x?

  ## download to temp dir if necessary. We cannot 
  ## stream into store since we must first compute address from id
  con <- stream_connection(x, download = TRUE)
  on.exit(close(con))

  ## Compute the Content Hash URI and other metadata
  id <- content_uri(con)

  ## Here we actually copy the data into the local store
  ## Using paths and file.copy() is much faster than streaming
  path <- summary(con)$description
  stored_path <- store_shelve(path, id, dir = dir)

  id
}


## Shelve the object based on its content_uri
store_shelve <- function(path, id = content_uri(file), dir = app_dir()) {
  
  ## Determine the storage location and move the file to that location
  dest <- content_based_location(id, dir)
  if(!fs::file_exists(dest))
    fs::file_copy(path, dest)
  
   ## Alternately, for an open connection, but slower
   # stream_binary(con, dest)

  dest
}


store_retrieve <- function(x, dir = app_dir()) {
  if (!is_content_uri(x)){ 
    stop(paste(x, "is not a recognized content uri"), call. = FALSE)
  }

  path <- content_based_location(x, dir)

  if (!file.exists(path)) {
    message(paste("No stored file found for", x, "in", dir),
            call. = FALSE)
    return(NULL)
  }
  
  ## We could call `file(path)` instead, but would make assumptions about how
  ## we were reading the content that are better left to the user?
  path
}

store_list <- function(dir = app_dir()){
  fs::dir_info(path = fs::path(dir, "data"), recurse = TRUE, type = "file")
}

store_delete <- function(ids, dir = app_dir()){
  lapply(ids, function(id){ 
    path <- content_based_location(id, dir)
    fs::file_delete(path)
  })
}



# hate to add a dependency but `fs` is so much better about file paths
#' @importFrom fs path_rel path
content_based_location <- function(hash, dir = app_dir()) {
  ## use 2-level nesting
  hash <- strip_prefix(hash)
  sub1 <- gsub("^(\\w{2}).*", "\\1", hash)
  sub2 <- gsub("^(\\w{2})(\\w{2}).*", "\\2", hash)
  base <- fs::path_abs(fs::path("data", sub1, sub2), start = dir)
  fs::dir_create(base)
  path <- fs::path(base, hash)
  fs::path_abs(path, dir)
}





# first cache content for all urls locally, then register them locally.
# Registry non-file urls remotely.
# returns a table of hash_uri | url with remote and local urls
