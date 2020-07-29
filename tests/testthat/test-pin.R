context("pin")

  ## A zenodo URL will be stable
  url <- "https://zenodo.org/record/3678928/files/vostok.icecore.co2"
  ## or not?
  
  url <- "https://knb.ecoinformatics.org/knb/d1/mn/v2/object/ess-dive-457358fdc81d3a5-20180726T203952542"



test_that("We can access a URL with an unverified pin", {

  
  path <- pin(url, verify = FALSE)
  
  id <- content_id(path)
  expect_equal("hash://sha256/9412325831dab22aeebdd674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37",
               id$sha256)
  ## Should be faster now
  ## A zenodo URL will be stable
  path <- pin(url, verify = FALSE)
  
  
})


test_that("We can access a URL with pin", {
  
  
  path <- pin(url)
   
  id <- content_id(path)
  expect_equal("hash://sha256/9412325831dab22aeebdd674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37",
               id$sha256)
  
  
})



