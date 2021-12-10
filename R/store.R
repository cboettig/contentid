

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
#' @inheritParams content_id
#' @return the content-based identifier
#' @seealso retrieve
#' @export
#'
#' @examplesIf interactive()
#' \dontshow{ ## Real users won't use a temporary dir
#' Sys.setenv("CONTENTID_HOME" = tempdir())
#' }
#' # Store & retrieve local file
#' vostok_co2 <- system.file("extdata", "vostok.icecore.co2",
#'                           package = "contentid")
#'  id <- store(vostok_co2)
#'  retrieve(id)
#'
#' \dontshow{ ## Real users won't use a temporary dir
#' Sys.unsetenv("CONTENTID_HOME")
#' }
store <- function(x, dir = content_dir(), algos = default_algos() ) {
  
  # vectorize 
  vapply(x, function(x){
    
    ## Handle paths, connections, urls. assure download only once.
    con <- stream_connection(x, download = TRUE)
    filepath <- local_path(con)
  
    ## Compute the sha256 content identifier, and any others in use
    algos <- unique(c(algos, "sha256"))
    ids <- content_id_(con, algos = algos)
    id <- ids[["sha256"]]

    ## Store at a path based on the content identifier
    dest <- content_based_location(id, dir = dir)
    fs::dir_create(fs::path_dir(dest))
    
    
    ## Here we actually copy the data into the local store
    ## Using paths and file.copy() is faster than streaming
    if(!fs::file_exists(dest)){
      fs::file_copy(filepath, dest)
    }
    
    ## link any additional locations to the sha256 one
    lapply(ids[!grepl("sha256", ids)], function(id){
      ln <- content_based_location(id, dir)
      fs::dir_create(fs::path_dir(ln))
      if(!fs::link_exists(dest)){
        fs::link_create(dest, ln)
      }
    })
    
    
    id
  }, character(1L), USE.NAMES = FALSE)
}



# hate to add a dependency but `fs` is so much better about file paths
#' @importFrom fs path_rel path
content_based_location <- function(id, dir = content_dir()) {
  ## enforce hash_uri format
  id <-as_hashuri(id)
  algo <- unique(extract_algo(id))
  hash <- strip_prefix(id)
  ## use 2-level nesting
  sub1 <- substr(hash, 1, 2)
  sub2 <- substr(hash, 3, 4)
  # need absolute paths or things go badly...
  base <- fs::path_abs(fs::path(algo, sub1, sub2), start = dir)
  fs::dir_create(base)
  path <- fs::path(base, hash)
  fs::path_abs(path, dir)
}



## extract the local path of a connection object
local_path <- function(con){
  ## stopifnot(class(con) == c("file", "connection"))
  summary(con)$description
}



## Note that this requires computing file size and file modification time
## needless delay
sources_store <- function(id, dir = content_dir()){
  source = content_based_location(id, dir)
  if(file.exists(source)){
    info <- fs::file_info(source)
    registry_entry(id = id, 
                   source = source, 
                   date = info$modification_time,
                   size = info$size
    )
  } else {
    registry_entry(id = id, status=404)
  }
}




# first cache content for all urls locally, then register them locally.
# Registry non-file urls remotely.
# returns a table of hash_uri | url with remote and local urls
