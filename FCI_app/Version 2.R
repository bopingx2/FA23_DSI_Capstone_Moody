library(shiny)
library(readr)
library(tidyverse)
library(data.table)
library(ggplot2)
library(shinyWidgets)

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
                           romania_data) %>%
  mutate(
    velocity_of_money_mo12m_percent_change = velocity_of_money_mo12m_percent_change*100,
    broad_money_mo12m_percent_change = broad_money_mo12m_percent_change*100,
    date = as.Date(paste0(date, "-01"), format = "%Y-%m-%d")
  )


library(shinythemes)

ui <- fluidPage(
  theme = shinytheme("flatly"), 
  titlePanel("Explore Financial Data by Country"),
  
  sidebarLayout(
    sidebarPanel(
      selectInput("country", "Select Country", 
                  choices = unique(combined_data$country)),
      varSelectInput("var", "Choose variable", combined_data %>% 
                       select(-date, -country)),
      dateRangeInput("dateRange", "Select Date Range", 
                     start = min(combined_data$date), 
                     end = max(combined_data$date)),
      prettyCheckbox("smooth", "Apply smooth line")
    ),
    
    mainPanel(
      plotOutput("explorePlot")
    )
  )
)

server <- function(input, output, session) {
  filtered_data <- reactive({
    combined_data %>% 
      filter(
        country == input$country, 
        date >= input$dateRange[1],
        date <= input$dateRange[2], 
        !is.na(!!input$var)
        ) 
  })
  
  output$explorePlot <- renderPlot({
    p = ggplot(
      filtered_data(), 
      aes(x = date, y = !!input$var)
      ) +
      geom_line() +
      theme_bw() +
      labs(
        title = paste("Time Series Plot for", input$country)
        )
    
    if(input$smooth) p = p + geom_smooth(se = F)
    
    p
  })
}

shinyApp(ui = ui, server = server)
