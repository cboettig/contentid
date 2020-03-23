## A tab-seperated-values backed registry


register_tsv <- function(source, dir = content_dir()) {
  id <- content_uri(source)
  readr::write_tsv(data.frame(id, source, Sys.time()),
                   tsv_init(dir),
                   append = TRUE)
  
  id
}


#' @importFrom readr read_tsv write_tsv
# @importFrom dplyr filter
sources_tsv <- function(x, dir = content_dir()) {

  df <- readr::read_tsv(tsv_init(dir), col_types = "ccT")
  df[df$identifier == x, ] ## base R version
  
}


## A tsv-backed registry
history_tsv <- function(x, dir = content_dir()) {

  df <- readr::read_tsv(tsv_init(dir), col_types = "ccT")
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
    r <- data.frame(identifier = NA, source = NA, date = NA)
    readr::write_tsv(r[0, ], path)
  }
  
  path
}

