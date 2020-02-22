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

## Should we try and guess type from location?  
## mime::guess_type(location)
## 
bagit_add <- function(registry, identifier, source){
  readr::write_delim(data.frame(identifier, source), registry, append = TRUE)
}