context("tsv registry")


test_that("registry_entry creates expected template", {

  df <- registry_entry()
  expect_is(df, "data.frame")
  expect_equal(dim(df), c(1, length(registry_spec)))
              
})


test_that("register_tsv()", {
  
  ex <- system.file("extdata", "vostok.icecore.co2.gz",
                   package = "contentid", mustWork = TRUE
  )  
  id <- register_tsv(ex)
  expect_identical(id, 
                   paste0("hash://sha256/", 
                          "9362a6102437bff5ea508988426d527",
                          "4a8addfdb11a603d016a7b305cf66868f"))
  
  
})



test_that("sources_tsv()", {
  
  ex <- system.file("extdata", "vostok.icecore.co2", package = "contentid")
  register_tsv(ex)

  id <- "hash://sha256/9412325831dab22aeebdd674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37"
  df <- sources_tsv(id)
    
  expect_is(df, "data.frame")
  expect_gt(dim(df)[1], 0)
  
})


test_that("url with history_tsv()", {
  
  skip_on_cran()
  skip_if_offline()
  
  url <- "http://cdiac.ornl.gov/ftp/trends/co2/vostok.icecore.co2"
  id <- register_tsv(url)
  
  df <- history_tsv(url)
  expect_is(df, "data.frame")
  expect_gt(dim(df)[1], 0)
  
})

test_that("history_tsv()", {
  
  ex <- system.file("extdata", "vostok.icecore.co2", package = "contentid")
  id <- register_tsv(ex)
  
  
  df <- history_tsv(ex)
  expect_is(df, "data.frame")
  expect_gt(dim(df)[1], 0)
  
})



test_that("init_tsv()", {
  
  r <- init_tsv()
  expect_true(file.exists(r))
  df <- read.table(r, sep = "\t", header = TRUE, quote = "")
  expect_is(df, "data.frame")
  
})



