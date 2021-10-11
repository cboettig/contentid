
## helper functions to avoid documentation errors

ping <- function(url){
  all(vapply(url, 
         function(u) status_code(httr::HEAD(u)) < 300,
         logical(1))
  )
  
    
}

has_resource <- function(url){
curl::has_internet() && ping(url)
}
  
