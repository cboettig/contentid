

as_hashuri <- function(x){
  # Named Info, https://tools.ietf.org/html/rfc6920
  if(grepl("^ni://", x))
    return( from_ni(x) )
  
  # magnet URI
  if(grepl("^magnet:\\?xt=urn:", x))
    return(from_magnet(x))
  
  # SSB
  if(grepl("^\\&", x))
    return(from_ssb(x))
  
  ## Subresource registry
  if(grepl(paste0(algo_regex, "-", base64_regex), x))
    return(from_subresource_registry(x))
  
}

algo_regex <- "(sha[0-9]{1,3}|md5)"
base64_regex <- "((?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?)"
hex_regex <- "((0x|0X)?[a-fA-F0-9]+)"

#' x <- "sha256-lBIyWDHasiruvdZ0tutTumt73QS7maTbsh3f9kYofjc="
from_subresource_registry <- function(x){
  hash <- gsub(paste0(algo_regex, "-", base64_regex), "\\2", x)
  algo <- gsub(paste0(algo_regex, "-", base64_regex), "\\1", x)
  hex <- paste0(openssl::base64_decode(hash), collapse = "")
  paste0("hash://", algo, "/", hex)
  
}

#' x <- "&lBIyWDHasiruvdZ0tutTumt73QS7maTbsh3f9kYofjc=.sha256"
from_ssb <- function(x){
  
  pattern <- paste0("\\&", base64_regex, "\\.", algo_regex)
  hash <- gsub(pattern, "\\1", x)
  algo <- gsub(pattern, "\\2", x)
  hex <- paste0(openssl::base64_decode(hash), collapse = "")
  paste0("hash://", algo, "/", hex)
  
}

#'   x <- "ni:///sha256;lBIyWDHasiruvdZ0tutTumt73QS7maTbsh3f9kYofjc"
from_ni <- function(x){
  
  #pattern <- paste0("^ni:///", algo_regex,  ";", base64_regex)
  
  hash <-  gsub(paste0("^ni:///([a-zA-Z0-9]+);", base64_regex), "\\2", x)
  algo <- gsub(paste0("^ni:///", algo_regex,  ";", hash), "\\1", x)
  hex <- paste0(openssl::base64_decode(hash), collapse = "")
  paste0("hash://", algo, "/", hex)

}

#' x <- "magnet:?xt=urn:sha256:9412325831dab22aeebdd674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37"
from_magnet <- function(x){
  
  pattern <- paste0("^magnet:\\?xt=urn:", algo_regex, ":", hex_regex)
  algo <- gsub(pattern, "\\1", x)
  hex <-  gsub(pattern, "\\2", x)
  paste0("hash://", algo, "/", hex)
  
  
    
}