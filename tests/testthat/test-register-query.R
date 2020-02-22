context("local register & query")

test_that("We can register a URL in the local registry", {
  skip_if_offline()
  # Online tests sporadically time-out on CRAN servers
  skip_on_cran() 
  
  x <- register_local("https://zenodo.org/record/3678928/files/vostok.icecore.co2")
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


test_that("We can register to multiple registries", {
  
  skip_if_offline()
  skip_on_cran() 
  
  r1 <- tempfile()
  dir.create(r1)
  r2 <- tempfile()
  dir.create(r2)

    
  x <- register("https://zenodo.org/record/3678928/files/vostok.icecore.co2", registries = c(r1, r2))
  y <- query("https://zenodo.org/record/3678928/files/vostok.icecore.co2", registries = c(r1, r2))
  
  ## should be multiple entries from the multiple registries
  expect_true(dim(y)[1] > 1)
  
  ## Should be exactly 1 entry for the URL in the temporary local registry 
  y <- query("https://zenodo.org/record/3678928/files/vostok.icecore.co2", registries = r1)
  expect_true(dim(y)[1] == 1)
  
  ## Should be exactly 1 entry for the Content Hash in the temporary local registry 
  y <- query(x, registries = r1)
  expect_true(dim(y)[1] == 1)
  
  
  ## clear out r1
  unlink(r1)

    
})



