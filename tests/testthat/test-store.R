context("store")

test_that("We can store local files", {
  
  
  vostok_co2 <- system.file("extdata", "vostok.icecore.co2", package = "contenturi")
  x <- store(vostok_co2)
  expect_identical(x, "hash://sha256/9412325831dab22aeebdd674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37")
  
  ## This hash should now be in the local registry.
  ## NOTE: query_local only queries the local URL registry! It does not query the store!
  df <- query_local(x)
  expect_true(dim(df)[1] > 0)
  # identifier should register in the identifer column
  expect_true(any(df$identifier == x))
  
  ## Verify that object is in the store
  path <- store_retrieve(x)
  expect_true(file.exists(path))
  
  
  })


test_that("We can store remote files", {
  skip_if_offline()
  skip_on_cran()
  
  url <- "https://zenodo.org/record/3678928/files/vostok.icecore.co2"
  x <- store(url)

  # Confirm this hash is in the registry
  df <- query_local(x)
  expect_true(dim(df)[1] > 0)
  
  # Confirm this url is in the registry
  df <- query_local(url)
  expect_true(dim(df)[1] > 0)
  
    
})

