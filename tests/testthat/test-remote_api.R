context("remote api registry")

test_that("We can register & retrieve content from the remote API", {
  
  
  skip_if_offline()
  skip_on_cran()
  
  id <- register_remote("http://cdiac.ornl.gov/ftp/trends/co2/vostok.icecore.co2")
  df <- query_remote(id)
  
  
  
  ## Should the unit test verify the hash returned?
  
})