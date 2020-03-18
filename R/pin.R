

pin <- function(uri, dir = content_dir()) {
  x <- retrieve(uri, dir = dir)

  if (!is_content_uri(uri)) {
    uri <- store(uri, dir = dir)
  }
  retrieve(uri, dir = dir)
}
