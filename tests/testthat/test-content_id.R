context("content_id")

test_that("content_id parses compressed file connection correctly", {

  ## Windows CI platforms will check out package from git, and
  ## in the process alter the line endings and thus the hash
  ## of the uncompressed vostok.icecore.co2.  The .gz version
  ## is not effected by Windows git line-ending conversion.
  f <- system.file("extdata", "vostok.icecore.co2.gz",
    package = "contentid", mustWork = TRUE
  )
  
  ## We will uncompress the compressed version to get the original
  ## expected content uri on all platforms  
  con <- file(f, open = "", raw = FALSE)
 
  ## This id should match that of the uncompressed content (on any platform!)
  id <- content_id(con)
  
  expect_identical(
    id[["sha256"]],
    paste0("hash://sha256/", 
           "9412325831dab22aeebdd674b6eb53",
           "ba6b7bdd04bb99a4dbb21ddff646287e37")
  )
})



test_that("content_id streams url connections", {

  skip_on_cran()
  skip_if_offline()

  co2_url <- "https://zenodo.org/record/3678928/files/vostok.icecore.co2"
  
  id <- content_id(co2_url)
  expect_identical(
    id$sha256,
    paste0("hash://sha256/", 
           "9412325831dab22aeebdd674b6eb53",
           "ba6b7bdd04bb99a4dbb21ddff646287e37")
  )
})



test_that("content_id works with direct path", {
  
  skip_on_cran()
  skip_if_offline()

  ## Note this time we leave compressed so hash should be different
  ## then the above examples
  f <- system.file("extdata", "vostok.icecore.co2.gz",
                   package = "contentid", mustWork = TRUE
  )
  id <- content_id(f)
  expect_identical(
    id$sha256,
    paste0("hash://sha256/", 
           "9362a6102437bff5ea508988426d527",
           "4a8addfdb11a603d016a7b305cf66868f")
  )
})


test_that("content_id error handling", {
  
  x <- expect_warning(content_id_("https://httpstat.us/404"), "404")
  x <- expect_warning(content_id_("https://httpstat.us/401"), "401")
  expect_true(is.na(x))
  
  
  f <- file("notafile")
  content_id_(f)
  
  expect_error(content_id_(f))
  
})




