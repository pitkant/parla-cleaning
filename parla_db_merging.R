library(RSQLite)
library(DBI)

# Funktio joka siirtää taulut conn-tietokannasta conn_final tietokantaan
write_tables <- function() {
  tables <- dbListTables(conn)
  table_names <- c("vp", "vp_fulltext", "vp_vocals")
  for (i in 1:length(tables)) {
    # temp_object <- dbReadTable(conn, tables[i]))
    # temp_object$year <- substr(temp_object$id_speech, 3, 6)
    table_to_write <- dbReadTable(conn, tables[i])
    table_to_write$year <- substr(tables[i], 3, 6)
    dbWriteTable(conn_final, table_names[i], table_to_write, overwrite = FALSE, append = TRUE)
  }
  dbDisconnect(conn)
}

# Lopullinen .db-tiedosto johon kirjoitetaan kaikkien vuosien tiedot
conn_final <- dbConnect(RSQLite::SQLite(), "./Downloads/db/FI2000_2014.db")
# Vaihda tiedostopolku ja käsiteltävä tiedosto oikeaan, 
# isoja kansioita käsiteltäessä tähän voisi kirjoittaa jonkinlaisen loopinkin...
conn <- dbConnect(RSQLite::SQLite(), "./Downloads/db/FI2014.db")

write_tables()

# Tarkista että conn_final tietokannassa on kaikki tarvittavat taulut
dbListTables(conn_final)

dbDisconnect(conn_final)

