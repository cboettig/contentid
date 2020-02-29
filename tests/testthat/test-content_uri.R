context("content_uri")

test_that("content_uri returns the expected identifier", {

  ## Windows CI platforms will check out package from git, and
  ## in the process alter the line endings and thus the hash

  ## We will uncompress the compressed version to get the original
  ## expected content uri on all platforms
  f <- system.file("extdata", "vostok.icecore.co2.gz",
    package = "contenturi", mustWork = TRUE
  )
  id <- content_uri(f, raw = FALSE)
  expect_identical(
    id,
    paste0("hash://sha256/", 
           "9412325831dab22aeebdd674b6eb53",
           "ba6b7bdd04bb99a4dbb21ddff646287e37")
  )
})
