
context("DataONE")
 

test_that("we can return sources from DataONE", {
  
  skip_if_offline()
  skip_on_cran()
  
  id <- paste0("hash://md5/e27c99a7f701dab97b7d09c467acf468")
  df <- sources_dataone(id)
  expect_is(df, "data.frame")
  expect_gt(nrow(df), 0)
  
  df <- query_sources(id, registries = "https://cn.dataone.org")
  expect_is(df, "data.frame")
  expect_gt(nrow(df), 0)
  
  x <- resolve(id, registries = "https://cn.dataone.org")
  
})


test_that("we return missing hashes gracefully from DataONE", {
  
  skip_if_offline()
  skip_on_cran()
  
  id <- paste0("hash://sha256/9412325831dab22aeebdd",
               "674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37")
  df <- sources_dataone(id)
  expect_is(df, "data.frame")
  expect_equal(nrow(df), 0)
  
})