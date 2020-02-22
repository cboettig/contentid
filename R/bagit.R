bagit_manifest_create <- function(dir = app_dir()){
    path <- file.path(dir, "manifest-sha256.txt")
    bagit <- file.path(dir, "bagit.txt")
    
    if(!file.exists(bagit)){
      file.create(bagit, showWarnings = FALSE)
      readr::write_lines(
        "BagIt-Version: 1.0\nTag-File-Character-Encoding: UTF-8",
        bagit)
    }
    if(!file.exists(path)){
      file.create(path, showWarnings = FALSE)
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