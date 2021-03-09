context("remote api registry")

test_that("We can register & retrieve content from the remote API", {
  skip_if_offline()
  skip_on_cran()

  ## A zenodo URL will be stable
  url <- "https://zenodo.org/record/3678928/files/vostok.icecore.co2"
  ## or not.... use KNB
  url <- "https://knb.ecoinformatics.org/knb/d1/mn/v2/object/ess-dive-457358fdc81d3a5-20180726T203952542"
  ## Or use this zenodo download url:
  
  
  ## hash-archive.org may timeout more often these days...
  hash_archive <- "https://hash-archive.thelio.carlboettiger.info"
  
  id <- register(url,hash_archive)
  
  
  expect_is(id, "character")

  
  df <- query(id, registries = hash_archive)
  expect_is(df, "data.frame")
  expect_true(dim(df)[1] > 1)

  ## Should the unit test verify the hash returned?
})
