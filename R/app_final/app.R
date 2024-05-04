# Script Settings and Resources
library(shiny) #need to run this app
library(readr) #need in order to read file
library(dplyr) #need for running some analyses in app
library(ggplot2) #need for visualizations in app

# Data Import and Cleaning
# import data
clean_tas_data <- read_csv (file = "clean_tas_data.csv") #import skinny file that was created in original R script

# Define UI 
ui <- fluidPage( #I believe this makes it so that it adjusts based on the size of the screen viewing your app
  
  # app title
  titlePanel("Student Think-Aloud Analysis"), 
  
  # sidebar with radio buttons for all options to filter
  sidebarLayout(
    sidebarPanel(  #wanted to the buttons to be in a sidebar so they're not the focus but are still obvious
      
      #create set of radio buttons for selecting condition - individual line comments are the same for each set of radio buttons
      radioButtons("conditionselect", #reference to use when filtering for this set of buttons
                   label="Which condition would you like to see?", #displayed question for user
                   choices=c("Consecutive","Iterative","All"), #options to choose between
                   selected="All"), #default option
      
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
               
               #create panel for descriptives - individual line comments are the same for all panels
               tabPanel("Descriptives",    #name of panel
                        h3("Descriptive Statistics"), #heading that will display
                        tableOutput("descTable"), #output that will be displayed - is defined later in the server logic area
                        plotOutput("descPlotWords"),
                        plotOutput("descPlotLetters")),
               
               #create panel for frequencies
               tabPanel("Frequencies", 
                        h3("Frequency Analysis"), 
                        plotOutput("freqPlot")),
               
               #create panel for sentiments
               tabPanel("Sentiment", 
                        h3("Sentiment Analysis"), 
                        plotOutput("sentPlot"))
             )
      )
    )
  )
)


# Define server logic
server <- function(input, output) {
  
  # define data based on filters for later use
  filtered_data <- reactive({ #create a reactive function called filtered data where it depends on what radio buttons were selected
    data <- clean_tas_data #use clean data file but just refer to it as data in later functions for simplicity
    
    #filter for condition
    if (input$conditionselect != "All") {  #if anything is selected other than "All"...
      data <- data %>% 
        filter(Condition == input$conditionselect)  #filter the data based on the values in the "condition" column
    }
    
    #filter for gender
    if (input$genderselect != "All") { #if anything is selected other than "All"...
      gender_map <- c("Male" = "M", "Female" = "F")  #values in column didn't match values users are choosing between so needed to connect "Male" to "M" in the dataset and same for female
      data <- data %>% 
        filter(Gender %in% gender_map[input$genderselect]) #filter the data based on the values in the "gender" column
    }
    
    #filter for grade
    if (input$gradeselect != "All") { #if anything is selected other than "All"...
      data <- data %>% 
        filter(Grade == input$gradeselect) #filter the data based on the values in the "grade" column
    }
    
    #filter for multilingual learner status
    if (input$mlselect == "Only show MLs") { #if "Only show MLs" is selected...
      data <- data %>% 
        filter(ML == "Y") #filter so only those with Y tag for MLs are shown
    } else if (input$mlselect == "Show all students except MLs") { #if "Show all students except MLs" is selected...
      data <- data %>% 
        filter(ML == "N") #filter so only those with N tag for MLs are shown
    }
    
    data #output the filtered results
  })
  
  #create output for the "Descriptives" panel
  output$descTable <- renderTable({ #defines descTable output that is placed in the "Descriptives" panel in UI

    # Compute the descriptive statistics 
    descriptives <- filtered_data() %>%  #create name for new dataset that will be used in table output
      group_by(Sentence) %>% #compare each of the sentences from the texts to each other
      summarize(
        "Average Words Per Sentence" = mean(words_per_sentence), # average number of words per sentence
        "SD Words Per Sentence" = sd(words_per_sentence),# SD of words per sentence
        "Average Length of Word" = mean(num_ltrs), #average length of words
        "SD Length of Word" = sd(num_ltrs) #sd length of words
      )
    
    # Return the table with descriptives
    descriptives #returns descriptives table as an output
  })
  
  #create plot for the "Descriptives" panel - words per sentence
  output$descPlotWords <- renderPlot({   #defines descPlotWords output that is placed in the "Descriptives" panel in UI
 
    #repeated code from above to define descriptives - since it was defined inside of a reactive funciton it doesn't save the object. I tried using <<- but had problems when trying to deploy the Shiny app so I'm just repeating it even though that's not best practice for code.
    descriptives <- filtered_data() %>%  #create name for new dataset that will be used in table output
      group_by(Sentence) %>% #compare each of the sentences from the texts to each other
      summarize(
        "Average Words Per Sentence" = mean(words_per_sentence), # average number of words per sentence
        "SD Words Per Sentence" = sd(words_per_sentence),# SD of words per sentence
        "Average Length of Word" = mean(num_ltrs), #average length of words
        "SD Length of Word" = sd(num_ltrs) #sd length of words
      )
    
    #create bar plot
    ggplot(descriptives, aes(x = Sentence, y = `Average Words Per Sentence`)) + #show sentence number on x axis and average number of words on y
      geom_bar(stat = "identity", fill = "green") + #display bars in green
      geom_errorbar(  #add error bars
        aes(
          ymin = pmax(`Average Words Per Sentence` - `SD Words Per Sentence`,0), #add error bars with the lower end found by subtracting sd from mean. However some SD as quite large so I didn't want it to go below zero.
          ymax = `Average Words Per Sentence` + `SD Words Per Sentence` #add error bars with the higher end found by adding sd to mean
        ),
        width = 0.2  # set width of error bars
      ) +
      labs(x = "Sentence", y = "Average Number of Words", title = "Average Number of Words Per Sentence") + #add titles to axes and overall
      theme_minimal()  #gets rid of grayish background on plot that I don't love
  })
  
  #create plot for the "Descriptives" panel - letters per word
  output$descPlotLetters <- renderPlot({   #defines descPlotLetters output that is placed in the "Descriptives" panel in UI
  
    #repeated code from above to define descriptives - since it was defined inside of a reactive funciton it doesn't save the object. I tried using <<- but had problems when trying to deploy the Shiny app so I'm just repeating it even though that's not best practice for code.
    descriptives <- filtered_data() %>%  #create name for new dataset that will be used in table output
      group_by(Sentence) %>% #compare each of the sentences from the texts to each other
      summarize(
        "Average Words Per Sentence" = mean(words_per_sentence), # average number of words per sentence
        "SD Words Per Sentence" = sd(words_per_sentence),# SD of words per sentence
        "Average Length of Word" = mean(num_ltrs), #average length of words
        "SD Length of Word" = sd(num_ltrs) #sd length of words
      )
    
    #create bar plot
    ggplot(descriptives, aes(x = Sentence, y = `Average Length of Word`)) + #show sentence number on x axis and average number of words on y
      geom_bar(stat = "identity", fill = "purple") + #display bars in purple
      geom_errorbar(  #add error bars
        aes(
          ymin = `Average Length of Word` - `SD Length of Word`, #add error bars with the lower end found by subtracting sd from mean
          ymax = `Average Length of Word` + `SD Length of Word` #add error bars with the higher end found by adding sd to mean
        ),
        width = 0.2  # set width of error bars
      ) +
      labs(x = "Sentence", y = "Average Length of Word", title = "Average Number of Letters per Word") + #add titles to axes and overall
      theme_minimal()  #gets rid of grayish background on plot that I don't love
  })
  
  #create output for the "Frequencies" panel
  output$freqPlot <- renderPlot({   #defines freqPlot output that is placed in the "Frequencies" panel in UI
    # Use the filtered data to count word occurrences
    word_data <- filtered_data() %>%
      filter(stop == "N") %>%  # only include non-stop words
      count(word = word, sort = TRUE) %>% #sort by highest frequency
      top_n(20, n) # select top 20 most frequent words
    
    #create bar plot
    ggplot(word_data, aes(x = reorder(word, n), y = n)) + #display in descending order of words
      geom_bar(stat = "identity", fill = "red") + #display bars in red
      labs(x = "Word", y = "Frequency", title = "Most Used Words (Not Including Stop Words)") + #add titles to axes and overall
      theme_minimal() + #gets rid of grayish background on plot that I don't love
      coord_flip() # flip axes to read words better
  })
  
  #create output for the "Sentiment" panel
  output$sentPlot <- renderPlot({ #defines sentPlot output that is placed in the "Sentiment" panel in UI
    # Use the filtered data to count sentiment occurrences
    sentiment_data <- filtered_data() %>%
      filter(sentiment != "N/A") %>%  # get rid of N/As
      count(sentiment = sentiment, sort = TRUE) #sort by highest frequency
    
    #create bar plot
    ggplot(sentiment_data, aes(x = reorder(sentiment, n), y = n)) + #display in descending order of sentiments
      geom_bar(stat = "identity", fill = "blue") + #display bars in blue
      labs(x = "Sentiment", y = "Frequency", title = "Most Used Sentiments from NRC Dictionary") + #add titles to axes and overall
      theme_minimal() + #gets rid of grayish background on plot that I don't love
      coord_flip() # flip axes to read words better
  })
}

# Run the application 
shinyApp(ui = ui, server = server)
