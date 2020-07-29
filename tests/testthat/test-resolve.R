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

  url <- "https://knb.ecoinformatics.org/knb/d1/mn/v2/object/ess-dive-457358fdc81d3a5-20180726T203952542"
  x <- register(url, default_tsv())
  path <- resolve(x)

  expect_true(file.exists(path))
  co2 <- read.table(path,
    skip = 20,
    col.names = c("depth", "age_ice", "age_air", "co2")
  )
  expect_true(dim(co2)[2] == 4)
})

