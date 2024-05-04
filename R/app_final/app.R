# Script Settings and Resources
setwd(dirname(rstudioapi::getActiveDocumentContext()$path)) #set working directory
library(shiny) #need to run this app
library(dplyr) #need for running some analyses in app
library(ggplot2) #need for visualizations in app

# Data Import and Cleaning
# import data
clean_tas_data <- read_csv (file = '../../out/clean_tas_data.csv') #import skinny file that was created in original R script

# Define UI 
ui <- fluidPage(

    # app title
    titlePanel("Student Think-Aloud Analysis"),

    # sidebar with radio buttons for all options to filter
    sidebarLayout(
        sidebarPanel(
          
          #create set of radio buttons for selecting condition
          radioButtons("conditionselect",
                       label="Which condition would you like to see?",
                       choices=c("Consecutive","Iterative","All"),
                       selected="All"),
          
          #create set of radio buttons for selecting gender
          radioButtons("genderselect",
                       label="Which gender would you like to see?",
                       choices=c("Male","Female","All"),
                       selected="All"),
          
          #create set of radio buttons for selecting grade
          radioButtons("gradeselect",
                       label="Which grade would you like to see?",
                       choices=c("4","5","All"),
                       selected="All"),
          
          #create set of radio buttons for selecting ML status
          radioButtons("mlselect",
                       label="Would you like to filter results for multilingual learners (MLs)?",
                       choices=c("Only show MLs","Show all students except MLs","Show all students"),
                       selected="Show all students"),
        ),
        
        # main panel for displaying analyses - different tabs based on the different analyses
        mainPanel(   #display analyses in main panel
          column(12, #make it the full width of the main panel (not sure if this is necessary)
                 tabsetPanel(   #set up the main panel so that users can click between different panels
                   
                   #create panel for descriptives
                   tabPanel("Descriptives", 
                            h3("Descriptive Statistics"), 
                            tableOutput("descTable")),
                   
                   #create panel for frequencies
                   tabPanel("Frequencies", 
                            h3("Frequency Analysis"), 
                            plotOutput("freqPlot")),
                   
                   #create panel for sentiments
                   tabPanel("Sentiment", 
                            h3("Sentiment Analysis"), 
                            plotOutput("sentPlot")),
                   
                   #create panel for correlations
                   tabPanel("Correlations", 
                            h3("Correlation Analysis"), 
                            plotOutput("corrPlot"))
                 )
          )
        )
    )
)


# Define server logic
server <- function(input, output) {
 
  # define data based on filters for later use
  filtered_data <- reactive({ #create a reactive function called filtered data where it depends on what radio buttons were selected
    data <- clean_tas_data
    
    #filter for condition
    if (input$conditionselect != "All") {
      data <- data %>% 
        filter(Condition == input$conditionselect)
    }
    
    #filter for gender
    if (input$genderselect != "All") {
      gender_map <- c("Male" = "M", "Female" = "F")
      data <- data %>% 
        filter(Gender %in% gender_map[input$genderselect])
    }
    
    #filter for grade
    if (input$gradeselect != "All") {
      data <- data %>% 
        filter(Grade == input$gradeselect)
    }
    
    #filter for multilingual learner status
    if (input$mlselect == "Only show MLs") {
      data <- data %>% 
        filter(ML == "Y")
    } else if (input$mlselect == "Show all students except MLs") {
      data <- data %>% 
        filter(ML == "N")
    }
    
    data #output the filtered results
  })
  
  #create output for the "Frequencies" panel
  output$freqPlot <- renderPlot({
    # Use the filtered data to count word occurrences
    word_data <- filtered_data() %>%
      filter(stop == "N") %>%  # only include non-stop words
      count(word = word, sort = TRUE) %>%
      top_n(20, n) # select top 20 most frequent words

    # create bar plot
    ggplot(word_data, aes(x = reorder(word, n), y = n)) + #display in descending order of words
      geom_bar(stat = "identity", fill = "blue") + #display bars in blue
      labs(x = "Word", y = "Frequency", title = "Most Used Words") +
      theme_minimal() + #gets rid of grayish backgroun on plot that I don't love
      coord_flip() # flip axes to read words better
  })
  
  #create output for the "Sentiment" panel
  output$sentPlot <- renderPlot({
    # Use the filtered data to count sentiment occurrences
    sentiment_data <- filtered_data() %>%
      filter(sentiment != "N/A") %>%  # get rid of N/As
      count(sentiment = sentiment, sort = TRUE) %>% 
      top_n(20, n) # Select top 20 sentiments based on frequency
    
    # create bar plot
    ggplot(sentiment_data, aes(x = reorder(sentiment, n), y = n)) + #display in descending order of sentiments
      geom_bar(stat = "identity", fill = "blue") + #display bars in blue
      labs(x = "Sentiment", y = "Frequency", title = "Most Used Words") +
      theme_minimal() + #gets rid of grayish backgroun on plot that I don't love
      coord_flip() # flip axes to read words better
  })
}

# Run the application 
shinyApp(ui = ui, server = server)
