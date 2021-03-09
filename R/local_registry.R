## Generic function that computes id first, then registers it against a specified local registry 
## (e.g. tsv_registry).  Local registries are database entry only, and do not compute the hash,
## they only store it.  

## Likewise, defines generic schema used by the local registry entry. 
## (Remote registries like hash-archive.org are also coerced into this schema)

registry_cols <- c("identifier", "source", "date", "size", "status", "md5",
                   "sha1", "sha256", "sha384", "sha512")

registry_spec <- c("character","character", "POSIXct", "integer", "integer",
                   "character","character", "character","character", "character") 

## use base64 encoding for more space-efficient storage
registry_entry <- function(id = NA_character_, 
                           source = NA_character_, 
                           date = Sys.time(),
                           size = fs::file_size(source, FALSE),
                           status = 200L,
                           md5 = NULL, 
                           sha1 = NULL, 
                           sha256 = NULL, 
                           sha384 = NULL, 
                           sha512 = NULL){
  
  if(is.na(id)){
    status <- 404L
    size <- NA_integer_
  }
  
  as_chr <- function(x){
    if(is.null(x)) return(NA_character_)
    else as.character(x)
  }
  id <- as_hashuri(id)

  data.frame(identifier = as_hashuri(id), 
             source = as_chr(source), 
             date = as.POSIXct(date), 
             size = as.integer(size), 
             status = as.integer(status),
             md5 = match_algo(md5, id, "md5"), 
             sha1 = match_algo(sha1, id, "sha1"), 
             sha256 = match_algo(sha256, id, "sha256"), 
             sha384 = match_algo(sha384, id, "sha384"), 
             sha512 = match_algo(sha512, id, "sha512"),
             stringsAsFactors = FALSE)
}

match_algo <- function(given, id, type="sha256"){
  if(!is.null(given)) return(given)
  if(is.na(id)) return(NA_character_)
  algo <- extract_algo(id)
  if(algo == type) return(id)
  NA_character_
}





curl_err <- function(e) as.integer(gsub(".*(\\d{3}).*", "\\1", e$message))
# use '...' to swallow args for other methods
register_id <- function(source, 
                        algos = default_algos(),
                        registry =  default_tsv(),
                        register_fn = write_tsv,
                        ...
) {
  
  ## register will still refuse to fail, but record NAs when content_id throws and error
  id <- tryCatch(content_id(source, algos = algos, as.data.frame = TRUE),
                 error = function(e){
                   df <- registry_entry(NA_character_, source, status =  curl_err(e))
                   register_fn(df, registry)
                   df$id
                 },
                 finally = registry_entry(status = NA_integer_)
  )
  
  df <- registry_entry(id$sha256, source,  Sys.time(), 
                       md5 = id$md5, 
                       sha1 = id$sha1, 
                       sha256 = id$sha256, 
                       sha384 = id$sha384, 
                       sha512 = id$sha512)
  
  register_fn(df, registry)
  
  id$sha256
}


