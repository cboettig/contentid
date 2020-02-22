
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
#'  query("https://zenodo.org/record/3678928/files/vostok.icecore.co2")
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
#' @inheritParams query
#' @return a data frame with columns for `identifier`, `source`, 
#' and `date`.
#' @noRd
# @export
#' @examples \donttest{
#' 
#' query_remote(
#' "hash://sha256/9412325831dab22aeebdd674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37")
#' 
#' # Can also query a URL to see if it has been registered:
#' query_remote("https://zenodo.org/record/3678928/files/vostok.icecore.co2")
#' 
#' 
#' 
#' }
#' @importFrom httr GET content stop_for_status
query_remote <- function(uri){
  
  
  endpoint <- "api/sources"
  if(is_url(uri)){
    endpoint <- "api/history"
  }
  
  archive <- "https://hash-archive.org"
  request <- paste(archive, endpoint, uri, sep = "/")
  response <- httr::GET(request)
  httr::stop_for_status(response)
  
  result <- httr::content(response, "parsed", "application/json")
  out <- lapply(result, format_hashachiveorg)
  
  ## base alternative dplyr::bind_rows
  do.call(rbind, lapply(out, as.data.frame, stringsAsFactors = FALSE))
}







#' look up a Content URI or URL in the local registry
#' 
#' @inheritParams query
#' @inheritParams store
#' @return a data frame with matching results
#' @noRd
# @export
#' @examples 
#' \donttest{
#'   
#'  ## A content hash
#'  query_local("hash://sha256/9412325831dab22aeebdd674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37")
#'  ## Or a (registered) URL
#'  query_local("https://zenodo.org/record/3678928/files/vostok.icecore.co2")
#'   
#'   }
query_local <- function(uri, dir = app_dir()){
  registry <- registry_create(dir)
  if(is_content_uri(uri)){
    url_df <- registry_get_hash(uri, registry)
    
    df <- bagit_query(uri, dir)
    path_df <- format_bagit(df, dir)
    
    rbind(path_df, url_df)
  }
  else
    registry_get_source(uri, registry)
}


#' @importFrom readr read_tsv write_tsv
# @importFrom dplyr filter
registry_get_hash <- function(x, registry = registry_create()){
  df <- readr::read_tsv(registry, col_types = "ccT")
  out <- df[df$identifier == x, ] ## base R version 
  out
}

registry_get_source <- function(x, registry  = registry_create()){
  df <- readr::read_tsv(registry, col_types = "ccT")
  out <- df[df$source == x, ] ## base R version 
  out
}




