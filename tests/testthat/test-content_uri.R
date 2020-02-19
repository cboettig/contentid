context("content_uri")

test_that("content_uri returns the expected identifier", {
  
  f <- system.file("extdata", "vostok.icecore.co2", package="contenturi", mustWork = TRUE)
  id <- content_uri(f)
  expect_identical(id, "hash://sha256/9412325831dab22aeebdd674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37")
})