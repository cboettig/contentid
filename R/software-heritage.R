
#  See list of endpoints at:
# https://archive.softwareheritage.org/api/1/


# id <- paste0("hash://sha256/9412325831dab22aeebdd",
#              "674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37")
#


sources_swh <- function(id, host = "https://archive.softwareheritage.org", ...){

  endpoint <- "/api/1/content/sha256:"
  hash <- strip_prefix(id)
  query <- paste0(host, endpoint, hash)
  response <- httr::GET(query)
  #httr::stop_for_status(resp)
  result <- httr::content(response, "parsed", "application/json")
  
  if(httr::status_code(response) != 200)
   return( null_query() )
  
  data.frame(identifer = id, 
             source = result$data_url,
             date = Sys.time()
            )
  
  
}

## history 
# url <- "https://github.com/espm-157/climate-template"
#' @importFrom jsonlite fromJSON
history_swh <- function(url, host = "https://archive.softwareheritage.org", ...){
  endpoint <- "/api/1/origin/"
  query <- paste0(host, endpoint, url, "/get/")
  response <- httr::GET(query)
  stop_for_status(response)
  result <- httr::content(response, "parsed", "application/json")
  
  resp <- httr::GET(result$origin_visits_url)
  res <- httr::content(resp, "text", encoding = "UTF-8")
  jsonlite::fromJSON(res)
  #res <- httr::content(resp, "parsed", "application/json")
  
  
  
}

# https://archive.softwareheritage.org/api/1/origin/save/doc/
## Note that this does not conform to the standard `register` format, since you register the
## whole repository origin and not individual content.
store_swh <- function(origin_url, 
                         host = "https://archive.softwareheritage.org", 
                         type = "git", ...){
  
  endpoint <- "/api/1/origin/save/"
  query <- paste0(host, endpoint, type, "/url/", origin_url,  "/")
  response <- httr::GET(query)

  result <- httr::content(response, "parsed", "application/json")
  result
  
}

null_query <- function(){
  data.frame(identifer = as.character(NA), 
             source = as.character(NA), 
             date = as.POSIXct(NA))[0,]
}

