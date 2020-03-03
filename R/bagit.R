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

  if (!fs::file_exists(bagit)) {
    fs::file_create(bagit)
    readr::write_lines(
      "BagIt-Version: 1.0\nTag-File-Character-Encoding: UTF-8",
      bagit
    )
  }
  if (!fs::file_exists(path)) {
    fs::file_create(path)
    r <- data.frame(identifier = NA, source = NA)
    readr::write_delim(r[0, ], path, col_names = FALSE)
  }
  path
}



bagit_add <- function(dir = app_dir(), identifier, source) {
  registry <- bagit_manifest(dir)

  ## we don't want to create duplicate entries
  df <- bagit_query(identifier, dir)
  if (nrow(df) > 0) {
    return(dir)
  }

  row <- data.frame(
    identifier = strip_prefix(identifier),
    source = fs::path_rel(source, start = dir)
  )
  
  readr::write_delim(row, registry, append = TRUE)
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
