context("store")

test_that("We can store local files", {

  ## Store the binary (compressed) version, so that
  ## Windows git checkout cannot change the file-endings
  vostok_co2 <- system.file("extdata",
    "vostok.icecore.co2.gz",
    package = "contentid"
  )
  id <- store(vostok_co2)
  expect_identical(
    id,
    paste0(
      "hash://sha256/",
      "9362a6102437bff5ea508988426d5274",
      "a8addfdb11a603d016a7b305cf66868f"
    )
  )

  ## Verify that object is in the store
  path <- retrieve(id)
  expect_true(file.exists(path))
})


test_that("We can store remote files", {
  skip_if_offline()
  skip_on_cran()

  url <- "https://zenodo.org/api/files/5967f986-b599-4492-9a08-94ce32323dc2/vostok.icecore.co2"
  x <- store(url)

  # Confirm this hash is in the registry
  df <- query(x, registries = content_dir())
  expect_true(dim(df)[1] > 0)

  ## We will no longer automatically register the url, store isn't a registry
  # Confirm this url is in the registry
  #df <- query_local(url)
  #expect_true(dim(df)[1] > 0)
})
