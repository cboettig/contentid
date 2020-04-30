


as_hashuri <- function(id){

  if(all(is.null(id))) return(NA_character_)

  vapply(id, 
         function(x){
           switch(id_format(x),
           hashuri = x,
           magnet = from_magnet(x),
           sri = from_sri(x),
           ssb = from_ssb(x),
           ni = from_ni(x),
           NA_character_)
         },
         character(1L),
         USE.NAMES = FALSE)
  }





## SRI is a nice concise format that is useful for storage
as_sri <- function(x) {
  if(is.null(x)) return(NA_character_)
  if(is.na(x))  return(NA_character_)
  if(is_hash(x, "sri")) return(x)
  ## maybe a good check but will increase processing time?
  # if(!is_hash(x, "hashuri")){
  #   warning(paste(x, "is not the recognized hash-uri format\n"), call.=FALSE)
  #   return(NA_character_)
  # }
  
  algo <- sub(hashuri_regex, "\\1", x)
  hex <- sub(hashuri_regex, "\\2", x)
  
  paste0(algo, "-", hex_to_base64(hex))
}
## Note we cannot simply `base64_encode(hex)`, since that treats hex string as if it were 
## text and not raw bits.  We must convert it to raw bits like so: 
## https://stackoverflow.com/questions/29251934/how-to-convert-a-hex-string-to-text-in-r
hex_to_base64 <- function(s){
  bits <- sapply(seq(1, nchar(s), by=2), function(x) substr(s, x, x+1))
  raw <- as.raw(strtoi(bits, 16L))
  openssl::base64_encode(raw)
}


algo_regex <- "(sha[0-9]{1,3}|md5)"
base64_regex <- "((?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?)"
hex_regex <- "((0x|0X)?[a-fA-F0-9]+)"
hashuri_regex <- paste0("^hash://", algo_regex, "/", hex_regex)
magnet_regex <- paste0("^magnet:\\?xt=urn:", algo_regex, ":", hex_regex)
sri_regex <- paste0(algo_regex, "-", base64_regex)
ssb_regex <- paste0("\\&", base64_regex, "\\.", algo_regex)
ni_regex <- paste0("^ni:///", algo_regex,  ";", base64_regex)


id_format <- function(x){
  
  if(is.null(x)) return(NA_character_)
  if(is.na(x))  return(NA_character_)
  
  formats <- c("hashuri", "magnet", "sri", "ssb", "ni")
  matches <- vapply(formats, 
         function(type) is_hash(x, type),
         logical(1L))
  
  if(!any(matches)) return(NA_character_)
  
  formats[matches]
}

is_hash <- function(x, type = c("hashuri", "magnet", "sri", "ssb", "ni")){
  type <- match.arg(type)
  pattern <- switch(type,
                    hashuri = hashuri_regex,
                    magnet = magnet_regex,
                    sri = sri_regex,
                    ssb = ssb_regex,
                    ni = ni_regex,
                    NA)
  grepl(pattern, x)
}


# sri <- "sha256-lBIyWDHasiruvdZ0tutTumt73QS7maTbsh3f9kYofjc="
from_sri <- function(x){
  hash <- gsub(sri_regex, "\\2", x)
  algo <- gsub(sri_regex, "\\1", x)
  hex <- paste0(openssl::base64_decode(hash), collapse = "")
  paste0("hash://", algo, "/", hex)
  
}

# ssb <- "&lBIyWDHasiruvdZ0tutTumt73QS7maTbsh3f9kYofjc=.sha256"
from_ssb <- function(x){
  hash <- gsub(ssb_regex, "\\1", x)
  algo <- gsub(ssb_regex, "\\2", x)
  hex <- paste0(openssl::base64_decode(hash), collapse = "")
  paste0("hash://", algo, "/", hex)
  
}

## note that named info doesn't have the trailing '='
## argh this should be base64url encoded (that's URL-encoded!), and without trailing `=`, by spec
#   ni <- "ni:///sha256;lBIyWDHasiruvdZ0tutTumt73QS7maTbsh3f9kYofjc"
from_ni <- function(x){
  
  hash <-  gsub(paste0("^ni:///([a-zA-Z0-9]+);", base64_regex), "\\2", x)
  algo <- gsub(paste0("^ni:///", algo_regex,  ";", hash), "\\1", x)
  hex <- paste0(openssl::base64_decode(hash), collapse = "")
  paste0("hash://", algo, "/", hex)

}

# magnet <- "magnet:?xt=urn:sha256:9412325831dab22aeebdd674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37"
from_magnet <- function(x){
  algo <- gsub(magnet_regex, "\\1", x)
  hex <-  gsub(magnet_regex, "\\2", x)
  paste0("hash://", algo, "/", hex)
}


