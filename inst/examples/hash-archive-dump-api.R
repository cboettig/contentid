library(httr)
start_date <- "2021-04-01"
ha_date <- function(start_date) 
  round(as.integer(as.POSIXct(as.Date(start_date)))/1000 - 600)
duration <- 1000000000000

some <- GET(paste0("https://hash-archive.org/api/dump/?start=",
                   ha_date(start_date), "&duration=", duration))
jsonlite::write_json(content(some), paste0(start_date, ".json"))
