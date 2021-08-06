context("purge")

test_that("We can purge local files", {
  
  
  vostok_co2 <- system.file("extdata",
                            "vostok.icecore.co2.gz",
                            package = "contentid"
  )
  id <- store(vostok_co2)
  path <- resolve(id)
  ## confirm file is in local store
  expect_true(file.exists(content_based_location(id)))
  expect_true(file.exists(path))
  
  ## verify file is purged
  purge_cache(age = 0, threshold = 0)
  expect_false(file.exists(path))
  
})
