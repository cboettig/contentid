context("identifier formats")

magnet <- "magnet:?xt=urn:sha256:9412325831dab22aeebdd674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37"
sri <- "sha256-lBIyWDHasiruvdZ0tutTumt73QS7maTbsh3f9kYofjc="
ssb <- "&lBIyWDHasiruvdZ0tutTumt73QS7maTbsh3f9kYofjc=.sha256"
ni <- "ni:///sha256;lBIyWDHasiruvdZ0tutTumt73QS7maTbsh3f9kYofjc"
hashuri <- "hash://sha256/9412325831dab22aeebdd674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37"


test_that("we can convert other formats to hash uri", {

    ids <- c(magnet, sri, ssb, ni, hashuri)
    out <- as_hashuri(ids)
  
    matching <- vapply(out, function(x) 
      # Note: ni omits the optional base64 '=' ending character, corresponding to the '7e37'
      grepl("hash://sha256/9412325831dab22aeebdd674b6eb53ba6b7bdd04bb99a4dbb21ddff64628",
            x), logical(1L))
    expect_true(all(matching))
  

})



test_that("we can correctly recognize types without false ids", {
  
  expect_true(is_hash(ssb, "ssb"))
  expect_true(is_hash(ni, "ni"))
  expect_true(is_hash(sri, "sri"))
  expect_true(is_hash(magnet, "magnet"))
  expect_true(is_hash(hashuri, "hashuri"))
  
  
  expect_false(is_hash(ni, "ssb"))
  expect_false(is_hash(sri, "ni"))
  expect_false(is_hash(ssb, "sri"))
  expect_false(is_hash(hashuri, "magnet"))
  expect_false(is_hash(magnet, "hashuri"))

  expect_false(is_hash("https://example.com"))

    
  expect_true(is.na(as_hashuri("http://example.com")))
  
  
})




