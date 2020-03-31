context("tsv registry")


test_that("registry_entry creates expected template", {

  df <- registry_entry()
  expect_is(df, "data.frame")
  expect_equal(dim(df), c(1, nchar(registry_spec)))
              
})


test_that("register_tsv()", {
  
  
  ex <- system.file("extdata", "vostok.icecore.co2", package = "contentid")
  id <- register_tsv(ex)
  expect_identical(id, 
  "hash://sha256/9412325831dab22aeebdd674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37")
  
  
})



test_that("sources_tsv()", {
  
  skip_on_cran()
  skip_if_offline()

  ex <- system.file("extdata", "vostok.icecore.co2", package = "contentid")
  register_tsv(ex)

  id <- "hash://sha256/9412325831dab22aeebdd674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37"
  df <- sources_tsv(id)
    
  expect_is(df, "data.frame")
  expect_gt(dim(df)[1], 0)
  
})


test_that("history_tsv()", {
  
  skip_on_cran()
  skip_if_offline()
  
  
  ex <- system.file("extdata", "vostok.icecore.co2", package = "contentid")
  id <- register_tsv(ex)
  
  url <- "https://zenodo.org/record/3678928/files/vostok.icecore.co2"
  df <- history_tsv(url)
  expect_is(df, "data.frame")
  expect_gt(dim(df)[1], 0)
  
})



test_that("init_tsv()", {
  
  r <- init_tsv()
  expect_true(file.exists(r))
  df <- readr::read_tsv(r)
  expect_is(df, "data.frame")
  
})



