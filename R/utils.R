
#' @importFrom tools file_ext
file_ext <- function(x) {
  ext <- tools::file_ext(x)
  ## if compressed, chop off that and try again
  if (ext %in% c("gz", "bz2", "xz", "zip")) {
    ext <- tools::file_ext(gsub("\\.([[:alnum:]]+)$", "", x))
  }
  ext
}


## Download a resource to temporary local path, if necessary
#' @importFrom curl curl_download
download_resource <- function(x) {
  ## x is a local file
  if (file.exists(x)) {
    path <- x
  }

  ## x is a URL
  if (is_url(x)) {
    tmp <- tempfile(fileext = file_ext(x))
    curl::curl_download(x, tmp)
    path <- tmp
  }
  path
}

## These should be much more general!
add_prefix <- function(x) paste0("hash://sha256/", x)
strip_prefix <- function(x) gsub("^hash://sha256/", "", x)
is_url <- function(x) grepl("^((http|ftp)s?|sftp)://", x)



stream_connection <- function(file, download = FALSE, open = "rb", raw = TRUE){
  
  if (inherits(file, "connection")) {
    return(file)
  }
  
  ## URL connection
  if (is_url(file)) {
      if(!download) return( curl::curl(file) )
      file <- curl::curl_download(file, tempfile())
  }
  
  ## Path Name
  if (is.character(file)) {
    file <- file(file, open = open, raw = raw) 
    ## cannot close on exit, but we register a finalizer?
    env <-  parent.env(environment())
    reg.finalizer(env, function(env) close(file))
  }
  if (!inherits(file, "connection")) 
    stop("'file' must be a character string or connection")
  
  file
}

## Here we go.  Really quite worried this is a slower / more memory-intensive way to file.copy
## f <- curl::curl_download("https://github.com/boettiger-lab/taxadb-cache/releases/download/2019/dwc_gbif.tsv.bz2", tempfile())
# bench::mark({ fs::file_copy(f, tempfile()) })
# bench::mark({ stream_binary(file(f, "rb"), tempfile()) })

## much faster with higher `n` but involves more memory use
stream_binary <- function(input, dest, n = 1e5){
  if(!isOpen(input, "rb")){
    open(input, "rb")
    on.exit(close(input))
  }
  output <- file(dest, "wb")
  while(length(obj <- readBin(input, "raw", n = n))){
    writeBin(obj, output, useBytes = TRUE)
  } 
  close(output)
  dest
}



most_recent_sources <- function(df){
  
  reg <- df[order(df$date, decreasing = TRUE),]
  unique_sources <- unique(reg$source)
  
  out <- registry_entry(id = reg$identifier[[1]], 
                        source = unique_sources, 
                        date = as.POSIXct(NA))
  
  for(i in seq_along(unique_sources)){
    out[i,] <- reg[reg$source == unique_sources[i], ][1,]
  }
  out
}

filter_sources <- function(df, registries = default_registries(), 
                           cols = c("source, date")){
  id_sources <- most_recent_sources(df)
  
  ## Now, check history for all these URLs and see if the content is current 
  url_sources <- id_sources$source[is_url(id_sources$source)]
  history <- do.call(rbind, lapply(url_sources, query_history, registries = registries))
  
  
  recent_history <- most_recent_sources(history)
  
  out <- most_recent_sources(rbind(recent_history, id_sources))
   
  
  out$status[out$status >= 400L] <- NA_integer_
  out <- out[!is.na(out$status), ]
  out[cols]
  
}


