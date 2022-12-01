
#  See list of endpoints at:
# https://archive.softwareheritage.org/api/1/




#' List software heritage sources for a content identifier  
#' @inheritParams sources
#' @param host the domain name for the Software Heritage API
#' 
#' @export 
#' @seealso [sources]
#' @examplesIf interactive()
#' 
#'  \donttest{
#' 
#' id <- paste0("hash://sha256/9412325831dab22aeebdd",
#'              "674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37")
#' sources_swh(id)
#'
#' }
#' 
sources_swh <- function(id, host = "https://archive.softwareheritage.org", ...){
  quiet <- getOption("verbose", FALSE)
  id <- as_hashuri(id)
  if(is.na(id)){
    warning(paste("id", id, "not recognized as a valid identifier"), call. = FALSE)
    return( null_query() )
  }
  if(!grepl("sha256", id)){
    if(!quiet) message(paste("skipping Software Heritage as id is not a SHA256 sum"))
    return( null_query() )
  }

  endpoint <- "/api/1/content/sha256:"
  hash <- strip_prefix(id)
  query <- paste0(host, endpoint, hash)
  
  response <- tryCatch({
    response <- httr::GET(query)
    },
    error = function(e){
      message(e)
      list()
    },
    finally = list()
  )
  if(length(response) == 0 || httr::status_code(response) != 200)
   return( null_query() )
  
  result <- httr::content(response, "parsed", "application/json")
  registry_entry(id, 
                 source = result$data_url,
                 date = Sys.time()
                 )
  
  
}

#' return the history of archive events of a given software repository
#' 
#' Note that unlike the generic [history] method, SWH history is repo-specific
#' rather than content-specific. An archive event adds all content from the repo 
#' to the Software Heritage archival snapshot at once.  Any individual file can still
#' be referenced by its content identifier. 
#' @seealso [history], [store_swh], [sources_swh]
#' 
#' @param origin_url The url address to a GitHub, GitLab, or other recognized repository origin
#' @inheritParams sources_swh
#  @importFrom jsonlite fromJSON
#' @export
#' 
#' @examplesIf interactive()
#' \donttest{
#' history_swh("https://github.com/CSSEGISandData/COVID-19")
#' }
#' 
history_swh <- function(origin_url, host = "https://archive.softwareheritage.org", ...){
  endpoint <- "/api/1/origin/"
  query <- paste0(host, endpoint, origin_url, "/get/")
  response <- httr::GET(query)
  stop_for_status(response)
  result <- httr::content(response, "parsed", "application/json")
  
  resp <- httr::GET(result$origin_visits_url)
  #res <- httr::content(resp, "text", encoding = "UTF-8")
  #jsonlite::fromJSON(res)
  httr::content(resp, "parsed", "application/json")
  
  
  
}

# https://archive.softwareheritage.org/api/1/origin/save/doc/
## Note that this does not conform to the standard `register` format, since you register the
## whole repository origin and not individual content.

#' Add content to the Software Heritage Archival Store
#' 
#' @inheritParams history_swh
#' @param type software repository type, i.e. "git", "svn"
#' @export
#' @examplesIf interactive()
#' \donttest{
#' store_swh("https://github.com/CSSEGISandData/COVID-19")
#' }
#' 
store_swh <- function(origin_url, 
                      host = "https://archive.softwareheritage.org", 
                      type = "git", ...){
  
  endpoint <- "/api/1/origin/save/"
  query <- paste0(host, endpoint, type, "/url/", origin_url,  "/")
  response <- httr::GET(query)

  result <- httr::content(response, "parsed", "application/json")
  result
  
}


#' retrieve content from Software Heritage given a content identifier
#' 
#' @inheritParams sources_swh
#' @seealso [retrieve], [sources_swh]
#' @export
#' 
#' 
#' @examplesIf interactive()
#' \donttest{
#' 
#' id <- paste0("hash://sha256/9412325831dab22aeebdd",
#'              "674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37")
#' retrieve_swh(id)
#'
#' }
#' 
retrieve_swh <- function(id, host = "https://archive.softwareheritage.org"){
  df <- sources_swh(id, host)
  df$source[[1]]
}


null_query <- function(){
  registry_entry()[0,]
}

