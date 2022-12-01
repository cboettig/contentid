
context("DataONE")
 

test_that("we can return sources from DataONE", {
  
  skip_if_offline()
  skip_on_cran()
  
  skip_on_os("windows") # WTF
  
  # id <- "hash://md5/e27c99a7f701dab97b7d09c467acf468"
  id <- "hash://md5/2ac33190eab5a5c739bad29754532d76"
  df <- sources_dataone(id)
  expect_is(df, "data.frame")
  expect_gt(nrow(df), 0)
  
  df <- query_sources(id, registries = "dataone")
  expect_is(df, "data.frame")
  expect_gt(nrow(df), 0)
  
  x <- resolve(id,  registries = "dataone", store = TRUE)
  df <- read.table(x, skip=21)
  expect_gt(nrow(df), 0)
  
  # should have a local source now too
  df <- query_sources(id, registries = c("dataone", content_dir()))
  expect_gt(nrow(df), 1)
  
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