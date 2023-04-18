# Using rvest and XML2 to extract XML information ####
# Source: https://stackoverflow.com/questions/32896861/from-xml-attributes-to-data-frame-in-r


# Load required libraries
library(xml2)
library(rvest)
library(magrittr)
library(dplyr)

# ALWAYS LOAD XML DATA AGAIN IN NEW SESSION
doc <- xml2::read_xml("/Users/pyrykantanen/speechxml2csv/uusi2/PROCESSED/Speeches_2014.xml")
doc_1 <- xml2::xml_find_all(doc, ".//text/body/div")

# Create an empty data frame with 5 columns
# Remember to refresh df every time you run the script
columns <- c("head", "ana", "id", "who", "text")
df <- data.frame(matrix(nrow = 0, ncol = length(columns)))
colnames(df) <- columns

if (TRUE) {
  for (i in seq_along(doc_1)) {
    head <- doc_1[i] %>% rvest::html_elements("head") %>% xml2::xml_text() %>% trimws()
    # If head contains more elements (notably elements like <listBibl><head><bibl>) remove them
    if (length(head) > 1) {
      # Extract different contents with
      head <- doc_1[i] %>% rvest::html_elements("head") %>% xml2::xml_contents() %>% trimws()
      # 1st element contains only the broad topic without "Related documents:"
      head <- head[1]
    }
    # speeches_note <- doc_1[i] %>% rvest::html_elements("note")
    speeches_u <- doc_1[i] %>% rvest::html_elements("u")
    
    harvested <- data.frame(
      head = rep(head, times = length(xml_length(speeches_u))),
      ana = speeches_u %>% xml2::xml_attr("ana"),
      id = speeches_u %>% xml2::xml_attr("id"),
      id_speech = speeches_u %>% xml2::xml_attr("id") %>% gsub("\\.[[:digit:]]+$", "", x = .),
      who = speeches_u %>% xml2::xml_attr("who"),
      text = speeches_u %>% xml2::xml_text()
    )
    # Append new data.frame to the end of the old one
    df <- rbind(df, harvested)
  }
}

# Add metadata
speeches_note <- doc %>% html_elements("note")

metadata_df <- data.frame(
  link = speeches_note %>% xml_attr("link"),
  multilingual = speeches_note %>% xml_attr("multilingual"),
  speechType = speeches_note %>% xml_attr("speechType"),
  type = speeches_note %>% xml_attr("type"),
  id_speech = speeches_note %>% xml_attr("id"),
  lang = speeches_note %>% xml_attr("lang")
)

# Put everything in one big data.frame
full_df2 <- dplyr::inner_join(df, metadata_df, by = "id_speech")

# Add vocal
speeches_vocal <- doc_1 %>% html_elements("vocal")

vocalisation_df <- data.frame(
  segment_id = speeches_vocal %>% xml_parent() %>% xml_find_all(., "//vocal/preceding-sibling::*[1]") %>% xml_attr("id"),
  who = speeches_vocal %>% xml_attr("who"),
  vocalisation_text = speeches_vocal %>% xml_text()
)

# Go the dataframe through row-by-row. If segment_id is NA then take segment_id from the row above
for (i in seq_len(nrow(vocalisation_df))) {
  if (is.na(vocalisation_df$segment_id[i])) {
    vocalisation_df$segment_id[i] <- vocalisation_df$segment_id[i-1]
  }
}

# Multilingual-tekstien käsittely erillisinä vrt. täysin suomenkieliset puheet ####

library(reticulate)
trankit <- import("trankit")
# Miten trankit laitetaan auto modeen?
# Näin:
p <- trankit$Pipeline('finnish')
# Check which language is active
p$active_lang
# Add swedish
p$add('swedish')
# Set auto mode on
p$set_auto(state = TRUE)
# Now trankit automatically detects which language to use


handle_parl <- function(dataset) {

  t <- tempfile(pattern=paste("foo", Sys.getpid(), sep=""))
  
  parl_col_names <- c("doc_id", "paragraph_id", "sentence_id", 
                      "sentence", "token_id", "token", "lemma", 
                      "upos", "xpos", "feats", "head_token_id", 
                      "dep_rel", "deps", "misc")
  
  datafreimi <- data.frame(matrix(nrow = 0, ncol = length(parl_col_names)))
  colnames(datafreimi) <- parl_col_names
  write.table(datafreimi, paste0("output", Sys.getpid(), ".csv"), append = FALSE, col.names = TRUE)
  pb = txtProgressBar(min = 0, max = nrow(dataset), initial = 0, style = 3)
  for (i in seq_len(nrow(dataset))) {
    if (!identical(trimws(dataset$text[i]), "")) {
      if (dataset$multilingual[i] == "true") {
        splitatut <- p$ssplit(dataset$text[i])
        splitatut <- unlist(unname(sapply(splitatut$sentences, `[`, "text")))
        for (j in seq_len(length(splitatut))) {
          output <-  p(splitatut[j])
          sentence_lang <- output$lang
          conllu_doc <- trankit$trankit2conllu(output)
          write(conllu_doc, file = t)
          ud_conllu <- udpipe::udpipe_read_conllu(t)
          ud_conllu$paragraph_id <- dataset$id_speech[i]
          ud_conllu$sentence_id <- dataset$id[i]
          ud_conllu$sentence <- j
          ud_conllu$doc_id <- substr(dataset$id_speech[i], start = 1, stop = 8)
          ud_conllu$misc <- paste0("lang:", sentence_lang)
          write.table(ud_conllu, paste0("output", Sys.getpid(), ".csv"), append = TRUE, row.names = FALSE, col.names = FALSE)
          # datafreimi <- rbind(datafreimi, ud_conllu)
        }
      } else {
        output <- p(dataset$text[i])
        paragraph_language <- output$lang
        conllu_doc <- trankit$trankit2conllu(output)
        write(conllu_doc, file = t)
        ud_conllu <- udpipe::udpipe_read_conllu(t)
        ud_conllu$paragraph_id <- dataset$id_speech[i]
        ud_conllu$sentence_id <- dataset$id[i]
        ud_conllu$sentence <- 1
        ud_conllu$doc_id <- substr(dataset$id_speech[i], start = 1, stop = 8)
        ud_conllu$misc <- paste0("lang:", paragraph_language)
        write.table(ud_conllu, paste0("output", Sys.getpid(), ".csv"), append = TRUE, row.names = FALSE, col.names = FALSE)
        # datafreimi <- rbind(datafreimi, ud_conllu)
      }
    }
    setTxtProgressBar(pb, i)
  }
  close(pb)
  # return(datafreimi)
}

dataset_to_handle <- full_df2

for (i in seq_len(nrow(dataset_to_handle[,]))) {
  if (!identical(trimws(dataset_to_handle$text[i]), "")) {
    if (dataset_to_handle$lang[i] == "fi" & dataset_to_handle$multilingual[i] == "false") {
      write(dataset_to_handle$text[i], file = paste0("./input_files/", dataset_to_handle$id[i], ".txt"))
    }
  }
}

# Swedish and multilingual stuff here
handle_parl(dataset_to_handle[dataset_to_handle$lang == "sv" | dataset_to_handle$multilingual == "true",])

conllu_path <- "./Downloads/output_files/"
files <- list.files(path = conllu_path)

read_conllu_files <- function() {
  parl_col_names <- c("doc_id", "paragraph_id", "sentence_id", 
                      "sentence", "token_id", "token", "lemma", 
                      "upos", "xpos", "feats", "head_token_id", 
                      "dep_rel", "deps", "misc")
  
  datafreimi <- data.frame(matrix(nrow = 0, ncol = length(parl_col_names)))
  colnames(datafreimi) <- parl_col_names
  
  write.table(datafreimi, paste0("output", Sys.getpid(), ".csv"), append = FALSE, col.names = TRUE)
  
  for (i in seq_along(files)) {
    ud_conllu <- udpipe::udpipe_read_conllu(paste0(conllu_path, files[i]))
    ud_conllu$sentence_id <- gsub(".conllu", "", files[i])
    ud_conllu$paragraph_id <- gsub(".[[:digit:]]*.conllu$", "", files[i])
    ud_conllu$doc_id <- gsub("_[[:digit:]]*.[[:digit:]]*.conllu$", "", files[i])
    ud_conllu$misc <- "lang:finnish"
    ud_conllu$sentence <- 1
    write.table(ud_conllu, paste0("output", Sys.getpid(), ".csv"), append = TRUE, row.names = FALSE, col.names = FALSE)
  }
}

read_conllu_files()

outputti_colab <- read.table("output3571.csv", header = TRUE)
outputti_local <- read.table("output3571 kopio.csv", header = TRUE)
outputti_total <- rbind(outputti_colab, outputti_local)

# Explanation:
  
#  ^.*_ matches any character at the beginning of the string until the last underscore character (_)
# (\\d+) captures one or more digits and stores them in a group
# \\. matches the dot character (.) after the number
# .*$ matches any remaining characters until the end of the string

# The replacement string \\1 replaces the whole matched string with the content 
# of the first capturing group (i.e., the number)

# outputti_total$meeting.num <- formatC(as.numeric(gsub("^.*_(\\d+)_.*$", "\\1", outputti_total$sentence_id)), width = 3, flag = "0")

# Explanation:

# ^.*_ matches any character at the beginning of the string until the last underscore character (_)
# (\\d+) captures one or more digits and stores them in a group
# _.*$ matches any character after the underscore until the end of the string

# The replacement string \\1 replaces the whole matched string with the content 
# of the first capturing group (i.e., the number)
# Note that if you want to extract a different number, you just need to 
# change the index of the capturing group in the replacement string. 
# For example, if you want to extract the second number (i.e., 2 in the 
# example string), you can use gsub("^.*_\\d+_(\\d+)\\..*$", "\\1", string) 
# instead.

# outputti_total$final_signifier <- paste0("FI2003_", outputti_total$meeting.num, "_", outputti_total$speech.num, ".", outputti_total$segment.num)

outputti_total$order_by <- paste0(
  # FI + year
  substr(outputti_total$doc_id, 1, 6),
  "_",
  # meeting number
  formatC(as.numeric(gsub("^.*_(\\d+)_.*$", "\\1", outputti_total$sentence_id)), width = 3, flag = "0"),
  "_",
  # speech number
  formatC(as.numeric(gsub("^.*_(\\d+)\\..*$", "\\1", outputti_total$sentence_id)), width = 3, flag = "0"),
  ".",
  # segment number
  formatC(as.numeric(gsub("[[:alnum:]]{6}_[[:alnum:]]{1,3}_[[:alnum:]]{1,3}.", "", outputti_total$sentence_id)), width = 3, flag = "0")
)

# Arrange data, since it is messed up after combining Finnish and multilingual rows
outputti_total <- dplyr::arrange(outputti_total, order_by)

# Save everything in SQLite database

library(RSQLite)
# Create a .db file
conn <- dbConnect(RSQLite::SQLite(), "FI2014.db")
dbWriteTable(conn, "vp2014", outputti_total, overwrite = TRUE)
dbWriteTable(conn, "vp2014_fulltext", full_df2)
dbWriteTable(conn, "vp2014_vocals", vocalisation_df)
dbListTables(conn)
dbDisconnect(conn)
