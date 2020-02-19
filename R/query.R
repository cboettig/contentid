
#' query a Content URI or a URL with remote and/or local registries
#' 
#' @param uri a content identifier or a regular URL for a data file 
#' @inheritParams register
#' @param ... additional arguments to `[query_local]` or `[query_remote]`.
#' @return a data frame with matching results
#' @export
#' @examples 
#' \donttest{
#'   
#'  ## By content identifier
#'  query("hash://sha256/9412325831dab22aeebdd674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37")
#'  ## By (registered) URL
#'  query("http://cdiac.ornl.gov/ftp/trends/co2/vostok.icecore.co2")
#'   
#'   }
#'
query  <- function(uri, registries = default_registries(), ...){
  remote_out <- NULL
  local_out <- NULL
  
  if(any(grepl("https://hash-archive.org", registries))) remote_out <- query_remote(uri, ...)
  
  local <- registries[dir.exists(registries)]
  local_out <- lapply(local, function(dir) query_local(uri, dir = dir))
  local_out <- do.call(rbind, local_out)
  rbind(remote_out, local_out)
}


#' return registered downloadable URLs for the resource from hash-archive.org
#' @param hash A hash URI, or download URL of a resource
#' 
#' @return a data frame with columns for `url`, `timestamp`, 
#' `status`, `type` (mimeType), `length` (bytes), and `hashes`
#' @export
#' @examples \donttest{
#' 
#' query_remote(
#' "hash://sha256/9412325831dab22aeebdd674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37")
#' 
#' # Can also query a URL to see if it has been registered:
#' query_remote("http://cdiac.ornl.gov/ftp/trends/co2/vostok.icecore.co2")
#' 
#' 
#' 
#' }
#' @importFrom httr GET content stop_for_status
query_remote <- function(hash){
  
  
  endpoint <- "api/sources"
  if(is_url(hash)){
    endpoint <- "api/history"
  }
  
  archive <- "https://hash-archive.org"
  request <- paste(archive, endpoint, hash, sep = "/")
  response <- httr::GET(request)
  httr::stop_for_status(response)
  
  result <- httr::content(response, "parsed", "application/json")
  out <- lapply(result, as_dublincore)
  
  ## base alternative dplyr::bind_rows
  do.call(rbind, lapply(out, as.data.frame, stringsAsFactors = FALSE))
}







#' look up a Content URI or URL in the local registry
#' 
#' @param x a Content URI (identifier) or a URL
#' @inheritParams register_local
#' @return a data frame with matching results
#' @export
#' @examples 
#' \donttest{
#'   
#'  ## A content hash
#'  query_local("hash://sha256/9412325831dab22aeebdd674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37")
#'  ## Or a (registered) URL
#'  query_local("http://cdiac.ornl.gov/ftp/trends/co2/vostok.icecore.co2")
#'   
#'   }
query_local <- function(x, dir = app_dir()){
  registry <- registry_create(dir)
  if(is_content_uri(x))
    registry_get_hash(x, registry)
  else
    registry_get_source(x, registry)
}


#' @importFrom readr read_tsv write_tsv
# @importFrom dplyr filter
registry_get_hash <- function(x, registry = registry_create()){
  df <- readr::read_tsv(registry, col_types = "ccTc")
  out <- df[df$identifier == x, ] ## base R version 
  out
}

registry_get_source <- function(x, registry  = registry_create()){
  df <- readr::read_tsv(registry, col_types = "ccTc")
  out <- df[df$source == x, ] ## base R version 
  out
}

