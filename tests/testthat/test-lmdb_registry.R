

test_that("init_lmdb()", {
  
  options(thor_mapsize=1e6)
  skip_on_os("solaris")
  skip_if_not_installed("thor")
  
  db_dir <- tempfile()
  db <- init_lmdb(db_dir)
  
  expect_is(db, "mdb_env") 

})



test_that("register_lmdb()", {

  skip_on_os("solaris")
  skip_if_not_installed("thor")
  
  ex <- system.file("extdata", "vostok.icecore.co2.gz",
                   package = "contentid", mustWork = TRUE
  )  
  
  db_dir <- tempfile()
  db <- default_lmdb(db_dir)
  
  
  id <- register_lmdb(ex, db)
  expect_identical(id, 
                   paste0("hash://sha256/", 
                          "9362a6102437bff5ea508988426d527",
                          "4a8addfdb11a603d016a7b305cf66868f"))

  
  df <- history_lmdb(ex, db)
  
  expect_identical(df$identifier, id)
  expect_identical(df$source, ex)
  
  df2 <- sources_lmdb(id, db)
  
  expect_identical(df2$identifier, id)
  expect_identical(df2$source, ex)
  
  
})

