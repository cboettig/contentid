


# use '...' to swallow args for other methods
register_lmdb <- function(source, 
                         db = default_lmdb(),
                         algos = default_algos(),
                         ...
) {
  db <- init_lmdb(db)
  register_id(source, algos, db, write_lmdb, ...)
  
}



## serialize value as a tsv-formatted text string
lmdb_serialize <- function(df, prev_df){
  x <- paste0(apply(df, 1, paste0, collapse = "\t"), collapse="\n")
  ## if x and prev_df are identical strings, we do not append!
  if(identical(x, prev_df)) return(x)
  paste0(c(x, prev_df), collapse = "\n")
}

## parse text string back into a data.frame
lmdb_parse <- function(x){
  read.table(text = paste0(x, collapse="\n"), 
             header = FALSE, sep = "\t",
             quote = "",  colClasses = registry_spec,
             col.names = registry_cols)
}

write_lmdb <- function(df, db, ...){
  
  db <- init_lmdb(db)
  ## entry keyed by source
    # first, see if we have this source. if so, append it:
  current <- db$get(df$source, FALSE)
  entry <- lmdb_serialize(df, current)
  db$put(df$source, entry)
   
  ## entry keyed by id
  current <- db$get(df$identifier, FALSE)
  entry <- lmdb_serialize(df, current)
  db$put(df$identifier, entry)

  }



sources_lmdb <- function(id, db, ...) {
  db <- init_lmdb(db)
  out <- db$mget(id, FALSE)
  lmdb_parse(out)
}


history_lmdb <- function(x, db, ...) {
  db <- init_lmdb(db)
  out <- db$mget(x, FALSE)
  lmdb_parse(out)
}

#' default location for LMDB registry
#' 
#' Helper utility to initialize an LMDB registry -
#' matcher uses the pattern: "any file path ending in "lmdb".
#' The default map size can be set using, e.g. 
#' `options(thor_mapsize=1e12)`
#' 
#' Windows machines may need to set a smaller map size, 
#' see `thor::mdb_env` for details.
#' @param dir base directory for LMDB
#' @export
default_lmdb <- function(dir = content_dir()){
  file.path(dir, "lmdb")
}



init_lmdb <- function(path = default_lmdb()) {
  if (!requireNamespace("thor", quietly = TRUE)){
    stop("Please install package `thor` to use LMDB backend")
  }
  if(inherits(path, "mdb_env")) return(path)
  mdb_env <- getExportedValue("thor", "mdb_env")
  mdb_env(path, mapsize = getOption("thor_mapsize", 1e12)) ## ~1 TB
}



