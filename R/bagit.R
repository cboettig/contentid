# Used by query
bagit_query <- function(id,
                        dir = content_dir()) {
  registry <- bagit_manifest(dir)
  
  hash <- strip_prefix(id)
  df <- readr::read_delim(registry,
                          delim = " ",
                          col_names = c("identifier", "source"),
                          col_types = "cc"
  )
  
  if (length(df) == 0) {
    return(df)
  }
  
  out <- df[df[[1]] == hash, ]
  
  format_bagit(out, dir = dir)
}

# takes the result of a `df <- bagit_query(uri)`
# and formats it like a registry_query
#' @importFrom fs file_info path_abs
format_bagit <- function(df, dir = content_dir()) {
  if (ncol(df) == 0 || nrow(df) == 0) {
    return(data.frame(identifier = NA, source = NA, date = NA)[0, ])
  }
  names(df) <- c("identifier", "source")
  abs_path <- fs::path_abs(df$source, start = dir)
  df$identifier <- add_prefix(df$identifier)
  # fs, readr, & others do not handle file URIs well!
  # https://github.com/r-lib/fs/issues/245
  df$source <- abs_path # paste0("file://", abs_path)
  df$date <- fs::file_info(abs_path)$modification_time
  df
}



## Should potentially be made user-facing, to "bag up" a local store.
#' @importFrom fs file_create file_exists path_abs
bagit_manifest <- function(dir = content_dir()) {
  
  path <- fs::path_abs("manifest-sha256.txt", dir)
  bagit <- fs::path_abs("bagit.txt", dir)

  ## Creeate the required `bagit.txt`
  if (!fs::file_exists(bagit)) {
    fs::file_create(bagit)
    readr::write_lines(
      "BagIt-Version: 1.0\nTag-File-Character-Encoding: UTF-8",
      bagit
    )
  }
  bagit_manifest_from_content_store(dir)
  
  invisible(path)
}


bagit_manifest_from_content_store <- function(dir = content_dir()){
  path <- fs::path_abs("manifest-sha256.txt", dir)
  
  files <- fs::dir_ls(fs::path_abs("data", dir), recurse = TRUE, type = "file")
  ids <- fs::path_file(files)
  
  registry <- fs::path_abs(fs::path("data", "registry.tsv.gz"), dir)
  if(!fs::file_exists(registry)){
    fs::file_create(registry)
  }
  ## hash the registry.tsv.gz file, the only file in `data/` not already named by hash
  ids[ids == "registry.tsv.gz"] <- 
    as.character(openssl::sha256(file(registry)))
  df <- data.frame(id = ids, file = files)          
  readr::write_delim(df, path, col_names = FALSE)
  
  invisible(path)
}

