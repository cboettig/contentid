
context("software heritage")
 
test_that("we can return sources from software heritage", {
  id <- paste0("hash://sha256/9412325831dab22aeebdd",
                "674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37")
  df <- sources_swh(id)

})

history_swh("https://github.com/cboettig/content-store")

store_swh("https://github.com/cboettig/content-store")

id <- paste0("hash://sha256/9412325831dab22aeebdd",
              "674b6eb53ba6b7bdd04bb99a4dbb21ddff646287e37")
retrieve_swh(id)


