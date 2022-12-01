
#' default registries
#'
#' A helper function to conveniently load the default registries
#' @details This function is primarily useful to restrict the
#' scope of [sources] or [register] to, e.g. either just the
#' remote registry or just the local registry.  Note that a user
#' can alter the registry on the fly by passing local paths and/or the
#' URL (`https://hash-archive.org`) directly.
#'
#' @examples
#' ## Both defaults
#' default_registries()
#'
#' ## Only the fist one (local registry)
#' default_registries()[1]
#' \donttest{
#' ## Alter the defaults with env var.
#' Sys.setenv(CONTENTID_REGISTRIES = tempfile())
#' default_registries()
#'
#' Sys.unsetenv("CONTENTID_REGISTRIES")
#' }
#' @export
default_registries <- function() {
  registries <- strsplit(
    Sys.getenv(
      "CONTENTID_REGISTRIES",
      paste(
        default_tsv(),                           ## local registry
#        "https://hash-archive.org",              ## Hash Archives
        "https://hash-archive.carlboettiger.info",
        "https://archive.softwareheritage.org",  
        "https://cn.dataone.org",
        "https://zenodo.org",
        content_dir(),                           ## Local stores
        sep = ", "
      )
    ),
    ", "
  )[[1]]
  
  registries
}