library(shiny)
library(readr)
library(tidyverse)

# Load and combine data
egypt_data <- read_csv('/Users/yuanmingkang/Downloads/egypt_data.csv') %>% mutate(country = 'Egypt')
hungary_data <- read_csv('/Users/yuanmingkang/Downloads/egypt_data.csv') %>% mutate(country = 'Hungary')


combined_data <- bind_rows(egypt_data, hungary_data)


ui <- fluidPage(
  titlePanel("Explore Financial Data by Country"),
  
  sidebarLayout(
    sidebarPanel(
      selectInput("country", "Select Country", choices = unique(combined_data$country)),
      varSelectInput("var", "Choose variable", combined_data %>% select(-date, -country))
    ),
    
    mainPanel(
      plotOutput("explorePlot")
    )
  )
)


server <- function(input, output, session) {
  
  output$explorePlot <- renderPlot({
    filtered_data <- combined_data %>% 
      filter(country == input$country, !is.na(!!input$var)) 
    
    ggplot(filtered_data, aes(x = date, y = !!input$var)) +
      geom_line() +
      theme_minimal() +
      labs(title = paste("Time Series Plot for", input$country))
  })
}


shinyApp(ui = ui, server = server)
