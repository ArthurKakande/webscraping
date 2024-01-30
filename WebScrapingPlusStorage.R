#install.packages("rvest")
#install.packages("dplyr")
#install.packages("glue")

library("rvest")
library("dplyr")
library("glue")

url = "https://www.imdb.com/list/ls055386972/"
page = read_html(url)
name = page %>% html_nodes(".lister-item-header a") %>% html_text()
year = page %>% html_nodes(".text-muted.unbold") %>% html_text()
synopsis = page %>% html_nodes(".ipl-rating-widget+ p , .ratings-metascore+ p") %>% html_text()
rating = page %>% html_nodes(".ipl-rating-star.small .ipl-rating-star__rating") %>% html_text()

year = year[-c(1,2,3)]

movie_dataset = data.frame(name, year, rating, synopsis, stringsAsFactors = FALSE)
https://www.imdb.com/title/tt0088763/fullcredits?ref_=tt_cl_sm

movie_links = page %>% html_nodes(".lister-item-header a") %>% html_attr("href") %>% paste("https://www.imdb.com", ., sep="")

get_cast = function(movie_link){
  cast_link <- sub("\\?ref_=ttls_li_tt$", "fullcredits?ref_=tt_cl_sm", movie_link)
  cast_page <- read_html(cast_link)
  cast = cast_page %>% html_nodes(".primary_photo+ td a") %>% html_text() %>% paste(collapse = ",")
  return(cast)
  
}

cast = sapply(movie_links, get_cast, USE.NAMES = FALSE)
movie_dataset = data.frame(name, year, rating, synopsis, cast, stringsAsFactors = FALSE)

#scraping tables
tablelink = "https://www.patriotsoftware.com/blog/accounting/average-cost-living-by-state/"
table_page <- read_html(tablelink)

all_tables <- html_table(table_page, fill = T)
income_distribution <- all_tables[[1]]

#Data storage
library(RSQL)
library(RSQLite)

con = dbConnect(drv = RSQLite::SQLite(),
                dbname = ":memory:")

dbListTables(con)
dbWriteTable(conn = con,
             name = "movies",
             value = movie_dataset)
dbWriteTable(conn = con,
             name = "income",
             value = income_distribution)

#Data Analysis and Reading
  <- DBI::dbGetQuery(conn = con,
                               statement = "SELECT name, rating FROM movies WHERE rating >= 9")