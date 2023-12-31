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
wd = getwd()

egypt_data <- read_csv(paste0(wd, '/../data/Egypt_DataFrame.csv')) %>%
  clean_names() %>%
  mutate(
    country = 'Egypt'
  )
hungary_data <- read_csv(paste0(wd, '/../data/Hungary_DataFrame.csv')) %>% 
  clean_names() %>%
  mutate(
    country = 'Hungary'
  )
nigeria_data <- read_csv(paste0(wd, '/../data/Nigeria_DataFrame.csv')) %>% 
  clean_names() %>%
  mutate(
    country = 'Nigeria'
  )
poland_data <- read_csv(paste0(wd, '/../data/Poland_DataFrame.csv')) %>% 
  clean_names() %>%
  mutate(
    country = 'Poland'
  )
romania_data <- read_csv(paste0(wd, '/../data/Romania_DataFrame.csv')) %>% 
  clean_names() %>%
  mutate(
    country = 'Romania'
  )
combined_data <- bind_rows(egypt_data, hungary_data, nigeria_data, poland_data, 
                           romania_data)


ui <- dashboardPage(
  dashboardHeader(title = "Financial Data Explorer"),
  dashboardSidebar(
    selectInput("country", "Select Country", choices = unique(combined_data$country)),
    varSelectInput("var", "Choose variable", combined_data %>% select(-date, -country)),
    dateRangeInput("dateRange", "Select Date Range", start = min(combined_data$date), end = max(combined_data$date)),
    prettyCheckbox("smooth", "Apply smooth line"),
    downloadButton("downloadData", "Download Selected Data"),
    downloadButton("downloadPlot", "Download Plot"),
    actionButton("showData", "Show Complete Data")
  ),
  dashboardBody(
    tabsetPanel(
      tabPanel("Plot", plotlyOutput("explorePlot", height = "500px")),
      tabPanel("Selected Data", DTOutput("selectedTable")),
      tabPanel(
        "Compare Countries", 
        checkboxGroupInput(
          "countries",
          "Choose which countries to display:",
          choices = c("Egypt", "Nigeria", "Hungary", "Romania", "Poland"),
          selected = c("Egypt", "Nigeria", "Hungary", "Romania", "Poland"),
          inline = T
        ),
        plotlyOutput("allCountriesPlot", height = "500px")
        )
    )
  )
)

server <- function(input, output, session) {
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
      labs(
        title = paste(var_name(), "over time")
        ) +
      theme_minimal()
    
    if(input$smooth) {
      p <- p + geom_smooth(se = FALSE)
    }
    
    ggplotly(p)
  })
  
}

shinyApp(ui = ui, server = server)