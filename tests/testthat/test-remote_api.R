context("remote api registry")

test_that("We can register & retrieve content from the remote API", {
  skip_if_offline()
  skip_on_cran()

  id <- register(
    "https://zenodo.org/record/3678928/files/vostok.icecore.co2",
    "https://hash-archive.org")
  expect_is(id, "character")

  
  df <- query(id, registries = "https://hash-archive.org")
  expect_is(df, "data.frame")
  expect_true(dim(df)[1] > 1)

  ## Should the unit test verify the hash returned?
})
