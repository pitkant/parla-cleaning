library(shiny)
library(RSQLite)
library(DBI)
library(quanteda)
library(shinydashboard)
library(dplyr)


upper_limit <- 2014
lower_limit <- 2000

ui <- fluidPage(
  
  titlePanel("Text networks"),
  
  sidebarLayout(
    
    sidebarPanel(
      p("Write lemmatized search term (e.g. 'puolustusvoimat' --> 'puolustus#voima'):"),
      textInput("hakutermi", "Search term:", "puolustus#voima"),
      numericInput("num", h3("KWIC / n-gram context size"), value = 3),
      checkboxInput("casesen", "Case insensitive?", value = FALSE),
      sliderInput("year_slider", "Choose years", min = lower_limit, max = upper_limit, value = c(2009, 2011)),
      actionButton("go_button", "Go")
    ),
    
    mainPanel(
      
      tabsetPanel(type = "tabs",
                  tabPanel("KWIC", tableOutput("tbl")),
                  tabPanel("n-gram", tableOutput("ngram"))
                  )
    )
  )
)

server <- function(input, output, session) {
  
  v <- reactiveValues(data = NULL)
  
  observeEvent(input$go_button, {
    conn <- dbConnect(RSQLite::SQLite(), "./data/FI2000_2014.db")
    on.exit(dbDisconnect(conn), add = TRUE)
    tables <- dbListTables(conn)
    tables_df <- data.frame(table = tables, year = substr(tables, 3, 6), type = ifelse((nchar(tables) > 6), substr(tables, 8, nchar(tables)), "vp"))
    # selected_fulltext <- SQL(tables_df$table[which(tables_df$year >= min(input$year_slider) & tables_df$year <= max(input$year_slider) & tables_df$type == "fulltext")])
    # selected_vp <- SQL(tables_df$table[which(tables_df$year >= min(input$year_slider) & tables_df$year <= max(input$year_slider) & tables_df$type == "vp")])
    sql_text <- "SELECT text, who, id_speech, id FROM vp_fulltext WHERE year BETWEEN ?year_min AND ?year_max AND id_speech IN (SELECT paragraph_id FROM vp WHERE lemma = ?lemma)"
    sql_query <- sqlInterpolate(conn, sql_text, lemma = input$hakutermi, year_min = min(input$year_slider), year_max = max(input$year_slider))
    dict_query_text <- "SELECT token FROM vp WHERE lemma = ?lemma"
    dict_query <- sqlInterpolate(conn, dict_query_text, lemma = input$hakutermi)
    v$query <- dbGetQuery(conn, sql_query)
    query2 <- dbGetQuery(conn, dict_query)
    query2 <- tolower(unname(unlist(query2)))
    v$query2 <- query2[!duplicated(query2)]
    v$toks <- corpus(x = v$query$text, docnames = v$query$id)
  })
  
  output$tbl <- renderTable({
    if (is.null(v$toks)) {
      return()
    } else {
      quanteda::kwic(v$toks, 
                      pattern = phrase(unname(unlist(v$query2))), 
                      window = input$num, 
                      case_insensitive = input$casesen)
    }
  })
  
  output$ngram <- renderTable({
    if (is.null(v$toks)) {
      return()
    } else {
      head(n = 100, x =
        sort(decreasing = TRUE, x =
          table(x =
            unlist(x =
              quanteda::as.list(quanteda::tokens_ngrams(tokens(v$query$text, 
                                     remove_punct = TRUE,
                                     remove_symbols = TRUE,
                                     remove_numbers = TRUE,
                                     remove_separators = TRUE), n = input$num, concatenator = " ")
                                )
              )
            )
          ),
        )
    }
  })
}

shinyApp(ui, server)
