
#' default registries
#'
#' A helper function to conviently load the default registries
#' @details This function is primarily useful to restrict the
#' scope of [query_sources] or [register] to, e.g. either just the
#' remote registry or just the local registry.  Note that a user
#' can alter the registry on the fly by passing local paths and/or the
#' URL (`https://hash-archive.org`) directly.
#'
#' @examples
#' ## Both defaults
#' default_registries()
#'
#' ## Only the fist one (local registry)
#' default_registry()[1]
#' \donttest{
#' ## Alter the defaults with env var.
#' ## here we set two local registries as the defaults
#' Sys.setenv(CONTENTID_REGISTRIES = "store/, store2/")
#' default_registries()
#'
#' Sys.unsetenv(CONTENTID_REGISTRIES)
#' }
#' @noRd
# @export
default_registries <- function() {
  registries <- strsplit(
    Sys.getenv(
      "CONTENTID_REGISTRIES",
      paste(
        default_tsv(),                           ## local registry
        "https://hash-archive.org",              ## Hash Archives
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