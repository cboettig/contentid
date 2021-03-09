context("pin")

## A zenodo URL will be stable
url <- "https://zenodo.org/record/3678928/files/vostok.icecore.co2"
## or not?
url <- "https://knb.ecoinformatics.org/knb/d1/mn/v2/object/ess-dive-457358fdc81d3a5-20180726T203952542"

## avoid timeouts on hash-archive.org
hash_archive <- "https://hash-archive.thelio.carlboettiger.info"


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



