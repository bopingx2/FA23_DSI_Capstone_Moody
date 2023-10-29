#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)

egypt_data <- read_csv('../data/egypt_data.csv')


# Define UI for application that draws a histogram
fluidPage(

    # Application title
    titlePanel("Explore Egypt financial data"),

    # Sidebar with a slider input for number of bins
    sidebarLayout(
        sidebarPanel(
          varSelectInput("var",
                        "Choose variable",
                        egypt_data %>% select(-date)
                        )
        ),

        # Show a plot of the generated distribution
        mainPanel(
            plotOutput("exploreEgypt")
        )
    )
)
