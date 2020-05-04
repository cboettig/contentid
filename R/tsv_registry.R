## A tab-seperated-values backed registry


registry_spec <- "ccTiiccccc"
## use base64 encoding for more space-efficient storage
registry_entry <- function(id = NA_character_, 
                           source = NA_character_, 
                           date = Sys.time(),
                           size = fs::file_size(source, FALSE),
                           status = 200L,
                           md5 = NULL, 
                           sha1 = NULL, 
                           sha256 = id, 
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
  
  data.frame(identifier = as_chr(id), 
             source = as_chr(source), 
             date = as.POSIXct(date), 
             size = as.integer(size), 
             status = as.integer(status),
             md5 = as_hashuri(md5), 
             sha1 = as_hashuri(sha1), 
             sha256 = as_hashuri(sha256), 
             sha384 = as_hashuri(sha384), 
             sha512 = as_hashuri(sha512),
             stringsAsFactors = FALSE)
}


curl_err <- function(e) as.integer(gsub(".*(\\d{3}).*", "\\1", e$message))

# use '...' to swallow args for other methods
register_tsv <- function(source, 
                         dir = content_dir(),
                         algos = default_algos(),
                         ...
                         ) {
  
  ## register will still refuse to fail, but record NAs when content_id throws and error
  id <- tryCatch(content_id(source, algos = algos),
                 error = function(e){
                   df <- registry_entry(id$sha256, 
                                        source, 
                                        Sys.time(), 
                                        status =  curl_err(e))
                   readr::write_tsv(df, init_tsv(dir), append = TRUE)
                 },
                 finally = NA_character_
                )
  
  # https://gist.github.com/jeroen/2087db9eaeac46fc1cd4cb107c7e106b#file-multihash-R
  
  df <- registry_entry(id$sha256, 
                       source, 
                       Sys.time(), 
                       md5 = id$md5, 
                       sha1 = id$sha1, 
                       sha256 = id$sha256, 
                       sha384 = id$sha384, 
                       sha512 = id$sha512)
  readr::write_tsv(df, init_tsv(dir), append = TRUE)
  
  id$sha256
}


#' @importFrom readr read_tsv write_tsv
# @importFrom dplyr filter
sources_tsv <- function(id, dir = content_dir(), ...) {
  
  
  id <- as_hashuri(id)
  if(is.na(id)){
    warning(paste("id", id, "not recognized as a valid identifier"))
    return( null_query() )
  }
  

  df <- readr::read_tsv(init_tsv(dir), col_types = registry_spec)
  df[df$identifier == id, ] ## base R version
  
}


## A tsv-backed registry
history_tsv <- function(x, dir = content_dir(), ...) {

  df <- readr::read_tsv(init_tsv(dir), col_types = registry_spec)
  df[df$source == x, ] ## base R version

}




## intialize a tsv-based registry
init_tsv <- function(dir = content_dir()) {
  
  path <- fs::path_abs(fs::path("data", "registry.tsv.gz"), dir)
  
  if (!fs::dir_exists(fs::path_dir(path))) {
    fs::dir_create(fs::path_dir(path))
  }
  
  if (!fs::file_exists(path)) {
    fs::file_create(path)
    registry_entry
    r <- registry_entry()
    readr::write_tsv(r[0, ], path)
  }
  
  path
}



