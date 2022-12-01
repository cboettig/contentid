
context("software heritage")
 

test_that("we can return sources from software heritage", {
  
  skip_if_offline()
  skip_on_cran()
  
  id <- paste0("hash://sha256/9412325831dab22aeebdd",
                "674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37")
  df <- sources_swh(id)
  expect_is(df, "data.frame")
  
})

test_that("we can use software heritage API fns", {

  skip_if_offline()
  skip_on_cran()
  
  x <- store_swh(  "https://github.com/CSSEGISandData/COVID-19")
  expect_is(x, "list")
  
  x<- history_swh("https://github.com/CSSEGISandData/COVID-19")
  expect_is(x, "list")
  

  id <- paste0("hash://sha256/9412325831dab22aeebdd",
                "674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37")
  x <- retrieve_swh(id)
  expect_is(x, "character")

})
