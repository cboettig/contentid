## A tab-seperated-values backed registry


registry_spec <- "ccTiiccccc"
## use base64 encoding for more space-efficient storage
registry_entry <- function(id = NA_character_, 
                           source = NA_character_, 
                           date = Sys.time(),
                           size = fs::file_size(source, FALSE),
                           status = 200L,
                           md5 = NA_character_, 
                           sha1 = NA_character_, 
                           sha256 = as_sri(id), 
                           sha384 = NA_character_, 
                           sha512 = NA_character_){
  
  
  if(is.na(id)){
    status <- 404L
    size <- NA_integer_
  }
  
  data.frame(identifier = id, 
             source = source, 
             date = date, 
             size = as.integer(size), 
             status = status,
             md5 = md5, sha1 = sha1, sha256 = sha256, sha384 = sha384, sha512 = sha512,
             stringsAsFactors = FALSE)
}



register_tsv <- function(source, dir = content_dir()) {
  
  id <- content_id(source)
  
  # https://gist.github.com/jeroen/2087db9eaeac46fc1cd4cb107c7e106b#file-multihash-R
  
  df <- registry_entry(id, source, Sys.time())
  readr::write_tsv(df, tsv_init(dir), append = TRUE)
  
  id
}


#' @importFrom readr read_tsv write_tsv
# @importFrom dplyr filter
sources_tsv <- function(id, dir = content_dir()) {
  
  
  id <- as_hashuri(id)
  if(is.na(id)){
    warning(paste("id", id, "not recognized as a valid identifier"))
    return( null_query() )
  }
  

  df <- readr::read_tsv(tsv_init(dir), col_types = registry_spec)
  df[df$identifier == id, ] ## base R version
  
}


## A tsv-backed registry
history_tsv <- function(x, dir = content_dir()) {

  df <- readr::read_tsv(tsv_init(dir), col_types = registry_spec)
  df[df$source == x, ] ## base R version

}




## intialize a tsv-based registry
tsv_init <- function(dir = content_dir()) {
  
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



