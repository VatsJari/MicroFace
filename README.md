![image](https://user-images.githubusercontent.com/85255019/226131956-84d1a69f-b6c7-4e44-b58d-b28e923d4456.png)

## Abstract

The implantation of flexible neural probes induces traumatic brain injury (TBI) and triggers neuroinflammation, affecting probe performance. Microglia, the brain's resident immune cells, play a critical role in initiating and sustaining neuroinflammation. Activated microglia undergo morphological changes, transitioning from a resting, highly branched state to an amoeboid shape, indicative of specific functions in neuroinflammation. However, microglia can also exhibit intermediate forms between amoeboid and branched states, with morphology and function varying during processes such as migration, phagocytosis, and process extension/retraction. Traditional methods for measuring microglial morphology can be labor-intensive and prone to errors, making automated image analysis a valuable alternative.

To address these challenges, we developed an automated image analysis approach using Iba1-immunostained microglial images from a TBI rat model implanted with flexible neural probes. The methodology involved multiple stages, including preprocessing, illumination correction, skeleton reconstruction, and data clustering. This technique enabled the quantification of microglial morphology from microscopy images, yielding up to 79 morphological parameters for over 400,000 microglia.

The spatiotemporal distribution analysis revealed an increase in microglia cell density after acute injury at 1-, 2-, and 8-weeks post-implantation (WPI), indicating microglial proliferation toward the injury site. Hierarchical clustering analysis demonstrated a 95% similarity in morphology parameters between microglial cells near and far from the injury site at 2 WPI, suggesting a state of homeostasis. However, this homeostatic phase was disrupted at 8- and 18-WPI, potentially indicating chronic inflammation. Principal component analysis (PCA) of individual microglial cells identified 14 distinct morphotypes, grouped into four major phenotypes: amoeboid, highly branched, transitional, and rod-like microglia. The occurrence frequency of these phenotypes revealed three spatial distribution zones related to TBI: activated, intermediate, and homeostatic zones.

In summary, our automated tool for classifying microglial morphological phenotypes provides a time-efficient and objective method for characterizing microglial changes in the TBI rat model and potentially in human brain samples. Furthermore, this tool is not limited to microglia and can be applied to various cell types.




## Experimental Design 

In this project, a rat model of neuroinflammation was used to develop an automated workflow for quantifying microglia morphology over an extended implantation period. The effects of flexible neural probe implantation on microglial morphology were investigated, aiming to identify features sensitive to different activation states. Animals were sacrificed at various time points (0-18WPI), and brain sections were subjected to immunohistochemistry. Microscopic images from the cortex region were processed using Fiji for brightness and contrast adjustment, followed by analysis using a CellProfiler pipeline. This pipeline corrected illumination inconsistencies and generated a skeleton representation of microglia, allowing measurement of parameters related to their shape and size. The resulting data were then subjected to analysis using techniques such as PCA, hierarchical clustering, and statistical analysis in R Studio. The workflow provided valuable insights into the structure and spatiotemporal distribution of microglia.

![Copy of Untitled (6)](https://github.com/vatsal-jari/MicroFace.github.io/assets/85255019/ec2c58c0-ea53-408d-bb5e-21f7f61fd9cc)

## Imaging Analysis

The acquisition of image data involved several steps, including pre-processing, illumination correction, and automated segmentation. Through these processes, we were able to successfully reconstruct over 400,000 microglia cells from a dataset comprising more than 200 images.

### Image Pre-processing

In our study, we utilized Fiji software for the preprocessing of images, following the workflow depicted in Figure below, The initial step involved adjusting the brightness and contrast of the images using the "AUTO" mode in Fiji. This automated feature calculates the minimum and maximum intensity values in the image and scales the pixel values accordingly, resulting in a balanced distribution of pixel intensities across the image. Next, we applied the rolling ball method with a radius of 50 pixels to subtract the image background. This technique effectively removes the background, enhancing the clarity of the image for further analysis. To enhance image contrast, we employed the saturation pixel method, which sets a small percentage (1%) of the brightest and darkest pixels in the image to pure white and black, respectively.

![Untitled (17)](https://github.com/vatsal-jari/MicroFace.github.io/assets/85255019/ff531a23-6052-4ece-b216-12beff3a4824)

### Illumination Correction 
### The Skeleton Pipeline

![Untitled (18)](https://github.com/vatsal-jari/MicroFace.github.io/assets/85255019/25a8ebab-e8dc-40ce-80dd-fb363d7b3bb3)


***

## Data Analysis

After preprocessing and segmenting the images, we generated a datasheet that contained information on individual microglia and their corresponding parameters, such as shape and size, using CellProfiler software. This datasheet was then imported into R Studio, where we conducted statistical analysis. 


***


###  Require Packages

By running this code, it ensures that all the necessary packages are installed and loads them into the R environment, allowing subsequent code to make use of their functions.

```
##### CHECK FOR THE PACKAGES AND INSTALL IF NOT AVAILABLE #####

# Create a list to store package information
packages <- list()

# Specify the required packages
packages$my_packages <- c("readr", "plyr", "readxl", "dplyr", "factoextra", "cluster", "readxl"
                 , "tidyverse", "corrplot", "dataRetrieval", "dplyr", "tidyr", "ggplot2", "rsq"
                 , "ggpmisc", "writexl", "Biobase", "cluster", "BiocManager", "ConsensusClusterPlus", "pheatmap", "vroom", "ggforce", "plotrix",
                 "moments", "Seurat", "patchwork", "clusterSim", "tidymodels", "recipes", "tidytext", "embed", "corrr", "viridis", "randomForest", "BiocParallel", "pheatmap",
                 "dendextend", "RColorBrewer", "dendsort", "ape", "BBmisc", "ggExtra", "fmsb", "GGally", "gghighlight", "wesanderson","remotes", "ggstream", "devtools", "ggdark",
                  "streamgraph", "reshape2", "cardiomoon/moonBook","cardiomoon/webr")

# Check for packages that are not installed
packages$not_installed <- packages$my_packages[!(packages$my_packages %in% installed.packages()[ , "Package"])]

# Install packages if they are not already installed
if(length(packages$not_installed)) 
  install.packages(packages$not_installed)

##### BIOCONDUCTOR BASED PACKAGES #####

# Install and load the required Bioconductor packages
if (!require("BiocManager", quietly = TRUE))
  install.packages("BiocManager")
BiocManager::install(version = "3.17")

BiocManager::install("ConsensusClusterPlus")
BiocManager::install("BiocParallel")
BiocManager::install("ggbiplot")

##### GITHUB BASED PACKAGES #####

# Install packages from GitHub repositories
devtools::install_github("nsgrantham/ggdark")
remotes::install_github("davidsjoberg/ggstream")
devtools::install_github("hrbrmstr/streamgraph")

devtools::install_github("cardiomoon/moonBook")
devtools::install_github("cardiomoon/webr")

##### LOAD ALL THE PACKAGES AT ONCE #####

# Load all the required packages
lapply(packages$my_packages, require, character.only = TRUE)

``````

1. Creates a list called `packages` to store package information.
2. Defines the required packages in the `my_packages` vector.
3. Checks for any packages that are not currently installed using the `installed.packages()` function and stores them in `not_installed`.
4. Installs the missing packages using `install.packages()` if there are any.
5. Installs the required Bioconductor packages using `BiocManager::install()`.
6. Installs packages from GitHub repositories using `devtools::install_github()` and `remotes::install_github()`.
7. Loads all the required packages using `lapply()` and `require()`.

By running this code, it ensures that all the necessary packages are installed and loads them into the R environment, allowing subsequent code to make use of their functions.



***


### Import the data sheets into R-studio environment

```
import <- list()

##### COPY THE PATH OF FOLDER THAT CONTAINS ALL THE TEXT FILES #####

# Specify the folder paths for the text files containing the data
import$folder_path_soma = "File_Location_to_Datasheet_all_soma/"
import$folder_path_cell = "File_Location_to_Datasheet_all_cell/"

# STORE ALL THE FILE NAMES INTO ON OBJECT = LIST_OF_ALL_FILES_SOMA

# Get a list of all the text file names in the specified folder paths
import$list_of_files_soma <- list.files(path = import$folder_path_soma , recursive = TRUE,
                            pattern = "*.txt", full.names = TRUE)
import$list_of_files_cell <- list.files(path = import$folder_path_cell , recursive = TRUE,
                                 pattern = "*.txt", full.names = TRUE)  

##### MERGE ALL THE FILES INTO ONE BIG DATAFRAME. ALSO ADDING FILENAME TO A NEW COLUMN #####

# Merge all the text files into a single dataframe, with the 'FileName' column indicating the file name
import$df_soma <- vroom(import$list_of_files_soma, id = "FileName")
import$df_cell <- vroom(import$list_of_files_cell, id = "FileName")

##### CREATE A NEW COLUMN WITH NAME = CONDITION AND APPEND THE VALUE IN FORM OF (PROBESIZE_TIMEPOINT) #####

# Extract the condition information from the 'FileName' column and store it in the 'Condition' column
import$df_soma <- import$df_soma %>%
  mutate(Condition = str_remove(FileName, pattern = import$folder_path_soma)) %>%
  mutate(Condition = str_remove(Condition, pattern = ".txt")) %>%
  mutate(Condition = str_remove(Condition, pattern = "/"))

import$df_cell <- import$df_cell %>%
  mutate(Condition = str_remove(FileName, pattern = import$folder_path_cell)) %>%
  mutate(Condition = str_remove(Condition, pattern = ".txt")) %>%
  mutate(Condition = str_remove(Condition, pattern = "/"))

##### DELETING THE COLUMN FILENAME #####

# Remove the 'FileName' column from the dataframes
import$df_soma <-subset(import$df_soma, select = -c(FileName))
import$df_cell <-subset(import$df_cell, select = -c(FileName))

##### RENAMING THE COLUMN NAMES: BY SUBTRACTING "AREASHAPE_" & ADDING "_SOMA" TO THE COLUMN NAMES #####

# Rename the columns of the dataframe by removing "AreaShape_" and adding "_soma" as a suffix
colnames(import$df_soma) <- gsub("AreaShape_","",colnames(import$df_soma)) %>%
  paste("soma",sep="_")
colnames(import$df_cell) <- gsub("AreaShape_","",colnames(import$df_cell)) %>%
  paste("cell",sep="_")

##### MERGE DATAFRAMES: DF_SOMA & DF_CELL INTO ONE BIG FILE #####

# Merge the 'df_cell' and 'df_soma' dataframes into a single dataframe based on specified column matches
import$df_all <- merge(import$df_cell, import$df_soma, by.x = c('ImageNumber_cell', 'Parent_Soma_cell', 'Condition_cell'), 
                by.y = c('ImageNumber_soma', 'Parent_Soma_soma', 'Condition_soma'))

##### REMOVE UNWANTED COLUMNS FROM THE FINAL DATASET #####

# Remove unwanted columns from the 'df_all' dataframe
import$df_all <- subset(import$df_all, select = -c(Location_Center_X_soma, Location_Center_Z_soma,Location_Center_Y_soma, Location_Center_X_cell,
                                     Location_Center_Z_cell, Location_Center_Y_cell, Children_Cell_Count_soma))

##### IMPORT THE DATASHEET WHICH CONTAINS INJURY COORDINATES #####

# Read the injury center coordinates from an Excel file
import$Injury_center <- read_excel("/Volumes/JARI-NES/Brain Injury project/4 Datasheet/Injury center.xls")

##### ADD THE INJURY X & Y COORDINATES TO THE MAIN DATA SHEET (DF_ALL) #####

# Merge the 'df_all' and 'Injury_center' dataframes based on specified column matches
import$df_all <- merge(import$df_all, import$Injury_center, by.x = c("ImageNumber_cell", "Condition_cell"), by.y = c("Image_Number", "Condition"), all.x=TRUE)

##### ADDING COLUMNS FOR CONDITION AND TIME POINT #####

# Split the 'Condition_cell' column into 'Electrode_Thickness' and 'Time_weeks' columns
import$colmn <- paste('Electrode_Thickness',1:2)

import$df_all <- tidyr::separate(
  data = import$df_all,
  col = Condition_cell,
  sep = "_",
  into = import$colmn,
  remove = FALSE)

names(import$df_all)[names(import$df_all) == 'Electrode_Thickness 2'] <- 'Time_weeks'
names(import$df_all)[names(import$df_all) == 'Electrode_Thickness 1'] <- 'Electrode_Thickness'
names(import$df_all)[names(import$df_all) == 'ObjectSkeleton_NumberBranchEnds_MorphologicalSkeleton_soma'] <- 'Branch_Ends'
names(import$df_all)[names(import$df_all) == 'ObjectSkeleton_NumberNonTrunkBranches_MorphologicalSkeleton_soma'] <- 'Non_Trunk_Branch'
names(import$df_all)[names(import$df_all) == 'ObjectSkeleton_NumberTrunks_MorphologicalSkeleton_soma'] <- 'Trunk_Branch'
names(import$df_all)[names(import$df_all) == 'ObjectSkeleton_TotalObjectSkeletonLength_MorphologicalSkeleton_soma'] <- 'Skeleton_Length'
names(import$df_all)[names(import$df_all) == 'x'] <- 'Injury_x'
names(import$df_all)[names(import$df_all) == 'y'] <- 'Injury_y'

##### EXPORT THE DATASHEET AS A .XLSX FILE #####

# Export the 'df_all' dataframe as an Excel file
write_xlsx(import$df_all,"File_Location_to_df_all.xlsx") 

```


This code snippet performs the following actions:

1. Creates a list called `import` to store various data objects.
2. Specifies the folder paths for the text files containing the data.
3. Retrieves a list of all the text file names in the specified folder paths.
4. Merges all the text files into two dataframes (`df_soma` and `df_cell`) and adds a `FileName` column indicating the file name.
5. Extracts the condition information from the `FileName` column and creates a `Condition` column in the dataframes.
6. Deletes the `FileName` column from the dataframes.
7. Renames the column names by removing "AreaShape_" and adding "_soma" or "_cell" as a suffix.
8. Merges the `df_soma` and `df_cell` dataframes into one using specified column matches.
9. Removes unwanted columns from the merged dataframe.
10. Reads the injury center coordinates from an Excel file.
11. Adds the injury X and Y coordinates to the main dataframe (`df_all`) based on specified column matches.
12. Adds columns for condition and time point by splitting the `Condition_cell` column.
13. Renames specific columns in the dataframe.
14. Exports the resulting dataframe (`df_all`) as an Excel file.


(Note: Please ensure that the folder paths and file paths provided in the code are accurate and accessible according to your file locations)


***

### Visualization of microglia cell distribution around the injury location 

The code provided generates a count plot to visualize the number of cells in relation to the bin number for all conditions.

```
# create a new object for this part of the result
count <- list()

# import the datasheet from import to count object. then perform counting of cells using group_by function
count$df_counts <- import$df_all %>% 
  group_by(ImageNumber_cell, Condition_cell, Bin_Number_New) %>% 
  summarize(num_cells = n())

# create two separate columns for time_weeks and electrode thickness
count$colmn_count <- paste('Electrode_Thickness',1:2)
count$df_counts <- tidyr::separate(
  data = count$df_counts,
  col = Condition_cell,
  sep = "_",
  into = count$colmn_count,
  remove = FALSE)

names(count$df_counts)[names(count$df_counts) == 'Electrode_Thickness 2'] <- 'Time_weeks'
names(count$df_counts)[names(count$df_counts) == 'Electrode_Thickness 1'] <- 'Electrode_Thickness'

# Remove rows where Bin_Number_New is 17
count$df_counts <- filter(count$df_counts, Bin_Number_New != 17)

# Calculate radial distance and normalized area
count$df_counts$radial_dist <- 139 * count$df_counts$Bin_Number_New
count$df_counts$norm_area <- (pi * (count$df_counts$radial_dist)^2) - (pi * (count$df_counts$radial_dist-139)^2)

# Create the boxplot
count$plot <- ggplot(count$df_counts, aes(x = Bin_Number_New, y = count$df_counts$num_cells / 2*sqrt((pi / count$df_counts$norm_area)), group = Bin_Number_New, fill = Time_weeks)) +
  geom_boxplot() +
  facet_grid(~Time_weeks) +
  ggtitle("Number of Cells per Bin") +
  scale_fill_manual(values=company_colors) +
  stat_summary(fun.y=median, geom="point", size=2, color="white") +
  xlab("Bin Number") + ylab("Number of Cells normalized to the area") +
  theme_bw() +
  ggtitle("") +
  labs(fill = "Time (Weeks)") +
  theme(
    plot.title = element_text(size=24, hjust = 0.5, face="bold"),
    axis.title.x = element_text(size=22, face="bold"),
    axis.title.y = element_text(size=22, face="bold"),
    axis.text.x = element_text(size = 17, face="bold"),
    axis.text.y  = element_text(size = 17, face="bold"),
    legend.text = element_text(size = 16,  face="bold"),
    legend.title = element_text(size = 18,  face="bold"),
    legend.key.size = unit(1.5, "lines"),
    legend.position = "bottom",
    strip.text = element_text(size = 18, face = "bold"))

# Print the plot
print(count$plot)

```

1. Creates a new object called `count` to store the results.
2. Imports the `df_all` dataframe from the `import` object to the `count` object.
3. Counts the number of cells by grouping the dataframe based on `ImageNumber_cell`, `Condition_cell`, and `Bin_Number_New`.
4. Creates separate columns for `Time_weeks` and `Electrode_Thickness`.
5. Renames specific columns in the dataframe.
6. Filters out rows where `Bin_Number_New` is equal to 17.
7. Calculates the `radial_dist` and `norm_area` columns based on the bin number.
8. Creates the count plot using `ggplot`.
9. Adds a boxplot with facets based on `Time_weeks`.
10. Sets the title, axis labels, and theme for the plot.
11. Prints the plot.

Note: Make sure to provide the required data and color information (`company_colors`) for the plot to work correctly.

**Output:**

![image](https://github.com/vatsal-jari/MicroFace.github.io/assets/85255019/9eb4a29a-9e77-451a-970f-25f8ed7dd06e)


***

### 


```
##### CALCULATE THE DISTANCE OF EACH CELL FROM THE MID POINT (IN THIS CASE IT IS 2764, 2196) AND CLASIFY THE CELLS ACCORDING TO THE DISTANCE FROM THE CENTER INTO 20 BINS #####

# Calculate the distance from the midpoint using the Euclidean distance formula
import$df_all$radial_dist <- sqrt((import$df_all$Center_X_soma - import$df_all$Injury_x)^2 + (import$df_all$Center_Y_soma - import$df_all$Injury_y)^2)

# Assign a bin number to each cell based on the radial distance
import$df_all$bin_number <- ntile(import$df_all$radial_dist, 25)

# Calculate the range of each bin by multiplying the bin number by 139
import$df_all$bin_range <- import$df_all$bin_number * 139

# Create a new column to store the updated bin numbers
import$df_all$Bin_Number_New <- import$df_all$bin_number

# Update the bin numbers for cells beyond the 16th bin
import$df_all$Bin_Number_New[import$df_all$bin_number > 16] <- 17

# Calculate a new range for the updated bin numbers
import$df_all$bin_range_new <- import$df_all$Bin_Number_New * 139


##### RAMIFICATION INDEX OF THE CELL #####

# Calculate the ramification index (RI) of each cell
import$df_all$RI <- ((import$df_all$Perimeter_cell / import$df_all$Area_cell) / (2 * sqrt(pi / import$df_all$Area_cell)))


##### AREA RATIO OF CELL TO SOMA #####

# Calculate the area ratio of each cell to its soma
import$df_all$area_ratio <- import$df_all$Area_cell / import$df_all$Area_soma


##### LENGTH TO WIDTH RATIO OF CELL & SOMA (ROD-LIKE MORPHOLOGY OF CELL) #####

# Calculate the length to width ratio of the cell
import$df_all$Length_Width_Ratio_cell <- import$df_all$MaxFeretDiameter_cell / import$df_all$MinFeretDiameter_cell

# Calculate the length to width ratio of the soma
import$df_all$Length_Width_Ratio_soma <- import$df_all$MaxFeretDiameter_soma / import$df_all$MinFeretDiameter_soma


##### ASPECT RATIO OF CELL WHICH IS DEFINED AS MAJOR AXIS LENGTH TO MINOR AXIS LENGTH #####

# Calculate the aspect ratio of the cell
import$df_all$Aspect_Ratio_cell <- import$df_all$MajorAxisLength_cell / import$df_all$MinorAxisLength_cell

# Calculate the aspect ratio of the soma
import$df_all$Aspect_Ratio_soma <- import$df_all$MajorAxisLength_soma / import$df_all$MinorAxisLength_soma


##### BRANCHING RATIO OF THE SECONDARY (NON-TRUNK) TO PRIMARY (TRUNKS) BRANCHES #####

# Calculate the branching ratio of the secondary to primary branches
import$df_all$Branch_Ratio <- import$df_all$Non_Trunk_Branch / import$df_all$Trunk_Branch

# Calculate the total number of branches
import$df_all$Total_Branch <- import$df_all$Non_Trunk_Branch + import$df_all$Trunk_Branch


##### CYTOPLASMIC AREA OF MICROGLIA #####

# Calculate the cytoplasmic area of each microglia cell
import$df_all$Cyto_Area <- import$df_all$Area_cell - import$df_all$Area_soma


##### GROUPING THE DATAFRAME INTO FAR & NEAR THE INJURY LOCATION USING BINS < 6 IS NEAR, > 13 IS FAR, AND REST IS MIDDLE #####

# Group the cells into regions based on their bin numbers
import$df_all$Impact_Region <- case_when(
  import$df_all$Bin_Number_New <= 5 ~ "Near",
  import$df_all$Bin_Number_New >= 8 ~ "Far",
  TRUE ~ "Middle"
)


##### HEALTH SCORE OF CELLS FROM 0-1 #####

# Calculate the health score of each cell based on the total number of branches
import$df_all$Health_score <- case_when(
  import$df_all$Total_Branch >= 20 ~ 1,
  import$df_all$Total_Branch <= 19 ~ (1 - (((20 - import$df_all$Total_Branch) / 2)) / 10)
)


##### COLOUR PALETTE #####

# Define a color palette for visualization
company_colors <- c("#E50000", "#008A8A", "#AF0076", "#E56800", "#1717A0", "#E5AC00", "#00B700")


##### EXCLUSION CRITERIA #####

# Define a function to filter the data based on specific criteria
filter_data_1 <- function(df) {
  df_all_filtered_10 <- df[!(df$Bin_Number_New >= 11 & df$RI < 2),]
  df_all_filtered_20 <- df_all_filtered_10[!(df_all_filtered_10$Bin_Number_New <= 6 & df_all_filtered_10$RI > 5),]
  df_all_filtered_30 <- df_all_filtered_20[!(df_all_filtered_20$Total_Branch > 90),]
  df_all_filtered_40 <- df_all_filtered_30[!(df_all_filtered_30$Bin_Number_New >= 11 & df_all_filtered_30$area_ratio < 2 & df_all_filtered_30$Time_weeks > 0 & df_all_filtered_30$Time_weeks < 8),]
  df_all_filtered_50 <- df_all_filtered_40[!(df_all_filtered_40$Bin_Number_New <= 6 & df_all_filtered_40$Non_Trunk_Branch > 10 & df_all_filtered_40$Time_weeks > 0 & df_all_filtered_40$Time_weeks < 8),]
  return(df_all_filtered_50)
}

# Define another function to filter the data based on additional criteria
filter_data_2 <- function(df) {
  df_all_filtered_1 <- df_all[!(df_all$Bin_Number_New >= 10 & df_all$Time_weeks >= 2 & df_all$Total_Branch < 20 & df_all$Electrode_Thickness == 50),]
  df_all_filtered_2 <- df_all_filtered_1[!(df_all_filtered_1$Bin_Number_New <= 8 & df_all_filtered_1$Time_weeks >= 18 & df_all_filtered_1$Total_Branch > 20),]
  df_all_filtered_3 <- df_all_filtered_2[!(df_all_filtered_2$Bin_Number_New >= 14 & df_all_filtered_2$Total_Branch <= 20),]
  df_all_filtered_4 <- df_all_filtered_3[!(df_all_filtered_3$Total_Branch > 70),]
  return(df_all_filtered_4)
}


##### REORDER THE COLUMNS WHICH ARE NOT NECESSARY TO THE FIRST #####

# Reorder the columns in the dataframe, moving unnecessary columns to the end
import$df_all_reordered <- import$df_all %>% dplyr::select(c(9, 10, 11, 12, 13, 14, 19, 29, 32, 33, 34, 37, 38, 39, 40, 41, 42, 47, 57, 60, 65, 66, 68, 69, 70, 71, 78, 81), everything())

##### SELECT THE COLUMNS THAT REPRESENT THE ACTUAL VALUES OF MICROGLIA MORPHOLOGY #####

# Create a new dataframe containing only the columns representing microglia morphology
import$df_all_reordered_raw <- import$df_all_reordered[, colnames(import$df_all_reordered)[c(25, 31, 32, 35:81)]]

# Write the reordered dataframe to a CSV file
write.csv(import$df_all_reordered, "D:/Brain Injury project/4 Datasheet/df_all_reordered.csv", row.names = FALSE)

```



1. **Calculating the Distance from the Midpoint:**
   - The code calculates the distance of each cell from the midpoint `(2764, 2196)` using the Euclidean distance formula.
   - It uses the coordinates `Center_X_soma` and `Center_Y_soma` from the dataframe `import$df_all` to represent the cell's position.
   - The coordinates `Injury_x` and `Injury_y` represent the midpoint.
   - The result is stored in the `radial_dist` column of the dataframe.

2. **Assigning Bin Numbers:**
   - The code assigns a bin number to each cell based on its radial distance.
   - It uses the `ntile` function to divide the `radial_dist` values into 25 equal-sized bins.
   - The result is stored in the `bin_number` column.

3. **Calculating Bin Ranges:**
   - The code calculates the range of each bin by multiplying the bin number by 139.
   - The result is stored in the `bin_range` column.

4. **Updating Bin Numbers:**
   - The code creates a new column `Bin_Number_New` to store the updated bin numbers.
   - It copies the values from the `bin_number` column initially assigned in the previous step.

5. **Adjusting Bin Numbers:**
   - For rows where the `bin_number` is greater than 16 (i.e., beyond the 16th bin), the code assigns a value of 17 to `Bin_Number_New`.
   - This step ensures that all cells beyond the 16th bin are grouped together under bin number 17.

6. **Calculating New Bin Ranges:**
   - The code calculates a new range for `Bin_Number_New` by multiplying it by 139.
   - The result is stored in the `bin_range_new` column.

7. **Ramification Index (RI) Calculation:**
   - The code calculates the Ramification Index (RI) of each cell.
   - RI is calculated as `(Perimeter_cell / Area_cell) / (2 * sqrt(pi / Area_cell))`.
   - The result is stored in the `RI` column.

8. **Area Ratio Calculation:**
   - The code calculates the area ratio of each cell to its soma.
   - It divides the `Area_cell` by the `Area_soma`.
   - The result is stored in the `area_ratio` column.

9. **Length to Width Ratio Calculation:**
   - The code calculates the length to width ratio of both the cell and soma.
   - For cells, it divides the `MaxFeretDiameter_cell` by the `MinFeretDiameter_cell`.
   - For soma, it divides the `MaxFeretDiameter_soma` by the `MinFeretDiameter_soma`.
   - The results are stored in the `Length_Width_Ratio_cell` and `Length_Width_Ratio_soma` columns, respectively.

10. **Aspect Ratio Calculation:**
    - The code calculates the aspect ratio of both the cell and soma.
    - For cells, it divides the `MajorAxisLength_cell` by the `MinorAxisLength_cell`.
    - For soma, it divides the `MajorAxisLength_soma` by the `MinorAxisLength_soma`.
    - The results are stored in the `Aspect_Ratio_cell` and `Aspect_Ratio_soma` columns, respectively.

11. **Branching Ratio Calculation:**
    - The code calculates the branching ratio of the secondary (non-trunk) branches to the primary (trunk) branches.
    - It divides

 the `Non_Trunk_Branch` by the `Trunk_Branch`.
    - The result is stored in the `Branch_Ratio` column.

12. **Total Branch Calculation:**
    - The code calculates the total number of branches for each cell.
    - It sums the `Non_Trunk_Branch` and `Trunk_Branch` values.
    - The result is stored in the `Total_Branch` column.

13. **Cytoplasmic Area Calculation:**
    - The code calculates the cytoplasmic area of each microglia cell.
    - It subtracts the `Area_soma` from the `Area_cell`.
    - The result is stored in the `Cyto_Area` column.

14. **Grouping Cells based on Bin Numbers:**
    - The code groups the cells into three regions based on the `Bin_Number_New` column.
    - Cells with bin numbers less than or equal to 5 are classified as "Near".
    - Cells with bin numbers greater than or equal to 8 are classified as "Far".
    - The remaining cells fall into the "Middle" category.
    - The classification is stored in the `Impact_Region` column.

15. **Health Score Calculation:**
    - The code calculates a health score for each cell based on its total number of branches (`Total_Branch`).
    - If the total number of branches is greater than or equal to 20, the health score is set to 1.
    - For cells with a total number of branches less than 20, the health score is calculated as `(1 - ((20 - Total_Branch) / 2)) / 10`.
    - The result is stored in the `Health_score` column.

16. **Color Palette Definition:**
    - The code defines a color palette (`company_colors`) with seven color values for visualization purposes.

17. **Filtering Functions:**
    - The code defines two filtering functions (`filter_data_1` and `filter_data_2`) to exclude specific rows from the dataframe based on certain criteria.
    - These functions help remove unwanted data from the analysis.

18. **Reordering Columns:**
    - The code reorders the columns of the `import$df_all` dataframe to prioritize the necessary columns.
    - It selects the necessary columns and stores the reordered dataframe in `import$df_all_reordered`.

19. **Selecting Actual Morphology Columns:**
    - The code selects specific columns from `import$df_all_reordered` that provide the actual values of microglia morphology.
    - It stores the result in `import$df_all_reordered_raw`.

20. **Writing the Data to a CSV File:**
    - The code writes the reordered dataframe (`df_all_reordered`) to a CSV file named "df_all_reordered.csv" located at "D:/Brain Injury project/4 Datasheet/".
   



***

### Hierarchical clustering analysis for comparision of cell populations closer


1. First list item
   - First nested list item
     - Second nested list item
