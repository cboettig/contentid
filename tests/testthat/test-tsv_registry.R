context("tsv registry")


test_that("registry_entry creates expected template", {

  df <- registry_entry()
  expect_is(df, "data.frame")
  expect_equal(dim(df), c(1, length(registry_spec)))
              
})



test_that("init_tsv()", {
  
  tsv <- tempfile(fileext = ".tsv")
  
  r <- init_tsv(tsv)
  expect_identical(r, tsv) # returns the path
  expect_true(file.exists(r))
  df <- read.table(r, sep = "\t", header = TRUE, quote = "")
  expect_is(df, "data.frame")
  # tempfile should have 10 cols but no rows
  expect_equal(dim(df)[2], length(registry_spec))
  
  unlink(tsv)  
})






test_that("register_tsv()", {
  
  ex <- system.file("extdata", "vostok.icecore.co2.gz",
                   package = "contentid", mustWork = TRUE
  )  
  
  r1 <- tempfile(fileext = ".tsv")
  
  id <- register_tsv(ex, r1)
  expect_identical(id, 
                   paste0("hash://sha256/", 
                          "9362a6102437bff5ea508988426d527",
                          "4a8addfdb11a603d016a7b305cf66868f"))

  expect_true(file.exists(r1))
  
  df <- read.table(r1, sep = "\t", header = TRUE, quote = "", colClasses = registry_spec)
  expect_true(ex %in% df$source)
  expect_true(id %in% df$identifier)
  
})



test_that("sources_tsv()", {
  
  ex <- system.file("extdata", "vostok.icecore.co2.gz",
                    package = "contentid", mustWork = TRUE
  )  
  
  r1 <- tempfile(fileext = ".tsv")
  
  id <- register_tsv(ex, r1)
  

  known_id <- paste0("hash://sha256/", 
         "9362a6102437bff5ea508988426d527",
         "4a8addfdb11a603d016a7b305cf66868f")
  expect_identical(id, known_id)
  
  df <- sources_tsv(id, r1)
    
  expect_is(df, "data.frame")
  expect_gt(dim(df)[1], 0)
  
})


test_that("url with history_tsv()", {
  
  skip_on_cran()
  skip_if_offline()
  
  url <- "https://knb.ecoinformatics.org/knb/d1/mn/v2/object/ess-dive-457358fdc81d3a5-20180726T203952542"
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


