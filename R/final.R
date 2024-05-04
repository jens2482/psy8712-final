# Script Settings and Resources
setwd(dirname(rstudioapi::getActiveDocumentContext()$path)) #set working directory
library(tidyverse) #use tidyverse for readr, dplyr
library(tidytext) #needed for NLP/text mining functions

# Data Import and Cleaning
tas_data <- read_csv (file = '../data/tas_data.csv') #use tidyverse to get tbl to work better with dplyr later
stop_words <- get_stopwords() #get list of tidytext stop_words

#create data version tokenzied by word
clean_tas_data <- tas_data %>%
  unnest_tokens(word, Response) %>% #tokenize the items from the Response column and call that column word; removes punctuation and makes lowercase too
  mutate(num_ltrs = nchar(word)) %>% #add a column that shows the total number of characters in each word
  left_join(get_stopwords(), by = c("word" = "word")) %>% #keep all columns from both but just values from the original dataset - want to be able to indicate which words are stop words so I can filter for them later rather than creating a separate tbl with stop words removed
  mutate(stop = if_else(lexicon == "snowball", "Y", lexicon)) %>% #add a column called stop that tracks whether the word in the word column is a stop word or not - if the column "lexicon" had a value "snowball"  (meaning it came from the stop word list) add a "Y" to this column so we can filter for it later
  select(Username, Condition, Grade, Gender, Age, ML, WMCwp, GMRTcp, Genre, Sentence, word, num_ltrs, stop) #only select desired columns so that it takes shiny less time to run
  
# Data Export
write_csv(clean_tas_data, "../out/clean_tas_data.csv") #save into out folder since it's a cleaned file
