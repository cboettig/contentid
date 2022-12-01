# Used by query
bagit_query <- function(id,
                        dir = content_dir()) {
  registry <- bagit_manifest(dir)
  
  hash <- strip_prefix(id)
  df <- utils::read.table(registry,
                          header = FALSE,
                          quote = "",
                          sep = "\t",
                          col.names = c("identifier", "source"),
                          colClasses = c("character", "character")
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
    return( registry_entry()[0, ])
  }
  
  abs_path <- fs::path_abs(df$source, start = dir)
  registry_entry(id = add_prefix(df$identifier),
                 source = abs_path,
                 date = fs::file_info(abs_path)$modification_time
                 )
  
}



## Should potentially be made user-facing, to "bag up" a local store.
#' @importFrom fs file_create file_exists path_abs
bagit_manifest <- function(dir = content_dir()) {
  
  path <- fs::path_abs("manifest-sha256.txt", dir)
  bagit <- fs::path_abs("bagit.txt", dir)

  ## Creeate the required `bagit.txt`
  if (!fs::file_exists(bagit)) {
    fs::file_create(bagit)
    writeLines(
      "BagIt-Version: 1.0\nTag-File-Character-Encoding: UTF-8",
      bagit
    )
  }
  bagit_manifest_from_content_store(dir)
  
  invisible(path)
}


bagit_manifest_from_content_store <- function(dir = content_dir()){
  
  path <- fs::path_abs("manifest-sha256.txt", dir)
  data_dir <- fs::path_abs("sha256", dir)
  fs::dir_create(data_dir)
  
  files <- fs::dir_ls(data_dir, recurse = TRUE, type = "file")
  ids <- fs::path_file(files)
  df <- data.frame(id = ids, file = files)          
  write.table(df, path, sep = "\t", quote = FALSE, col.names = FALSE, row.names = FALSE)
  
  invisible(path)
}

