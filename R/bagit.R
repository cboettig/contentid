bagit_query <- function(identifier,
                        dir = app_dir()) {
  registry <- bagit_manifest(dir)
  
  hash <- strip_prefix(identifier)
  df <- readr::read_delim(registry,
                          delim = " ",
                          col_names = c("identifier", "source"),
                          col_types = "cc"
  )
  
  if (length(df) == 0) {
    return(df)
  }
  
  out <- df[df[[1]] == hash, ]
  
  format_bagit(out)
  
}



#' @importFrom fs file_create file_exists path_abs
bagit_manifest <- function(dir = app_dir()) {
  
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


bagit_manifest_from_content_store <- function(dir = app_dir()){
  path <- fs::path_abs("manifest-sha256.txt", dir)
  files <- fs::dir_ls(fs::path(dir, "data"), recurse = TRUE, type = "file")
  ids <- fs::path_file(files)
  ## hash the registry.tsv.gz file, the only `data/` not named by hash
  ids[ids == "registry.tsv.gz"] <- 
    as.character(openssl::sha256(file(fs::path(dir, "data", "registry.tsv.gz"))))
  df <- data.frame(id = ids, file = files)          
  readr::write_delim(df, path, col_names = FALSE)
  
  invisible(path)
}



# takes the result of a `df <- bagit_query(uri)`
# and formats it like a registry_query
#' @importFrom fs file_info path_abs
format_bagit <- function(df, dir = app_dir()) {
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

