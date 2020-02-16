context("local register")

test_that("We can register a URL in the local registry", {
  skip_if_offline()
  # Online tests sporadically time-out on CRAN servers
  skip_on_cran() 
  
  x <- register_local("http://cdiac.ornl.gov/ftp/trends/co2/vostok.icecore.co2")
  expect_is(x, "character")
  expect_true(is_content_uri(x))
})


test_that("Error handling in registering a non-existent URL", {
  
  skip_if_offline()
  skip_on_cran() 
  
  expect_error(
    register_local("https://httpstat.us/404")
  )
  
})


