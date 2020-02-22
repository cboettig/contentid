#' @importFrom fs file_create file_exists path_abs
bagit_manifest_create <- function(dir = app_dir()){
    path <- fs::path_abs("manifest-sha256.txt", dir)
    bagit <- fs::path_abs("bagit.txt", dir)
    
    if(!fs::file_exists(bagit)){
      fs::file_create(bagit)
      readr::write_lines(
        "BagIt-Version: 1.0\nTag-File-Character-Encoding: UTF-8",
        bagit)
    }
    if(!fs::file_exists(path)){
      fs::file_create(path)
      r <- data.frame(identifier = NA, source = NA)
      readr::write_delim(r[0,], path, col_names = FALSE)
    }
    path
  }

bagit_query <- function(identifier,  
                        registry = bagit_manifest_create(dir)){
  hash <- strip_prefix(identifier)
  df <- readr::read_delim(registry, delim = " ", 
                           col_names = c("identifier", "source"), 
                           col_types = "cc")
  
  if(length(df) == 0) return(df)
  
  df[df[[1]] == hash, ]
}

bagit_add <- function(registry, identifier, source){
  ## we don't want to create duplicate entries
  df <- bagit_query(identifier, registry)
  if(nrow(df) > 0) return(registry)
  
  row <- data.frame(identifier = strip_prefix(identifier), 
                    source = fs::path_rel(source, start = fs::path_dir(registry))
                   )
  readr::write_delim(row, registry, append = TRUE)
  
}