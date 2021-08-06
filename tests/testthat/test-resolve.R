context("resolve")


test_that("we can resolve identifier of locally stored content", {
  vostok_co2 <- system.file("extdata",
    "vostok.icecore.co2.gz",
    package = "contentid"
  )
  x <- store(vostok_co2)
  path <- resolve(x)
  expect_true(file.exists(path))
})


test_that("we can retrieve remote registered content by hash", {
  skip_if_offline()
  skip_on_cran()

  url <- "https://zenodo.org/api/files/5967f986-b599-4492-9a08-94ce32323dc2/vostok.icecore.co2"
  x <- register(url)
  Sys.sleep(1) # avoid overloading KNB API....
  path <- resolve(x)

  expect_true(file.exists(path))
  co2 <- read.table(path,
    skip = 20,
    col.names = c("depth", "age_ice", "age_air", "co2")
  )
  expect_true(dim(co2)[2] == 4)
})

