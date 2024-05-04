# Script Settings and Resources
setwd(dirname(rstudioapi::getActiveDocumentContext()$path)) #set working directory
library(tidyverse) #use tidyverse for readr, dplyr
library(tidytext) #needed for NLP/text mining functions

# Data Import and Cleaning
tas_data <- read_csv (file = '../data/tas_data.csv') #use tidyverse to get tbl to work better with dplyr later
stop_words <- get_stopwords() #get list of tidytext stop_words
sentiment <- get_sentiments("nrc") %>% #get list of nrc sentiments
  group_by(word) %>% #want to look at the words with more than one sentiment because otherwise it creates a "many to many" situation when joining
  slice(1) %>%  #take only the first sentiment for each word - there is probably a better way to do this where you choose the most common sentiment but for the purposes of this assignment it was simplest to just choose the first
  ungroup() #get rid of grouping
  
#create data version tokenzied by word
clean_tas_data <- tas_data %>%  #rename after pre-processing/cleaning
  unnest_tokens(word, Response) %>% #tokenize the items from the Response column and call that column word; removes punctuation and makes lowercase too
  mutate(num_ltrs = nchar(word)) %>% #add a column that shows the total number of characters in each word
  left_join(stop_words, by = "word") %>% #keep all columns from both but just values from the original dataset - want to be able to indicate which words are stop words so I can filter for them later rather than creating a separate tbl with stop words removed
  mutate(stop = if_else(is.na(lexicon), "N", if_else(lexicon == "snowball", "Y", "Other"))) %>% #add a column called stop that tracks whether the word in the word column is a stop word or not - if the column "lexicon" had a value "snowball"  (meaning it came from the stop word list) add a "Y" to this column so we can filter for it later, if not it prints "N". There are some things in my app that I want to look at the raw words used so I don't always want to get rid of stop words, just want to set it up for an option to filter it.
  left_join(sentiment, by = "word") %>%  #join with sentiment dictionary to assign sentiments to words
  select(Username, Condition, Grade, Gender, ML, Sentence, word, num_ltrs, stop, sentiment) #only select desired columns so that it takes shiny less time to run

#create a summary of total words per sentence to add to dataset
sentence_level <- clean_tas_data %>% #create intermediate new dataset
  select(Username,Sentence,word) %>% #only want these three columns for when I join it later
  group_by(Username, Sentence) %>% #only calculate within these groupings
  summarize(
    words_per_sentence = n() # average number of words per sentence by counting rows (words) within the groupings of Username and Sentence
  )

#add words per sentence onto data
clean_tas_data <- clean_tas_data %>%  #replace original dataset with this new version
  left_join(sentence_level, by = c("Username", "Sentence")) #adds wps amount to current dataset - I need this for calculating descriptives in my app

 
# Data Export
write_csv(clean_tas_data, "../out/clean_tas_data.csv") #save into out folder since it's a cleaned file

