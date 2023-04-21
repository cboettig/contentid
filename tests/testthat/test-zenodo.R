
context("Zenodo")
 

test_that("we can return sources from Zenodo", {
  
  skip_if_offline()
  skip_on_cran()
  
  id <- paste0("hash://md5/61b36a86930f6ffb073f4e189bbd5723")
  df <- sources_zenodo(id)
  expect_is(df, "data.frame")
  expect_gt(nrow(df), 0)
  
})

