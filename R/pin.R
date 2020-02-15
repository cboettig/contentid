

pin <- function(uri, dir = app_dir()){
  
  if(!is_content_uri(uri)){
    uri <- store(uri, dir = dir)
  }
  retrieve(uri, dir = dir)
}  
