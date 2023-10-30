library(shiny)
library(readr)
library(tidyverse)
library(data.table)
library(ggplot2)

egypt_data <- fread('/Users/yuanmingkang/Downloads/egypt_data.csv') %>% mutate(country = 'Egypt')
hungary_data <- fread('/Users/yuanmingkang/Downloads/egypt_data.csv') %>% mutate(country = 'Hungary')

combined_data <- bind_rows(egypt_data, hungary_data)


library(shinythemes)

ui <- fluidPage(
  theme = shinytheme("slate"), 
  titlePanel("Explore Financial Data by Country"),
  
  sidebarLayout(
    sidebarPanel(
      selectInput("country", "Select Country", choices = unique(combined_data$country)),
      varSelectInput("var", "Choose variable", combined_data %>% select(-date, -country)),
      dateRangeInput("dateRange", "Select Date Range", start = min(combined_data$date), end = max(combined_data$date))
    ),
    
    mainPanel(
      plotOutput("explorePlot")
    )
  )
)

server <- function(input, output, session) {
  filtered_data <- reactive({
    combined_data %>% 
      filter(country == input$country, date >= input$dateRange[1], date <= input$dateRange[2], !is.na(!!input$var)) 
  })
  
  output$explorePlot <- renderPlot({
    ggplot(filtered_data(), aes(x = date, y = !!input$var)) +
      geom_line() +
      theme_minimal() +
      labs(title = paste("Time Series Plot for", input$country))
  })
}

shinyApp(ui = ui, server = server)
