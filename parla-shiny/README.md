# WP 3.5 TEXT NETWORK ANALYSIS OF POLITICAL TEXTS

# Installation and running

Install the necessary dependencies in R:

```{r}
install.packages(c("shiny", "RSQLite", "DBI", "quanteda", "dplyr"))
```

Set parla-shiny folder as your working directory:

```{r}
# Check your working directory is
getwd()
# Set your working directory to parla-shiny 
# Change the folder names in quotation marks to your local settings
setwd("parla-shiny")
```

Load Shiny:

```{r}
library(shiny)
```

Run Shiny app by writing the following command to your console:

```{r}
runApp()
```

Alternatively, you can open the app.R file e.g. in RStudio and click the "Run App" button on upper right corner of the Source editor.

## Using the Shiny App

In its current form, the Shiny app has only very basic functionalities and includes a database file with years 2000-2014. You can create Keyword-in-context (KWIC) tables for lemmatized search terms, for example "puolustus#voima" for texts that contain "Finnish Defence Force" in its various inflected forms. The context size can be adjusted.

n-gram tab opens a view that shows 100 most often used n-grams (bigrams, trigrams etc.). 
