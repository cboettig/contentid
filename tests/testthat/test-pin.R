context("pin")

## A zenodo URL will be stable
url <- "https://zenodo.org/api/files/5967f986-b599-4492-9a08-94ce32323dc2/vostok.icecore.co2"

## avoid timeouts on hash-archive.org
hash_archive <- "https://hash-archive.carlboettiger.info"


test_that("We can access a URL with an unverified pin", {

  skip_if_offline()
  skip_on_cran()
  
  path <- pin(url, verify = FALSE, registries = hash_archive)
  
  id <- content_id(path)
  expect_equal("hash://sha256/9412325831dab22aeebdd674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37",
               id)
  ## Should be faster now
  path <- pin(url, verify = FALSE, registries = hash_archive)
  
  
})


test_that("We can access a URL with pin", {
  
  skip_if_offline()
  skip_on_cran()
  
  path <- pin(url, registries = hash_archive)
   
  id <- content_id(path)
  expect_equal("hash://sha256/9412325831dab22aeebdd674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37",
               id)
  
  
})



