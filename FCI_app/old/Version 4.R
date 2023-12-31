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

egypt_data <- read_csv(paste0(wd, '/../FCI_app/data/Egypt_DataFrame.csv')) %>%
  clean_names() %>%
  mutate(
    country = 'Egypt'
  )
hungary_data <- read_csv(paste0(wd, '/../FCI_app/data/Hungary_DataFrame.csv')) %>% 
  clean_names() %>%
  mutate(
    country = 'Hungary'
  )
nigeria_data <- read_csv(paste0(wd, '/../FCI_app/data/Nigeria_DataFrame.csv')) %>% 
  clean_names() %>%
  mutate(
    country = 'Nigeria'
  )
poland_data <- read_csv(paste0(wd, '/../FCI_app/data/Poland_DataFrame.csv')) %>% 
  clean_names() %>%
  mutate(
    country = 'Poland'
  )
romania_data <- read_csv(paste0(wd, '/../FCI_app/data/Romania_DataFrame.csv')) %>% 
  clean_names() %>%
  mutate(
    country = 'Romania'
  )

hungary_fci <- read_csv(paste0(wd, "/../FCI_app/data/hungary_fci.csv")) %>%
  mutate(country = 'Hungary')
poland_fci <- read_csv(paste0(wd, "/../FCI_app/data/poland_fci.csv")) %>%
  mutate(country = 'Poland')

combined_data <- bind_rows(egypt_data, hungary_data, nigeria_data, poland_data, 
                           romania_data)

combined_fci <- bind_rows(hungary_fci, poland_fci)


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
        plotlyOutput("allCountriesPlot", height = "500px")
      ),
      tabPanel("FCI plot", plotOutput("fciPlot"))
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
    ggplot(selected_data(), aes(x = "", y = !!sym(input$var))) +
      geom_boxplot() +
      labs(title = paste("Distribution of", input$var, "in", input$country),
           y = var_name())
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
  
  output$fciPlot <- renderPlot({
    ggplot(
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
  })
  
}

shinyApp(ui = ui, server = server)