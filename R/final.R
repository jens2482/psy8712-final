# Script Settings and Resources
setwd(dirname(rstudioapi::getActiveDocumentContext()$path)) #set working directory
library(tidyverse) #use tidyverse for readr, dplyr
library(tidytext) #needed for NLP/text mining functions
download.file("http://saifmohammad.com/WebPages/lexicons.html", "nrc_lexicon.zip")  #had to add this in to make my code work in binder

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

#Publication
#not sure if this was meant to go in visualizations or publication...the shiny app allows for interactive visualizations based on selected filters. However, since we also need static images saved as outputs I included them in this script

#table #1 - descriptives table - related to RQ#1
table_1 <- clean_tas_data %>%  
  group_by(Sentence) %>% #compare each of the sentences from the texts to each other
  summarize(
    "Average Words Per Sentence" = mean(words_per_sentence), # average number of words per sentence
    "SD Words Per Sentence" = sd(words_per_sentence),# SD of words per sentence
    "Average Length of Word" = mean(num_ltrs), #average length of words
    "SD Length of Word" = sd(num_ltrs) #sd length of words
  )%>%
  write_csv("../out/tbl1_descriptives_table.csv") #saved to 'out' folder (even though the rest of the things below are saved to 'figs' which feels weird because they're all related to publication)

#visualization #1 - descriptives plot #1 looking at words per sentence  - related to RQ#1
fig_1 <- table_1 %>%
  ggplot( aes(x = Sentence, y = `Average Words Per Sentence`)) + #show sentence number on x axis and average number of words on y
  geom_bar(stat = "identity", fill = "green") + #display bars in green
  geom_errorbar(  #add error bars
    aes(
      ymin = pmax(`Average Words Per Sentence` - `SD Words Per Sentence`,0), #add error bars with the lower end found by subtracting sd from mean. However some SD as quite large so I didn't want it to go below zero.
      ymax = `Average Words Per Sentence` + `SD Words Per Sentence` #add error bars with the higher end found by adding sd to mean
    ),
    width = 0.2  # set width of error bars
  ) +
  labs(x = "Sentence", y = "Average Number of Words", title = "Average Number of Words Per Sentence") #add titles to axes and overall
ggsave("../figs/fig1_descriptives_words.png", fig_1, height=3, width=4, units="in", dpi=600) #save to figs using journal-worthy properties according to notes

#visualization #2 - descriptives plot #2 looking at letters per word - related to RQ#1; I know it said we were supposed to have one table and one plot for our descriptive data. However, one of my hypotheses/questions is based around my descriptive data so instead I have two plots relating to descriptive data (since I don't have a third separate hypothesis plot). Hopefully that's okay!
fig_2 <- table_1 %>%
  ggplot(aes(x = Sentence, y = `Average Length of Word`)) + #show sentence number on x axis and average number of words on y
  geom_bar(stat = "identity", fill = "purple") + #display bars in purple
  geom_errorbar(  #add error bars
    aes(
      ymin = `Average Length of Word` - `SD Length of Word`, #add error bars with the lower end found by subtracting sd from mean
      ymax = `Average Length of Word` + `SD Length of Word` #add error bars with the higher end found by adding sd to mean
    ),
    width = 0.2  # set width of error bars
  ) +
  labs(x = "Sentence", y = "Average Length of Word", title = "Average Number of Letters per Word") #add titles to axes and overall
ggsave("../figs/fig2_descriptives_letters.png", fig_2, height=3, width=4, units="in", dpi=600) #save to figs using journal-worthy properties according to notes

#visualization #3 - frequencies plot - related to RQ#2
fig_3 <- clean_tas_data %>%
  filter(stop == "N") %>%  # only include non-stop words
  count(word = word, sort = TRUE) %>% #sort by highest frequency
  top_n(20, n) %>% # select top 20 most frequent words
  ggplot(aes(x = reorder(word, n), y = n)) + #display in descending order of words
  geom_bar(stat = "identity", fill = "red") + #display bars in red
  labs(x = "Word", y = "Frequency", title = "Most Used Words") + #add titles to axes and overall
  coord_flip() # flip axes to read words better
ggsave("../figs/fig3_frequency.png", fig_3, height=3, width=4, units="in", dpi=600) #save to figs using journal-worthy properties according to notes

#visualization #4 - sentiment plot - related to RQ#3
fig_4 <- clean_tas_data %>%
  filter(sentiment != "N/A") %>% # get rid of N/As
  count(sentiment = sentiment, sort = TRUE) %>%
  ggplot(aes(x = reorder(sentiment, n), y = n)) + #display in descending order of sentiments
  geom_bar(stat = "identity", fill = "blue") + #display bars in blue
  labs(x = "Sentiment", y = "Frequency", title = "Most Used Sentiments from NRC") + #add titles to axes and overall
  coord_flip() # flip axes to read words better
ggsave("../figs/fig4_sentiment.png", fig_4, height=3, width=4, units="in", dpi=600) #save to figs using journal-worthy properties according to notes

#rq/hypothesis #1 analysis - this part is a little weird for me. My analyses are more qualitative, which up until this point in the project seemed okay. You said to make sure it was "psyche-y" and I feel like qualitative analyses would still fall under that category...I did my best to do some formal stats to determine the answers to RQ1/H1. I also think we may use hypotheses and research questions different that ya'll...we typically have a research question with a supporting hypothesis so I'm not understanding the distinction you make here where Hs need a formal test and RQs don't. Does that mean I don't need any? Of course I'm wrapping this up too late to email you. I ran an anova for both parts of my RQ1/H1 so there are two outputs that I copy/pasted from R. For my other two, I'm going to guess those are just research questions and not hypotheses since they are more open ended so I'll provide some general observations in the document but won't perform a formal test for those. Hopefully that's okay!

#number of words per sentence
anova_result_words <- aov(words_per_sentence ~ Sentence, data = clean_tas_data) #perform an anova with sentence length as the dependent variable and sentence number as the independent variable
summary_anova_words <- summary(anova_result_words) #get summary of anova results
f_value <- summary_anova_words[[1]]$`F value`[1] #pull out F value
formatted_f_value <- formatted_f_value <- str_replace(formatC(f_value, format = "f", digits = 2), "^0", "") #2 decimal places and no leading zero
p_value <- summary_anova_words[[1]]["Sentence", "Pr(>F)"] #pull out p value
formatted_p_value <- formatted_p_value <- str_replace(formatC(p_value, format = "f", digits = 2), "^0", "") #2 decimal places and no leading zero
significance_statement <- if (p_value > 0.05) "not" else ""
cat("The analysis of variance showed that the number of words per sentence did",
    significance_statement, 
    "vary significantly by sentence (F =",
    formatted_f_value,
    ", p = ",
    formatted_p_value,
    ")." 
)
#output: The analysis of variance showed that the number of words per sentence did vary significantly by sentence (F = 1104.60, p = .00).

#number of letters per word
anova_result_letters <- aov(num_ltrs ~ Sentence, data = clean_tas_data) #perform an anova with sentence length as the dependent variable and sentence number as the independent variable
summary_anova_letters <- summary(anova_result_letters) #get summary of anova results
f_value <- summary_anova_letters[[1]]$`F value`[1] #pull out F value
formatted_f_value <- formatted_f_value <- str_replace(formatC(f_value, format = "f", digits = 2), "^0", "") #2 decimal places and no leading zero
p_value <- summary_anova_letters[[1]]["Sentence", "Pr(>F)"] #pull out p value
formatted_p_value <- formatted_p_value <- str_replace(formatC(p_value, format = "f", digits = 2), "^0", "") #2 decimal places and no leading zero
significance_statement <- if (p_value > 0.05) "not" else ""
cat("The analysis of variance showed that the number of letters per word did",
    significance_statement, 
    "vary significantly by sentence (F =",
    formatted_f_value,
    ", p = ",
    formatted_p_value,
    ")." 
    )
#output: The analysis of variance showed that the number of letters per word did not vary significantly by sentence (F = 3.38, p = .07).


# Data Export
write_csv(clean_tas_data, "./app_final/clean_tas_data.csv") #normally I would save this to "out" because it's a cleaned file. However, in order to be able to deploy my Shiny app it has to be inside the Shiny folder.

