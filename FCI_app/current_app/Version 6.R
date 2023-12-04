library(shiny)
library(readr)
library(tidyverse)
library(data.table)
library(ggplot2)
library(shinyWidgets)
library(janitor)
library(plotly)
library(shinydashboard)
library(DT)
library(shinythemes)
library(see)
wd = getwd()

egypt_data <- read_csv('data/Egypt_DataFrame.csv') %>%
  clean_names() %>%
  mutate(
    country = 'Egypt'
  )
hungary_data <- read_csv('data/Hungary_DataFrame.csv') %>% 
  clean_names() %>%
  mutate(
    country = 'Hungary'
  )
nigeria_data <- read_csv('data/Nigeria_DataFrame.csv') %>% 
  clean_names() %>%
  mutate(
    country = 'Nigeria'
  )
poland_data <- read_csv('data/Poland_DataFrame.csv') %>% 
  clean_names() %>%
  mutate(
    country = 'Poland'
  )
romania_data <- read_csv('data/Romania_DataFrame.csv') %>% 
  clean_names() %>%
  mutate(
    country = 'Romania'
  )

hungary_fci <- read_csv("data/hungary_fci.csv") %>%
  mutate(country = 'Hungary')
poland_fci <- read_csv("data/poland_fci.csv") %>%
  mutate(country = 'Poland')
romania_fci <- read_csv("data/romania_fci.csv") %>%
  mutate(country = 'Romania')
egypt_fci <- read_csv("data/egypt_fci.csv") %>%
  mutate(country = 'Egypt')

combined_data <- bind_rows(egypt_data, hungary_data, nigeria_data, poland_data, 
                           romania_data)

combined_fci <- bind_rows(hungary_fci, poland_fci, romania_fci, egypt_fci)


ui <- dashboardPage(
  dashboardHeader(title = "Financial Data Explorer"),
  dashboardSidebar(
    selectInput("country", "Select Country", choices = unique(combined_data$country)),
    varSelectInput("var", "Choose variable", combined_data %>% select(-date, -country)),
    dateRangeInput("dateRange", "Select Date Range", start = min(combined_data$date), end = max(combined_data$date)),
    prettyCheckbox("smooth", "Apply smooth line"),
    actionButton("showData", "Show Complete Data")
  ),
  dashboardBody(
    tabsetPanel(
      tabPanel("Plot", plotlyOutput("explorePlot", height = "500px"),downloadButton("downloadPlot", "Download Plot")),
      tabPanel("Selected Data", DTOutput("selectedTable"),downloadButton("downloadData", "Download Selected Data")),
      tabPanel("Data Summary", DTOutput("summaryTable"), plotOutput("summaryPlot")),
      tabPanel(
        "Compare Countries", 
        checkboxGroupInput(
          "countries",
          "Choose which countries to display:",
          choices = c("Egypt", "Nigeria", "Hungary", "Romania", "Poland"),
          selected = c("Egypt", "Nigeria", "Hungary", "Romania", "Poland"),
          inline = T
        ),
        plotlyOutput("allCountriesPlot", height = "500px"),
        downloadButton("downloadAllCountriesPlot", "Download Compare Countries Plot")
      ),
      tabPanel("FCI plot",
               prettyCheckbox("imf", "Show IMF FCI"),
               plotOutput("fciPlot"),
               downloadButton("downloadFciPlot", "Download FCI Plot"), 
               verbatimTextOutput("weightsInfo"),
               downloadButton("downloadWeights", "Download Weights")
      )
      
    )
  ),
  skin = 'blue'
  
)

server <- function(input, output, session) {
  read_fci_weights_text <- function(file_path) {
    readLines(file_path, warn = FALSE) %>% paste(collapse = "\n")
  }
  
  egypt_weights_text <- read_fci_weights_text("data/egypt_weights.txt")
  poland_weights_text <- read_fci_weights_text("data/poland_weights.txt")
  hungary_weights_text <- read_fci_weights_text("data/hungary_weights.txt")
  romania_weights_text <- read_fci_weights_text("data/romania_weights.txt")
  # nigeria_weights_text_1 <- read_fci_weights_text("data/nigeria_weights_1.txt")
  
  selected_data <- reactive({
    combined_data %>%
      filter(
        country == input$country,
        date >= input$dateRange[1],
        date <= input$dateRange[2],
        !is.na(!!sym(input$var))
      ) %>%
      select(date, !!sym(input$var))  
  })
  
  observeEvent(input$country, {
    if(input$country == "") {
      showModal(modalDialog(
        title = "Input Required",
        "Please select a country."
      ))
    }
  })
  
  
  observeEvent(input$dateRange, {
    if(is.null(input$dateRange)) {
      showModal(modalDialog(
        title = "Input Required",
        "Please select a date range."
      ))
    } else if(input$dateRange[1] > input$dateRange[2]) {
      showModal(modalDialog(
        title = "Invalid Date Range",
        "Start date must be before end date."
      ))
    }
  })
  
  observeEvent(input$imf, {
    if (input$imf && !(input$country %in% c("Hungary", "Poland"))) {
      showModal(modalDialog(
        title = "Data Unavailable",
        "No IMF data available for the selected country.",
        easyClose = TRUE,
        footer = modalButton("Close")
      ))
    }
  })
  
  var_name <- reactive({
    str_to_title(str_replace_all(as.character(input$var), "_", " "))
  })
  
  
  output$explorePlot <- renderPlotly({
    req(selected_data())
    
    p <- ggplot(selected_data(), aes(x = date, y = !!sym(input$var))) +
      geom_line() +
      labs(
        title = paste(var_name(), "in", input$country, "over time"),
        x = "Date",
        y = var_name()
      ) +
      theme_minimal()
    
    if(input$smooth) {
      p <- p + geom_smooth(se = FALSE)
    }
    
    ggplotly(p)
  })
  output$summaryTable <- renderDT({
    req(selected_data())
    summary_df <- selected_data() %>% 
      summarise(
        Mean = mean(!!sym(input$var), na.rm = TRUE),
        Median = median(!!sym(input$var), na.rm = TRUE),
        SD = sd(!!sym(input$var), na.rm = TRUE),
        Min = min(!!sym(input$var), na.rm = TRUE),
        Max = max(!!sym(input$var), na.rm = TRUE)
      )
    datatable(summary_df, options = list(pageLength = 5, scrollX = TRUE))
  })
  
  output$summaryPlot <- renderPlot({
    req(selected_data())
    ggplot(
      selected_data(), 
      aes(x = !!sym(input$var))
    ) +
      geom_boxplot() +
      labs(
        title = paste("Distribution of", input$var, "in", input$country),
        y = NULL,
        x = var_name(),
      ) +
      theme_minimal()
  })
  
  output$selectedTable <- renderDT({
    req(selected_data())
    datatable(selected_data(), options = list(pageLength = 5, scrollX = TRUE))
  })
  
  output$downloadData <- downloadHandler(
    filename = function() {
      paste(input$country, "selected_data.csv", sep = "_")
    },
    content = function(file) {
      write.csv(selected_data(), file, row.names = FALSE)
    }
  )
  
  output$downloadPlot <- downloadHandler(
    filename = function() {
      paste(input$country, "plot.png", sep = "_")
    },
    content = function(file) {
      p <- ggplot(selected_data(), aes(x = date, y = !!sym(input$var))) +
        geom_line() +
        labs(
          title = paste("Time Series Plot for", input$country, "-", var_name()),
          x = "Date",
          y = var_name()
        ) +
        theme_minimal()
      if(input$smooth) {
        p <- p + geom_smooth(se = FALSE)
      }
      ggsave(file, plot = p, device = "png", width = 10, height = 6)
    }
  )
  
  complete_data <- reactive({
    combined_data %>%
      filter(country == input$country)
  })
  
  observeEvent(input$showData, {
    showModal(modalDialog(
      title = paste("Complete Data for", input$country),
      DTOutput("completeDataTable"),
      downloadButton("downloadCompleteData", "Download Complete Data")
    ))
  })
  
  output$completeDataTable <- renderDT({
    req(complete_data())
    datatable(complete_data(), options = list(pageLength = 5, scrollX = TRUE, autoWidth = TRUE))
  })
  
  output$downloadCompleteData <- downloadHandler(
    filename = function() {
      paste(input$country, "complete_data.csv", sep = "_")
    },
    content = function(file) {
      write.csv(complete_data(), file, row.names = FALSE)
    }
  )
  
  output$allCountriesPlot <- renderPlotly({
    req(selected_data())
    
    p <- ggplot(
      combined_data %>% filter(country %in% input$countries), 
      aes(x = date, y = !!sym(input$var), color = country)
    ) +
      geom_line() +
      scale_color_okabeito() +
      labs(
        title = paste(var_name(), "over time")
      ) +
      theme_minimal()
    
    if(input$smooth) {
      p <- p + geom_smooth(se = FALSE)
    }
    
    ggplotly(p)
  })
  
  output$downloadAllCountriesPlot <- downloadHandler(
    filename = function() {
      paste("compare_countries_plot.png", sep = "_")
    },
    content = function(file) {
      p <- ggplot(
        combined_data %>% filter(country %in% input$countries), 
        aes(x = date, y = !!sym(input$var), color = country)
      ) +
        geom_line() +
        labs(
          title = paste(var_name(), "over time"),
          x = "Date",
          y = var_name()
        ) +
        theme_minimal()
      
      if(input$smooth) {
        p <- p + geom_smooth(se = FALSE)
      }
      
      ggsave(file, plot = p, device = "png", width = 10, height = 6)
    }
  )
  
  
  output$fciPlot <- renderPlot({
    req(input$country)
    p <- ggplot(
      combined_fci %>% filter(country == input$country),
      aes(x = date, y = fci, color = "Custom")
    ) +
      geom_line() +
      scale_color_manual(
        name='FCI',
        breaks=c('Custom', 'IMF'),
        values=c('Custom'='black', 'IMF'='red')
      ) +
      labs(
        title = paste("Custom FCI over time for", input$country),
        x = "Date",
        y = "FCI"
      ) +
      theme_minimal()
    
    if(input$smooth) {
      p <- p + geom_smooth(se = FALSE)
    }
    
    if(input$imf){
      p <- p + geom_line(aes(y = imf_fci, color = "IMF")) 
    }
    
    p
  })
  
  output$weightsInfo <- renderText({
    req(input$country)
    weights_text <- switch(input$country,
                           "Egypt" = egypt_weights_text,
                           "Poland" = poland_weights_text,
                           "Hungary" = hungary_weights_text,
                           "Romania" = romania_weights_text,
                           "Nigeria" = nigeria_weights_text,
                           "Weights info not available")
    weights_text
  })
  
  output$downloadFciPlot <- downloadHandler(
    filename = function() {
      paste(input$country, "fci_plot.png", sep = "_")
    },
    content = function(file) {
      p <- ggplot(
        combined_fci %>% filter(country == input$country),
        aes(x = date, y = fci, color = "Custom")
      ) +
        geom_line() +
        geom_line(aes(y = imf_fci, color = "IMF")) +
        scale_color_manual(name='FCI',
                           breaks=c('Custom', 'IMF'),
                           values=c('Custom'='black', 'IMF'='red')) +
        labs(
          title = paste("Custom FCI over time for", input$country),
          x = "Date",
          y = "FCI"
        ) +
        theme_minimal()
      
      if(input$smooth) {
        p <- p + geom_smooth(se = FALSE)
      }
      
      ggsave(file, plot = p, device = "png", width = 10, height = 6)
    }
  )
  
  output$downloadWeights <- downloadHandler(
    filename = function() {
      paste(input$country, "weights.txt", sep = "_")
    },
    content = function(file) {
      req(input$country)
      weights_text <- switch(input$country,
                             "Egypt" = egypt_weights_text,
                             "Poland" = poland_weights_text,
                             "Hungary" = hungary_weights_text,
                             "Romania" = romania_weights_text,
                             "Nigeria" = nigeria_weights_text,
                             stop("Weights info not available"))
      writeLines(weights_text, file)
    }
  )
  
}

shinyApp(ui = ui, server = server)