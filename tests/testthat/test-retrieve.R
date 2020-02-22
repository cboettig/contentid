context("retrieve")


test_that("we can retrieve locally stored content by hash", {
  
  
  vostok_co2 <- system.file("extdata", "vostok.icecore.co2", package = "contenturi")
  x <- store(vostok_co2)
  path <- retrieve(x)
  expect_true(file.exists(path))
})


test_that("we can retrieve remote registered content by hash", {
  
  
  skip_if_offline()
  skip_on_cran()
  
  skip("retrieve must be re-worked to understand local data")
  
  url <- "https://zenodo.org/record/3678928/files/vostok.icecore.co2"
  x <- register_local(url)
  
  ## Force local path preference
  path <- retrieve(x, prefer = "local")
  
  expect_true(file.exists(path))
  co2 <- read.table(path, skip = 20, col.names = c("depth", "age_ice", "age_air", "co2"))
  expect_true(dim(co2)[2] == 4)
  
})



test_that("we can retrieve remotely registered content by url", {
  
  
  skip_if_offline()
  skip_on_cran()
  
  url <- "https://zenodo.org/record/3678928/files/vostok.icecore.co2"
  register_local(url)  
  path <- retrieve(url, prefer = "remote")
  
  expect_true(file.exists(path))
  
  
})


