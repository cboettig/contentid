context("remote api registry")

test_that("We can register & retrieve content from the remote API", {
  skip_if_offline()
  skip_on_cran()

  id <- register_remote("https://zenodo.org/record/3678928/files/vostok.icecore.co2")
  expect_is(id, "character")

  df <- query_remote(id)
  expect_is(df, "data.frame")

  expect_true(dim(df)[1] > 1)

  ## Should the unit test verify the hash returned?
})
