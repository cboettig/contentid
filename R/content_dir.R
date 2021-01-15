#' content store home directory
#' 
#' A configurable default location for persistent data storage
#' @param dir directory to be used as the home directory
#' @details This function is intended to be called internally with no
#' arguments.  It will use the directory set by the system environmental
#' variable CONTENTID_HOME, if set.  Otherwise, it will use the default
#' location returned by [tools::R_user_dir] for the application,
#' `contentid`.  Unlike rappdirs function, this function will also 
#' create the directory if it does not yet exist.
#' @importFrom fs dir_create dir_exists
#' @export
#' @examples 
#' 
#' ## example using temporary storage: 
#' Sys.setenv(CONTENTID_HOME=tempdir())
#' content_dir()
#' 
#' ## clean up
#' Sys.unsetenv("CONTENTID_HOME")
#' 
#' ## Or explicitly with an argument:
#' content_dir(tempdir())
content_dir <- function(dir = Sys.getenv(
  "CONTENTID_HOME",
  tools::R_user_dir("contentid")
)) {
  if (!fs::dir_exists(dir)) fs::dir_create(dir)
  dir
}
