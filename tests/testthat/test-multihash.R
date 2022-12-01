context("multihash")

test_that("We can compute multiple hashes from a single content stream", {
  
  skip_if(utils::packageVersion("openssl") <= package_version("1.4.1"))
  ex<- system.file("extdata", "vostok.icecore.co2.gz",package = "contentid")
  algos <- c("md5", "sha1", "sha256", "sha384", "sha512")
  hashes <- content_id(ex, algos = algos)
  expect_is(hashes, "data.frame")
  expect_identical(names(hashes), algos)
  expect_identical(hashes$sha256,
                   "hash://sha256/9362a6102437bff5ea508988426d5274a8addfdb11a603d016a7b305cf66868f")
})

test_that("We can set algos with an env var", {
  
  skip_if(utils::packageVersion("openssl") <= package_version("1.4.1"))
  ex<- system.file("extdata", "vostok.icecore.co2.gz",package = "contentid")
  algos <- c("md5", "sha1", "sha256", "sha384", "sha512")
  
  Sys.setenv("CONTENTID_ALGOS" = paste(algos, collapse = ","))
  
  hashes <- content_id(ex)
  expect_is(hashes, "data.frame")
  expect_identical(names(hashes), algos)
  expect_identical(hashes$sha256,
                   "hash://sha256/9362a6102437bff5ea508988426d5274a8addfdb11a603d016a7b305cf66868f")
  
  expect_identical(hashes$md5,
                   "hash://md5/bc5ef1ec8c3ab0d11e6901be278c1f72")
  
  Sys.unsetenv("CONTENTID_ALGOS")
  
  ## single hash algo must request data.frame format
  hashes <- content_id(ex, as.data.frame = TRUE)
  expect_is(hashes, "data.frame")
  expect_identical(names(hashes), "sha256")
  
})


test_that("We can register all hashes", {
  
  skip_if(utils::packageVersion("openssl") <= package_version("1.4.1"))
 
  ex<- system.file("extdata", "vostok.icecore.co2.gz",package = "contentid")
  algos <- c("md5", "sha1", "sha256", "sha384", "sha512")
  
  tsv <- tempfile(fileext = ".tsv")
  id <- register_tsv(ex, tsv, algos = algos)
  
  ## sha256 is still the internal id:
  expect_identical(id,
   "hash://sha256/9362a6102437bff5ea508988426d5274a8addfdb11a603d016a7b305cf66868f")
  
  
  df <- history_tsv(ex, tsv)
  sha1 <- as.character(na.omit(df$sha1))
  
  ## Note that the internal storage uses SRI format
  expect_identical(sha1,  "hash://sha1/026c40417ecebc5fdb138bc5a317e288369e8e08")
})

test_that("default adds sha256", {
  
  algos <- c("md5", "sha1")
  Sys.setenv("CONTENTID_ALGOS" = paste(algos, collapse = ","))
  expect_warning(a <- default_algos())
  expect_true("sha256" %in% a)
  Sys.unsetenv("CONTENTID_ALGOS")
  
  
})

