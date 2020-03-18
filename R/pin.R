
#' Access the latest content at a URL
#' 
#' `[latest]` will download the first time it is run, and then use a local cache
#'  unless content has changed. This behavior is similar to `pins::pin()`,
#'  but uses cryptographic content hashes. Because content hashes are computed in a fast public 
#'  content registry, this will usually be faster than downloading on a local connection,
#'  but slower than checking eTags in headers.  Use [resolve]
#' @seealso resolve
#' @param url a URL to a web resource
#' @inheritParams resolve 
#' @details at this time, `latest` cannot process FTP resources
#' @export 
#' 
#' @examples \donttest{
#' 
#' url <- paste0("https://data.giss.nasa.gov/gistemp/graphs/graph_data/",
#'        "Global_Mean_Estimates_based_on_Land_and_Ocean_Data/graph.txt")
#' x <- latest(url)
#' 
#' ## 
#' ## latest() will always check for changes. Therefore, it is faster to request
#' ## content by resolve() :
#' resolve(
#' "hash://sha256/ce1865032089bec8e8a5b0b572c2cb2e3e89bfa8b824520136232d286a908f86",
#' store = TRUE)
#'     
#' }
#' 
latest <- function(url, dir = content_dir()) {
  # Have hash-archive.org compute the identifier. Its high bandwidth
  # and fast processors will probably do so faster than local computation
  id <- register(url, registries = "https://hash-archive.org")
  
  ## resolve the curent content id.  If it matches a cached copy, resolve
  ## will use that.  If it does not, resolve will download the latest version
  resolve(id, store = TRUE, dir = dir)
}
