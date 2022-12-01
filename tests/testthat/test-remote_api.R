context("remote api registry")

test_that("We can register & retrieve content from the remote API", {
  skip_if_offline()
  skip_on_cran()
  skip_on_os("windows") # sometimes?
  
  ## A zenodo URL will be stable
  url <- "https://zenodo.org/api/files/5967f986-b599-4492-9a08-94ce32323dc2/vostok.icecore.co2"
  
  ## hash-archive.org may timeout more often these days...
  hash_archive <- "https://hash-archive.org"
  hash_archive <- "https://hash-archive.carlboettiger.info"
  
  id <- register(url,hash_archive)
  
  
  expect_is(id, "character")

  
  df <- query(id, registries = hash_archive)
  expect_is(df, "data.frame")
  expect_true(dim(df)[1] >= 1)

  ## Should the unit test verify the hash returned?
})
