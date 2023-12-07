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
nigeria_fci <- read_csv("data/nigeria_fci.csv") %>%
  mutate(country = 'Nigeria')

combined_data <- bind_rows(egypt_data, hungary_data, nigeria_data, poland_data, 
                           romania_data)

combined_fci <- bind_rows(hungary_fci, poland_fci, romania_fci, egypt_fci, nigeria_fci)

read_fci_weights_text <- function(file_path) {
  readLines(file_path, warn = FALSE) %>% paste(collapse = "\n")
}

egypt_weights_text <- read_fci_weights_text("data/egypt_weights.txt")
poland_weights_text <- read_fci_weights_text("data/poland_weights.txt")
hungary_weights_text <- read_fci_weights_text("data/hungary_weights.txt")
romania_weights_text <- read_fci_weights_text("data/romania_weights.txt")
nigeria_weights_text <- read_fci_weights_text("data/nigeria_weights.txt")

all_data <- full_join(combined_data, combined_fci, by= c("date", "country"))


ui <- fluidPage(
  navbarPage("Financial Data Explorer", theme = shinytheme("flatly"),
    tabPanel("Custom FCI", fluid = TRUE, icon = icon("chart-line"),
             mainPanel(
                 h3("Investigate our custom FCIs over 5 different emerging markets"),
               fluidRow(
                 column(10, offset = 2,
                   checkboxGroupInput(
                   "countries", "", inline = TRUE,
                   choices = c("Egypt", "Nigeria", "Hungary", "Romania", "Poland"),
                   selected = c("Egypt", "Nigeria", "Hungary", "Romania", "Poland")
                 )
                 ),
                 plotOutput("fciPlot"),
                 br(),
                 h1("\n "),
                 br(),
                 h1("\n ")
               ),
               fluidRow(
                 h4("Compare Poland and Hungary to their corresponding IMF FCI"),
                 column(10, offset = 2,
                        radioButtons("imfCountry", "", inline = TRUE,
                              c("Poland" = "Poland",
                                "Hungary" = "Hungary"))
                        ),
                 plotOutput("fciIMF")
                 
               )
               )
             ),
  tabPanel("A closer look", fluid = TRUE, icon = icon("magnifying-glass"),
           sidebarLayout(
             sidebarPanel(
               selectInput("country", "Select Country", choices = unique(combined_data$country)),
               dateRangeInput("dateRange", "Select Date Range", start = min(combined_data$date), end = max(combined_data$date)),
               prettyCheckbox("smooth", "Apply smooth line")
               ),
             mainPanel(
               h3("Dive deeper into our custom FCI in each country"),
               plotOutput("fciIndPlot"),
               downloadButton("downloadIndFciPlot", "Download FCI Plot"),
               verbatimTextOutput("weightsInfo"),
               downloadButton("downloadWeights", "Download Weights")
             )
           )
           ),
  tabPanel("Individual variables", fluid = TRUE, icon = icon("circle-dot"),
           sidebarLayout(
             sidebarPanel(
               selectInput("countryVar", "Select Country", choices = unique(combined_data$country)),
               varSelectInput("var", "Choose variable", combined_data %>% select(-date, -country)),
               dateRangeInput("dateRangeVar", "Select Date Range", start = min(combined_data$date), end = max(combined_data$date)),
               prettyCheckbox("smoothVar", "Apply smooth line")
             ),
             mainPanel(
               h3("Explore the variables we used in our PCA analysis"),
               plotlyOutput("explorePlot", height = "500px"),
               downloadButton("downloadPlot", "Download Plot"),
               br(),
               h1("\n "),
               br(),
               h1("\n "),
               DTOutput("summaryTable"), 
               plotOutput("summaryPlot")
             )
           )
           ),
  tabPanel("Download data", fluid = TRUE, icon = icon("table"),
           sidebarLayout(
             sidebarPanel(
               selectInput("country", "Select Country", choices = unique(combined_data$country))
              ),
             mainPanel(
               h3("Download the data"),
               DTOutput("completeDataTable"),
               downloadButton("downloadCompleteData", "Download Complete Data")
             )
           ))
  )
)

server <- function(input, output, session) {
  
  selected_data <- reactive({
    combined_data %>%
      filter(
        country == input$countryVar,
        date >= input$dateRangeVar[1],
        date <= input$dateRangeVar[2],
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
  
  var_name <- reactive({
    str_to_title(str_replace_all(as.character(input$var), "_", " "))
  })
  
  
  output$explorePlot <- renderPlotly({
    req(input$country)
    
    p <- ggplot(selected_data(), aes(x = date, y = !!sym(input$var))) +
      geom_line() +
      labs(
        title = paste(var_name(), "in", input$countryVar, "over time"),
        x = "Date",
        y = var_name()
      ) +
      theme_minimal()
    
    if(input$smoothVar) {
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
        title = paste("Distribution of", input$var, "in", input$countryVar),
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
    all_data %>%
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
    req(input$countries)
    p <- ggplot(
      combined_fci %>% filter(country %in% input$countries), 
      aes(x = date, y = fci, color = country)
    ) +
      geom_line() +
      scale_color_manual(
        name='Country',
        breaks=c('Egypt', 'Nigeria', "Romania", "Hungary", "Poland"),
        values=c('Egypt' = "#E69F00", 'Nigeria' = "#009E73", "Romania" = "#D55E00", 
                 "Hungary" = "#CC79A7", "Poland" = "#0072B2")
      ) +
      labs(
        title = "Compare custom FCIs over time",
        x = "Date",
        y = "FCI",
        color = "Country"
      ) +
      theme_minimal()
    
    p
  })
    
    output$fciIndPlot <- renderPlot({
      req(input$country)
      p <- ggplot(
        combined_fci %>% 
          filter(
            country == input$country,
            date >= input$dateRange[1],
            date <= input$dateRange[2]
            ), 
        aes(x = date, y = fci)
      ) +
        geom_line() +
        labs(
          title = paste("Custom FCI over time for", input$country),
          x = "Date",
          y = "FCI"
        ) +
        theme_minimal()
      
      if(input$smooth) {
        p <- p + geom_smooth(se = FALSE)
      }
      p
    })
  
  output$fciIMF <- renderPlot({
    req(input$imfCountry)
    p <- ggplot(
      combined_fci %>% filter(country == input$imfCountry),
      aes(x = date, y = fci, color = "Custom")
    ) +
      geom_line() + 
      geom_line(aes(y = imf_fci, color = "IMF")) +
      scale_color_manual(
        name='FCI',
        breaks=c('Custom', 'IMF'),
        values=c('Custom'='black', 'IMF'='red')
      ) +
      labs(
        title = paste("Custom FCI over time for", input$imfCountry),
        x = "Date",
        y = "FCI"
      ) +
      theme_minimal()
    
    p
  })
  
  output$downloadFciPlot <- downloadHandler(
    filename = function() {
      paste(input$country, "fci_plot.png", sep = "_")
    },
    content = function(file) {
      req(input$countries)
      p <- ggplot(
        combined_fci %>% filter(country %in% input$countries), 
        aes(x = date, y = fci, color = country)
      ) +
        geom_line() +
        scale_color_manual(
          name='Country',
          breaks=c('Egypt', 'Nigeria', "Romania", "Hungary", "Poland"),
          values=c('Egypt' = "#E69F00", 'Nigeria' = "#009E73", "Romania" = "#D55E00", 
                   "Hungary" = "#CC79A7", "Poland" = "#0072B2")
        ) +
        labs(
          title = "Compare custom FCIs over time",
          x = "Date",
          y = "FCI",
          color = "Country"
        ) +
        theme_minimal()
      
      ggsave(file, plot = p, device = "png", width = 10, height = 6)
    }
  )
  
  output$downloadIndFciPlot <- downloadHandler(
    filename = function() {
      paste(input$country, "ind_fci_plot.png", sep = "_")
    },
    content = function(file) {
      req(input$country)
      p <- ggplot(
        combined_fci %>% 
          filter(
            country == input$country,
            date >= input$dateRange[1],
            date <= input$dateRange[2]
          ), 
        aes(x = date, y = fci)
      ) +
        geom_line() +
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