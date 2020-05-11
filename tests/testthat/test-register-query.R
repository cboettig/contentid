context("local register & query")


test_that("We can query a remote registry", {
  skip_if_offline()
  # Online tests sporadically time-out on CRAN servers
  skip_on_cran()
  
  url <- "http://cdiac.ornl.gov/ftp/trends/co2/vostok.icecore.co2"
  
  x <- query(url,
             registries = "https://hash-archive.org")
  
  expect_is(x, "data.frame")
  expect_true(any(grepl(paste0("hash://sha256/",
                           "9412325831dab22aeebdd674b6eb53ba",
                           "6b7bdd04bb99a4dbb21ddff646287e37"),
                    x$identifier)))
  
})

test_that("We can register a URL in the local registry", {
  skip_if_offline()
  # Online tests sporadically time-out on CRAN servers
  skip_on_cran()

  
  reg <- default_registries()
  local <- reg[file.exists(reg)]
  
  url <- "http://cdiac.ornl.gov/ftp/trends/co2/vostok.icecore.co2"
  x <- register(
    url,
    registries = local)
  expect_is(x, "character")
  expect_true(is_hash(x, "hashuri"))
})


test_that("Warn on registering a non-existent URL", {
  skip_if_offline()
  skip_on_cran()

  local <- content_dir()
  
  expect_warning(
    register("https://httpstat.us/404", local)
  )
})


test_that("We can register to multiple registries", {
  skip_if_offline()
  skip_on_cran()

  r1 <- tempfile()
  dir.create(r1)
  r2 <- tempfile()
  dir.create(r2)

  url <- "http://cdiac.ornl.gov/ftp/trends/co2/vostok.icecore.co2"

  
  
  x <- register(url,
                registries = c(r1, r2))
  y <- query(url,
             registries = c(r1, r2))

  ## should be multiple entries from the multiple registries
  expect_true(dim(y)[1] > 1)

  ## Should be exactly 1 entry for the URL in the temporary local registry
  y <- query(url,
             registries = r1)
  expect_true(dim(y)[1] == 1)

  ## Should be exactly 1 entry for the Content Hash in temp local registry
  y <- query(x, registries = r1)
  expect_true(dim(y)[1] == 1)


  ## clear out r1
  unlink(r1)
})
