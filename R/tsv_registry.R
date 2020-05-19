## A tab-seperated-values backed registry


# use '...' to swallow args for other methods
register_tsv <- function(source, 
                         tsv = default_tsv(),
                         algos = default_algos(),
                         ...
                         ) {
  register_id(source, algos, tsv, write_tsv, ...)

}

col_types = "ccTiiccccc"

write_tsv <- function(df, tsv){
  
  if(requireNamespace("vroom")){
    vroom_write <- getExportedValue("vroom", "vroom_write")
    vroom_write(df, init_tsv(tsv), delim = "\t", append = TRUE, quote = "none")
  } else {
  utils::write.table(df, init_tsv(tsv), sep = "\t", append = TRUE,
                     quote = FALSE, row.names = FALSE, col.names = FALSE)
  }
}


sources_tsv <- function(id, tsv = default_tsv(), ...) {
  
  
  id <- as_hashuri(id)
  if(is.na(id)){
    warning(paste("id", id, "not recognized as a valid identifier"))
    return( null_query() )
  }
  
  
  
  if(requireNamespace("vroom")){
    vroom <- getExportedValue("vroom", "vroom")
    df <- vroom(init_tsv(tsv), delim = "\t", quote = "",  col_types = col_types)
  } else {
    df <- utils::read.table(init_tsv(tsv), header = TRUE, sep = "\t",
                            quote = "",  colClasses = registry_spec)
  }
  
  df[df$identifier == id, ] ## base R version
  
}


## A tsv-backed registry
history_tsv <- function(x, tsv = default_tsv(), ...) {

  
  
  if(requireNamespace("vroom")){
    vroom <- getExportedValue("vroom", "vroom")
    df <- vroom(init_tsv(tsv), delim = "\t", quote = "",  col_types = col_types)
  } else {
    df <- utils::read.table(init_tsv(tsv), header = TRUE, sep = "\t",
                            quote = "",  colClasses = registry_spec)
  }
  
  df[df$source %in% x, ] ## base R version

}

default_tsv <- function(dir = content_dir()) file.path(dir, "registry.tsv")

#' @importFrom utils read.table write.table
## intialize a tsv-based registry
init_tsv <- function(path = default_tsv()) {
  
  if (!file.exists(path)) {
    ## Create an initial file with headings
    r <- registry_entry()
    
    if(requireNamespace("vroom")){
      vroom_write <- getExportedValue("vroom", "vroom_write")
      vroom_write(r, path, delim = "\t", quote = "none")
    } else {
    utils::write.table(r[0, ], path, sep = "\t", 
                       quote = FALSE, row.names = FALSE, col.names = TRUE)
    }
  }
  
  path
}



