# psy8712-final

Please read the following before accessing any other files in this repo. All instructions are based off of the assumption that you are using RStudio to clone and access this repo.

### Folder Structure for Repo

-   data - contains the original dataset (tas_data.csv) for this project. This data is taken from a think-aloud study with fourth and fifth grade students where they responded out loud after each sentence of a text (and they read two different texts – one narrative and one expository). Students were also randomly split into two conditions – iterative and consecutive. For the iterative condition, students only saw the current sentence displayed on the screen. For the consecutive condition, they saw the current sentence plus all previous sentences displayed on the screen. There are many different columns in this dataset related to the original study; only some will be used for the current project.

-   docs - contains the final report for this project

-   figs - contains static figures that will be used in final report (fig1_descriptives_words.png, fig2_descriptives_letters.png, fig3_frequency.png, fig4_sentiment.png)

-   out - contains table outputs that will be used in final report (tbl1_descriptives_table.csv)

-   R - contains R script file (final.R) to clean the data to prep it to be used for the Shiny app. This file also contains the code to create the figures seen in the 'fig' folder. This folder also contains necessary components to run the interactive Shiny app (app_final folder). There are two important files to know inside the app_final folder. First is the cleaned, skinny data file (clean_tas_data.csv) that is the output of the final.R script. This is the file used for the Shiny app. The second file is the actually R script that runs the Shiny app (app.R).

-   Rmd - contains the Rmd file used to create the final report

### Instructions for Reproducing Project

1.  The first file to run is final.R, located within the "R" folder. After running the entire script, there will be six new files created:

    -   clean_tas_data.csv will output to the "app_final" folder (within the "R" folder)

    -   fig1_descriptives_words.png, fig2_descriptives_letters.png, fig3_frequency.png, fig4_sentiment.png will all output to the "figs" folder

    -   tbl1_descriptives_table.csv will output to the "out" folder

2.  Next, you should run the app.R file, located within the "app_final" folder inside the "R" folder. If you already have Shiny installed when you open the file in RStudio you should be able to click the "Run App" button near the top of the window. This should create a pop-up in your browser that shows the Shiny app.

### Other Important Information

-   Binder - description and link

-   In order to access the Shiny app without going through the steps of loading all the script files, it can be accessed at [this link](https://jens2482.shinyapps.io/app_final/).
