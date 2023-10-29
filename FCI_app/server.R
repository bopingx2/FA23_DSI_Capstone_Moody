#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)

egypt_data <- read_csv('../data/egypt_data.csv')

# Define server logic required to draw a histogram
function(input, output, session) {

    output$exploreEgypt <- renderPlot({

      egypt_data %>%
        filter(!is.na(!!input$var)) %>%
        ggplot(aes(x = date, y = !!input$var)) +
        geom_line() +
        theme_minimal()

    })

}
