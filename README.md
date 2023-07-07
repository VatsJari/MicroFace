## Table of Contents


<!-- Add a div element to hold the sidebar -->
<div class="sidebar">
  <ul>
    <li><a href="#abstract">Abstract</a></li>
    <li><a href="#experimental-design">Experimental Design</a>
      <ul>
        <li><a href="#imaging-analysis">Imaging Analysis</a>
          <ul>
            <li><a href="#image-pre-processing">Image Pre-processing</a></li>
            <li><a href="#illumination-correction">Illumination Correction</a></li>
            <li><a href="#the-skeleton-pipeline">The Skeleton Pipeline</a></li>
          </ul>
        </li>
      </ul>
    </li>
    <li><a href="#data-analysis">Data Analysis</a>
      <ul>
        <li><a href="#require-packages">Require Packages</a></li>
        <li><a href="#import-the-data-sheets-into-r-studio-environment">Import the data sheets into R-studio environment</a></li>
        <li><a href="#defining-new-function-and-parameters-from-the-existing-parameters-in-the-dataframe">Defining new function and parameters from the existing parameters in the dataframe</a></li>
         <li><a href="#Visualization-of-microglia-cell-distribution-around-the-injury-location">Visualization of microglia cell distribution around the injury location</a></li>
         <li><a href="#Hierarchical-clustering-analysis-for-comparision-of-cell-populations">Hierarchical clustering analysis for comparision of cell populations</a></li>
         <li><a href="#Assess-the-dominant-parameters-variability-over-time">Assess the dominant parameters variability over time</a></li>
         <li><a href="#Introducing-Tanglegrams-Exploring-the-Relationships-between-Dendrograms-in-Microglia-Analysis">Introducing Tanglegrams: Exploring the Relationships between Dendrograms in Microglia Analysis</a></li>
         <li><a href="#Single-cell-morphometry-analysis">Single-cell morphometry analysis</a></li>
        <li><a href="#Definign-the-morphology-of-each-morpho-types">Definign the morphology of each morpho-types</a></li>
        <li><a href="#Spatial-distribution-of-morpho-types">Spatial distribution of morpho types</a></li>
      </ul>
    </li>
  </ul>
</div>





![image](https://user-images.githubusercontent.com/85255019/226131956-84d1a69f-b6c7-4e44-b58d-b28e923d4456.png)

## Abstract

The implantation of flexible neural probes induces traumatic brain injury (TBI) and triggers neuroinflammation, affecting probe performance. Microglia, the brain's resident immune cells, play a critical role in initiating and sustaining neuroinflammation. Activated microglia undergo morphological changes, transitioning from a resting, highly branched state to an amoeboid shape, indicative of specific functions in neuroinflammation. However, microglia can also exhibit intermediate forms between amoeboid and branched states, with morphology and function varying during processes such as migration, phagocytosis, and process extension/retraction. Traditional methods for measuring microglial morphology can be labor-intensive and prone to errors, making automated image analysis a valuable alternative.

To address these challenges, we developed an automated image analysis approach using Iba1-immunostained microglial images from a TBI rat model implanted with flexible neural probes. The methodology involved multiple stages, including preprocessing, illumination correction, skeleton reconstruction, and data clustering. This technique enabled the quantification of microglial morphology from microscopy images, yielding up to 79 morphological parameters for over 400,000 microglia.

The spatiotemporal distribution analysis revealed an increase in microglia cell density after acute injury at 1-, 2-, and 8-weeks post-implantation (WPI), indicating microglial proliferation toward the injury site. Hierarchical clustering analysis demonstrated a 95% similarity in morphology parameters between microglial cells near and far from the injury site at 2 WPI, suggesting a state of homeostasis. However, this homeostatic phase was disrupted at 8- and 18-WPI, potentially indicating chronic inflammation. Principal component analysis (PCA) of individual microglial cells identified 14 distinct morphotypes, grouped into four major phenotypes: amoeboid, highly branched, transitional, and rod-like microglia. The occurrence frequency of these phenotypes revealed three spatial distribution zones related to TBI: activated, intermediate, and homeostatic zones.

In summary, our automated tool for classifying microglial morphological phenotypes provides a time-efficient and objective method for characterizing microglial changes in the TBI rat model and potentially in human brain samples. Furthermore, this tool is not limited to microglia and can be applied to various cell types.


*******

## Experimental Design 

In this project, a rat model of neuroinflammation was used to develop an automated workflow for quantifying microglia morphology over an extended implantation period. The effects of flexible neural probe implantation on microglial morphology were investigated, aiming to identify features sensitive to different activation states. Animals were sacrificed at various time points (0-18WPI), and brain sections were subjected to immunohistochemistry. Microscopic images from the cortex region were processed using Fiji for brightness and contrast adjustment, followed by analysis using a CellProfiler pipeline. This pipeline corrected illumination inconsistencies and generated a skeleton representation of microglia, allowing measurement of parameters related to their shape and size. The resulting data were then subjected to analysis using techniques such as PCA, hierarchical clustering, and statistical analysis in R Studio. The workflow provided valuable insights into the structure and spatiotemporal distribution of microglia.

![Copy of Untitled (6)](https://github.com/vatsal-jari/MicroFace.github.io/assets/85255019/ec2c58c0-ea53-408d-bb5e-21f7f61fd9cc)


*******
## Imaging Analysis

The acquisition of image data involved several steps, including pre-processing, illumination correction, and automated segmentation. Through these processes, we were able to successfully reconstruct over 400,000 microglia cells from a dataset comprising more than 200 images.


*******

### Image Pre-processing

In our study, we utilized Fiji software for the preprocessing of images, following the workflow depicted in Figure below, The initial step involved adjusting the brightness and contrast of the images using the "AUTO" mode in Fiji. This automated feature calculates the minimum and maximum intensity values in the image and scales the pixel values accordingly, resulting in a balanced distribution of pixel intensities across the image. Next, we applied the rolling ball method with a radius of 50 pixels to subtract the image background. This technique effectively removes the background, enhancing the clarity of the image for further analysis. To enhance image contrast, we employed the saturation pixel method, which sets a small percentage (1%) of the brightest and darkest pixels in the image to pure white and black, respectively.

![Untitled (17)](https://github.com/vatsal-jari/MicroFace.github.io/assets/85255019/ff531a23-6052-4ece-b216-12beff3a4824)


*******

### Illumination Correction 

The images we obtained had very high light intensity at the injury site, which could result in poor segmentation. To address this issue, we utilized the illumination correction module in CellProfiler. This module helped us remove the uneven background illumination from the microscope images, resulting in normalized and equalized cell intensities. This correction made it much easier to identify and accurately segment individual cells.

Illumination correction is a process used to fix lighting issues in images. Imagine taking a photo where some parts are too bright and others are too dark. Illumination correction helps balance the lighting across the image, so it looks more natural and easier to see. It adjusts the brightness and contrast to make sure all the details are clear and visible. 

![Untitled (9)](https://github.com/vatsal-jari/MicroFace.github.io/assets/85255019/e1ec9c99-e89d-4c95-bbc5-d9059826d522)


*******
### The Skeleton Pipeline

![Untitled (18)](https://github.com/vatsal-jari/MicroFace.github.io/assets/85255019/25a8ebab-e8dc-40ce-80dd-fb363d7b3bb3)


*******

## Data Analysis

After preprocessing and segmenting the images, we generated a datasheet that contained information on individual microglia and their corresponding parameters, such as shape and size, using CellProfiler software. This datasheet was then imported into R Studio, where we conducted statistical analysis. 


*******


###  Require Packages

By running this code, it ensures that all the necessary packages are installed and loads them into the R environment, allowing subsequent code to make use of their functions.

```R
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



*******


### Import the data sheets into R-studio environment

```R
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


*******

### Defining new function and parameters from the existing parameters in the dataframe

```R
##### CALCULATE THE DISTANCE OF EACH CELL FROM THE INJURY MID POINT AND CLASIFY THE CELLS ACCORDING TO THE DISTANCE FROM THE CENTER INTO 20 BINS #####

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
   
*******

### Visualization of microglia cell distribution around the injury location 

The code provided generates a count plot to visualize the number of cells in relation to the bin number for all conditions.

```R
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



*******

### Hierarchical clustering analysis for comparision of cell populations

The code creates an object called H_clust, imports specific columns from the dataframe, filters and modifies the data, scales the columns, performs hierarchical clustering, and plots the resulting dendrogram.

```R
#### CREATE A NEW OBJECT CALLED H_clust ####

# Create a new object called H_clust
H_clust <- list()

### IMPORT THE DATAFRAME TO THE LIST ###

# Import the necessary columns from the reordered dataframe into the H_clust list
H_clust$df_clust <- import$df_all_reordered[, colnames(import$df_all_reordered)[c(31, 32, 25, 35:82)]]

# Filter the dataframe to include only rows where Bin_Number_New is less than or equal to 16
H_clust$df_clust <- filter(H_clust$df_clust, Bin_Number_New <= 16)

# Remove the 42nd column from the dataframe
H_clust$df_clust <- H_clust$df_clust[, -42]


#### SCALE THE COLUMNS ####

# Scale the columns in the dataframe using the scale function
H_clust$scale <- scale(H_clust$df_clust[, 4:50])

# Create a new dataframe by combining the first three columns of df_clust with the scaled columns
H_clust$scaled_df <- cbind(H_clust$df_clust[, 1:3], H_clust$scale)


#### HIERARCHICAL CLUSTERING ####

# Perform hierarchical clustering on the transposed scaled dataframe
H_clust$cluster_cols <- hclust(dist(t(H_clust$scaled_df[, 4:50])))


#### PLOT THE UNSORTED DENDROGRAM ####

# Plot the unsorted dendrogram
plot(H_clust$cluster_cols, main = "Unsorted Dendrogram", xlab = "", sub = "")

```

1. Create a new object called `H_clust`.
2. Import the necessary columns from the `import$df_all_reordered` dataframe into the `H_clust` object.
3. Filter the dataframe to include only rows where `Bin_Number_New` is less than or equal to 16.
4. Remove the 42nd column from the dataframe.
5. Scale the columns in the dataframe using the `scale` function to standardize the values.
6. Create a new dataframe by combining the first three columns of `df_clust` with the scaled columns.
7. Perform hierarchical clustering on the transposed scaled dataframe to create a hierarchical clustering object.
8. Plot the unsorted dendrogram, representing the hierarchical clustering results.

**Output:**
![image](https://github.com/vatsal-jari/MicroFace.github.io/assets/85255019/11876429-3119-4c3f-ad18-7cbd03a43362)



By flipping the branches, we can sort the dendrogram in a way that the most similar columns will be clustered on the left side of the plot. Conversely, the columns that are more distant from each other will be clustered on the right side of the plot.

```R
H_clust$sort_hclust <- function(...) as.hclust(dendsort(as.dendrogram(...)))

# Apply the `H_clust$sort_hclust` function to sort the `H_clust$cluster_cols` dendrogram object
H_clust$cluster_cols <- H_clust$sort_hclust(H_clust$cluster_cols)

# Plot the sorted dendrogram
plot(H_clust$cluster_cols, main = "Sorted Dendrogram", xlab = "", sub = "")
```

1. Define a new function `sort_hclust` within the `H_clust` object. This function takes a dendrogram object (`...`) as input and applies the `as.dendrogram` function to convert the object to a dendrogram format. The `dendsort` function is then used to sort the dendrogram. Finally, the sorted dendrogram is converted back to the `hclust` format using `as.hclust`.

2. Apply the `H_clust$sort_hclust` function to the `H_clust$cluster_cols` dendrogram object, sorting the dendrogram based on the specified criteria.

3. Update the `H_clust$cluster_cols` object with the sorted dendrogram.

4. Plot the sorted dendrogram using the `plot` function, with the title "Sorted Dendrogram", no x-axis label (empty string), and no subtitle. This visualizes the sorted hierarchical clustering results.

The code adds a sorting step to the dendrogram using the `dendsort` function to rearrange the hierarchical clustering results, and then plots the sorted dendrogram for visualization.


**Output:**
![image](https://github.com/vatsal-jari/MicroFace.github.io/assets/85255019/65e4fb71-73f5-4a83-97f9-d0d2aad6bc95)


```R
H_clust$gobal_dendrogram <- fviz_dend(
  H_clust$cluster_cols,
  cex = 0.8,
  k = 4,
  rect = TRUE,
  k_colors = "jco",
  rect_border = "jco",
  rect_fill = TRUE,
  horiz = TRUE
) +
  theme(
    plot.title = element_text(size = 24, hjust = 0.5, face = "bold"),
    axis.title.x = element_text(size = 22, face = "bold"),
    axis.title.y = element_text(size = 22, face = "bold"),
    axis.text.x = element_text(size = 17, face = "bold"),
    axis.text.y = element_text(size = 17, face = "bold"),
    legend.text = element_text(size = 16, face = "bold"),
    legend.title = element_text(size = 18, face = "bold"),
    legend.key.size = unit(1.5, "lines"),
    legend.position = "bottom",
    strip.text = element_text(size = 18, face = "bold")
  )

# Plot the global dendrogram
plot(H_clust$gobal_dendrogram)

```

1. Create a new object `H_clust$gobal_dendrogram` that represents the visualization of the dendrogram using the `fviz_dend` function from the `factoextra` package.
2. `H_clust$cluster_cols` is passed as the dendrogram object to be visualized.
3. Additional arguments are provided to customize the appearance of the dendrogram, including:
   - `cex = 0.8`: Controls the size of labels in the dendrogram.
   - `k = 4`: Specifies the number of colors to be used for dendrogram branches.
   - `rect = TRUE`: Displays rectangular boxes around the dendrogram branches.
   - `k_colors = "jco"`: Uses the "jco" color palette for dendrogram branches.
   - `rect_border = "jco"`: Sets the border color of the rectangular boxes.
   - `rect_fill = TRUE`: Fills the rectangular boxes with colors.
   - `horiz = TRUE`: Displays the dendrogram in a horizontal orientation.
4. The `theme` function is used to customize the appearance of the dendrogram plot, setting various text sizes, font styles, legend position, and strip text.
5. Plot the global dendrogram using the `plot` function, displaying the customized dendrogram visualization.

**Output:**
![image](https://github.com/vatsal-jari/MicroFace.github.io/assets/85255019/57e53a17-1647-426d-b14a-e429f1ea18ee)



*******

### Assess the dominant parameters' variability over time

The presented code performs an analysis of the importance of various parameters in different weeks using a dataset related to microglia morphology. The code begins by calculating the importance of each column in each condition and then visualizes the top 20 parameters with the highest importance. The dataset is initially aggregated to obtain the average importance values, which are then transformed into long format for further analysis. The top 20 parameters are selected based on their importance values for each week, and a grouped bar plot is generated to depict their relative importance across the weeks.

```R
# Calculate the importance of each column in each condition
H_clust$importance <- aggregate(H_clust$scaled_df[, 4:50], by = list(Weeks = H_clust$scaled_df$Time_weeks), FUN = mean)

# Melt the data frame to long format
H_clust$importance_melted <- melt(H_clust$importance, id.vars = c("Weeks"), variable.name = "Parameter", value.name = "Importance")

# Group the melted data frame by weeks
H_clust$df_grouped <- H_clust$importance_melted %>% group_by(Weeks)

# Select the top 20 parameters with the highest importance for each week
H_clust$f_top20 <- H_clust$df_grouped %>% 
  slice_max(order_by = Importance, n = 20) %>%
  ungroup()

# Create a grouped bar plot for the top 20 parameters
H_clust$top20_parameter <- ggplot(H_clust$f_top20, aes(x = Importance, y = Parameter, fill = factor(Weeks))) + 
  geom_col() +
  facet_grid(~Weeks) +
  scale_fill_manual(values = company_colors) +
  labs(title = "Top 20 Parameters") +
  theme_bw() +
  labs(fill = "Time (Weeks)") +
  theme(
    plot.title = element_text(size = 24, hjust = 0.5, face = "bold"),
    axis.title.x = element_text(size = 22, face = "bold"),
    axis.title.y = element_text(size = 22, face = "bold"),
    axis.text.x = element_text(size = 17, face = "bold"),
    axis.text.y = element_text(size = 17, face = "bold"),
    legend.text = element_text(size = 16, face = "bold"),
    legend.title = element_text(size = 18, face = "bold"),
    legend.key.size = unit(1.5, "lines"),
    legend.position = "bottom",
    strip.text = element_text(size = 18, face = "bold")
  ) +
  xlab("Variation Value") +
  ylab("Parameter")

# Plot the top 20 parameters
plot(H_clust$top20_parameter)
```

1. Calculate the average importance of each column in each condition using the `aggregate` function. The importance values are aggregated by the "Time_weeks" column in the `H_clust$scaled_df` data frame.

2. Melt the aggregated data frame `H_clust$importance` to convert it to long format using the `melt` function from the `reshape2` package. This creates a new data frame `H_clust$importance_melted` with "Weeks", "Parameter", and "Importance" columns.

3. Group the melted data frame `H_clust$importance_melted` by weeks using the `group_by` function from the `dplyr` package.

4. Select the top 20 parameters with the highest importance for each week using the `slice_max` function from the `dplyr` package. The parameters are ordered by importance, and the top 20 rows are retained. The resulting data frame is stored in `H_clust$f_top20`.

5. Ungroup the grouped data frame `H_clust$f_top20` using the `ungroup` function from the `dplyr` package.

6. Create a grouped bar plot `H_clust$top20_parameter` using `ggplot2` to visualize the top 20 parameters. The importance values are represented on the x-axis, the parameter names on the y-axis, and the bars are filled with colors based on the weeks. The plot is facetted by weeks using `facet_grid`.

7. Customize the appearance of the plot using various theme settings, such as title size, axis titles, legend appearance, and strip text.

8. Label the x-axis as "Variation Value" and the y-axis as "Parameter" using `xlab` and `ylab`.

9. Plot the top 20 parameters using the `plot` function to display the grouped bar plot.

The code calculates the importance of each parameter in each week, selects the top 20 parameters, and plots them in a grouped bar chart to visualize their relative importance.


**Output:**
![image](https://github.com/vatsal-jari/MicroFace.github.io/assets/85255019/fe15ff0d-5f95-4983-978f-22da8d1d36fb)


*******

### Introducing Tanglegrams: Exploring the Relationships between Dendrograms in Microglia Analysis


The provided code performs a comparison of dendrograms for different timepoints in order to analyze the clustering patterns of microglia morphology close to and far away from the injury site during the acute phase. The code focuses on the timepoint "02" and divides the dataset into two subsets: "Close to Injury site - Acute" and "Far away from Injury site - Acute." Each subset is further processed by removing irrelevant columns and scaling the data. Hierarchical clustering is then applied to both subsets to generate dendrograms representing the clustering structure. The dendrograms are visualized separately, and a tanglegram is created to compare the branching patterns between the two dendrograms. The tanglegram allows for the identification of common branches and differences in clustering between microglia close to and far away from the injury site. Finally, the code evaluates the equality of the tanglegram values. This analysis provides insights into the clustering relationships and differences in microglia morphology based on their proximity to the injury site during the acute phase.

```R


# Create a list called dend_comp
dend_comp <- list()

# Create an empty list to store the results
dend_comp$df_dend <- import$df_all_reordered_raw

# Select the data for timepoint "02"
dend_comp$df_0_dend <- dend_comp$df_dend[dend_comp$df_dend$Time_weeks == "02", ]

# Select the data close to the injury site
dend_comp$df_0_dend_close <- dend_comp$df_0_dend[which(dend_comp$df_0_dend$Bin_Number_New <= 3), ] 
dend_comp$df_0_dend_close <-  dend_comp$df_0_dend_close[,-1:-4]
dend_comp$df_0_dend_close <-  dend_comp$df_0_dend_close[,-38]

# Scale the data for clustering
dend_comp$df_0_dend_close_scale <- scale(dend_comp$df_0_dend_close) 

# Select the data far away from the injury site
dend_comp$df_0_dend_far <- dend_comp$df_0_dend[which(dend_comp$df_0_dend$Bin_Number_New >= 9), ]
dend_comp$df_0_dend_far <- dend_comp$df_0_dend_far[,-1:-4]
dend_comp$df_0_dend_far <- dend_comp$df_0_dend_far[,-38]

# Scale the data for clustering
dend_comp$df_0_dend_far_scale <- scale(dend_comp$df_0_dend_far)

# Generate dendrogram for the data close to the injury site
dend_comp$scale_cluster_cols <- hclust(dist(t(dend_comp$df_0_dend_close_scale)))

# Define a function to sort the dendrogram
dend_comp$sort_hclust <- function(...) as.hclust(dendsort(as.dendrogram(...)))

# Sort the dendrogram
dend_comp$scale_cluster_cols <- dend_comp$sort_hclust(dend_comp$scale_cluster_cols)

# Plot the dendrogram for the data close to the injury site
plot(dend_comp$scale_cluster_cols, main = "Close to Injury site - Acute", xlab = "", sub = "")

# Generate dendrogram for the data far away from the injury site
dend_comp$scale_cluster_cols_far <- hclust(dist(t(dend_comp$df_0_dend_far_scale)))

# Sort the dendrogram
dend_comp$scale_cluster_cols_far <- dend_comp$sort_hclust(dend_comp$scale_cluster_cols_far)

# Plot the dendrogram for the data far away from the injury site
plot(dend_comp$scale_cluster_cols_far, main = "Far away from Injury site - Acute", xlab = "", sub = "")

# Generate a tanglegram to compare the two dendrograms
tanglegram(dend_comp$scale_cluster_cols, dend_comp$scale_cluster_cols_far,
           highlight_distinct_edges = FALSE, # Turn off dashed lines
           common_subtrees_color_branches = TRUE # Color common branches
) %>%
  untangle(method = "step1side") %>%
  entanglement()

# Check the equality of the tanglegram values
dend_comp$tanglegram_values <- all.equal(dend_comp$scale_cluster_cols, dend_comp$scale_cluster_cols_far)

# View the tanglegram values
view(dend_comp$tanglegram_values)
```
1. The code initializes an empty list called `dend_comp` to store the results of the dendrogram comparison.

2. The section titled "DENDOGRAMS FOR DIFFERENT TIMEPOINTS" indicates specific time points and their corresponding bin numbers for further analysis.

3. The dendrogram data from `import$df_all_reordered_raw` is assigned to `dend_comp$df_dend`.

4. The data for a specific time point (timepoint "02") is extracted and stored in `dend_comp$df_0_dend`.

5. The data close to the injury site (bin numbers <= 3) is selected and assigned to `dend_comp$df_0_dend_close`. Irrelevant columns are removed from the dataframe.

6. The selected data is scaled using the `scale()` function, resulting in `dend_comp$df_0_dend_close_scale`.

7. Similarly, the data far away from the injury site (bin numbers >= 9) is selected and assigned to `dend_comp$df_0_dend_far`. Irrelevant columns are removed.

8. The selected data is scaled using `scale()`, resulting in `dend_comp$df_0_dend_far_scale`.

9. The dendrogram for the data close to the injury site is generated using `hclust()` and stored in `dend_comp$scale_cluster_cols`.

10. The `sort_hclust()` function is defined to sort the dendrogram based on its structure.

11. The dendrogram is sorted using `dend_comp$sort_hclust()` and reassigned to `dend_comp$scale_cluster_cols`.

12. The sorted dendrogram for the data close to the injury site is plotted using `plot()`. The title is set as "Close to Injury site - Acute", and the x-axis label is left empty.

13. Similarly, the dendrogram for the data far away from the injury site is generated using `hclust()` and stored in `dend_comp$scale_cluster_cols_far`.

14. The dendrogram is sorted using `dend_comp$sort_hclust()` and reassigned to `dend_comp$scale_cluster_cols_far`.

15. The sorted dendrogram for the data far away from the injury site is plotted using `plot()`. The title is set as "Far away from Injury site - Acute", and the x-axis label is left empty.

16. A tanglegram is created using `tanglegram()` to compare the two dendrograms. The `highlight_distinct_edges` parameter is set to `FALSE` to turn off dashed lines, and `common_subtrees_color_branches` is set to `TRUE` to color common branches.

17. The resulting tanglegram is untangled using `untangle()` with the "step1side" method.

18. The untangled tanglegram is displayed using `entanglement()`.

19. The equality of the tanglegram values is checked using `all.equal()`, and the result is stored in `dend_comp$tanglegram_values`.

20. The tanglegram values are viewed using `view()` to analyze any differences between the two dendrograms.


**Output:**
![image](https://github.com/vatsal-jari/MicroFace.github.io/assets/85255019/42ef3926-603f-4a57-8297-f531d6b9dd67)


*******

### Single-cell morphometry analysis

This code performs a Principal Component Analysis (PCA) on the clustered cells. It extracts the relevant columns for the analysis and determines the optimal number of clusters using PCA and eigenvalues. The code then performs k-means clustering based on the optimal number of clusters and assigns cluster labels to the data. PCA is performed on the data, and the top contributing variables in PC1 and PC2 are visualized. The code also plots the top contributing variables for each component and generates a scatter plot of PC1 and PC2, highlighting the clusters using different colors. The resulting plot provides insights into the major morpho-families of microglia based on their PCA scores.

Certainly! Here are the comments added to the code:

```R
PCA <- list()

##### PCA PLOT FOR CLUSTERED CELLS ALL #####

# Create a new list object to store the PCA results
PCA$df_pca <- import$df_all_reordered[, colnames(import$df_all_reordered)[c(35:82, 5, 6, 25, 29:32)]]

# Perform PCA on the selected columns for the optimal number of clusters determination
PCA$check_number_of_cluster <- prcomp(PCA$df_pca[,1:48], scale = TRUE)
df <- scale(PCA$df_pca[,1:48])

# Visualize the eigenvalues to determine the optimal number of clusters
fviz_eig(PCA$check_number_of_cluster, addlabels = TRUE, xlab = "Number of Cluster (K)", ylim = c(0, 50)) +
  theme_bw() +
  theme(...)

# Perform k-means clustering based on the optimal number of clusters (4 in this case)
PCA$kmeans_all <- kmeans(PCA$df_pca[,1:48], centers = 4, nstart = 25)
PCA$kmeans_all

# Assign the cluster labels to the data
PCA$df_pca$Cluster <- PCA$kmeans_all$cluster

## PCA starts here

# Create a recipe for PCA analysis with specified roles for variables
PCA$pca_rec <- recipe(~., data = PCA$df_pca) %>%
  update_role( Time_weeks, Bin_Number_New,  Center_X_cell, Center_Y_cell, 
               Cluster, Condition_cell, ImageNumber_cell, Electrode_Thickness, new_role = "id") %>%
  step_normalize(all_predictors()) %>%
  step_pca(all_predictors())

# Prepare the data for PCA analysis
PCA$pca_prep <- prep(PCA$pca_rec)
PCA$pca_prep

# Tidy the PCA results for visualization
PCA$tidied_pca <- tidy(PCA$pca_prep, 2)

# Plot the top contributing variables in PC1 and PC2
PCA$tidied_pca %>%
  filter(component %in% paste0("PC", 1:2)) %>%
  mutate(component = fct_inorder(component)) %>%
  ggplot(aes(value, terms, fill = terms)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~component, nrow = 1) +
  labs(y = NULL)


```
Certainly! Here's a revised point-by-point explanation, highlighting code objects:

1. Create an empty list object called `PCA` to store the PCA results.

2. Select specific columns from the `import$df_all_reordered` dataset to be used for PCA. These columns correspond to variables related to the morphology of microglia cells and additional variables of interest.

3. Perform PCA on the selected columns to determine the optimal number of clusters. This is done by applying the `prcomp` function to the data, with the `scale` parameter set to `TRUE` to standardize the variables.

4. Scale the selected columns using the `scale` function and store the result in the variable `df`. Scaling standardizes the variables to have zero mean and unit variance.

5. Visualize the eigenvalues of the principal components to assess the optimal number of clusters. The `fviz_eig` function is used to create a plot of the eigenvalues, with labels added and the x-axis labeled as "Number of Cluster (K)". The y-axis limit is set between 0 and 50. The appearance of the plot is customized using the `theme` function.

6. Perform k-means clustering on the selected columns using the optimal number of clusters determined from the PCA analysis. In this case, k-means clustering is performed with 4 clusters, and the `nstart` parameter is set to 25 to increase the chances of finding the optimal clustering.

7. Print the resulting k-means clustering object to the console. This provides information about the clusters, including cluster centers, sizes, and within-cluster sum of squares.

8. Assign the cluster labels obtained from k-means clustering to the `Cluster` column of the `PCA$df_pca` dataset.

9. Create a recipe for PCA analysis using the `recipe` function from the `recipes` package. The formula `~.` specifies that all variables in the dataset should be used for PCA.

10. Update the roles of specific variables in the recipe. The variables `Time_weeks`, `Bin_Number_New`, `Center_X_cell`, `Center_Y_cell`, `Cluster`, `Condition_cell`, `ImageNumber_cell`, and `Electrode_Thickness` are assigned the role of "id", which means they will not be used in the PCA calculation.

11. Normalize all predictor variables in the recipe using the `step_normalize` function. This standardizes the predictor variables to have zero mean and unit variance.

12. Apply the PCA transformation to the normalized predictors using the `step_pca` function.

13. Prepare the data for PCA analysis by applying the recipe using the `prep` function. This applies the specified transformations to the data.

14. Store the preprocessed data in the variable `PCA$pca_prep`.

15. Tidy the PCA results obtained from the preprocessed data using the `tidy` function. The `2` parameter indicates that only the first two components should be included in the tidy result.

16. Filter the tidied PCA results to include only the components "PC1" and "PC2".

17. Reorder the levels of the `component` variable to ensure proper ordering in the visualization.

18. Create a bar plot to visualize the top contributing variables in PC1 and PC2. This is done using the `ggplot` function and the `geom_col` function to create the bar plot.


**Output:**
![image](https://github.com/vatsal-jari/MicroFace.github.io/assets/85255019/ed18e04d-b0dd-43a6-a46a-95ec61506d81)


```

# Select the top contributing variables for each component and plot them
# Filter the tidied PCA data to include only components PC1 and PC2
PCA$tidied_pca %>%
  filter(component %in% paste0("PC", 1:2)) %>%
  
  # Group the filtered data by component
  group_by(component) %>%
  
  # Select the top 15 variables with highest absolute values of value within each component
  top_n(15, abs(value)) %>%
  
  # Ungroup the data
  ungroup() %>%
  
  # Reorder terms within each component based on absolute values of value
  mutate(terms = reorder_within(terms, abs(value), component)) %>%
  
  # Create a bar plot
  ggplot(aes(abs(value), terms, fill = value > 0)) +
  
  # Add columns using geom_col
  geom_col() +
  
  # Facet the plot by component
  facet_wrap(~component, scales = "free_y") +
  
  # Reorder y-axis based on absolute values of value
  scale_y_reordered() +
  
  # Set x-axis label and remove y-axis label
  labs(x = "Absolute value of contribution", y = NULL, fill = "Positive?")



# Visualize the PCA results with scatter plot of PC1 and PC2

# Extract the PCA coordinates from pca_prep using the juice function
juice(PCA$pca_prep) %>%
  
  # Create a scatter plot
  ggplot(aes(PC1, PC2, label = NA)) +
  
  # Add points to the plot with color mapped to Cluster variable
  geom_point(aes(color = as.factor(Cluster)), alpha = 0.7, size = 2) +
  
  # Add text labels to the plot with inward alignment and IBMPlexSans font
  geom_text(check_overlap = TRUE, hjust = "inward", family = "IBMPlexSans") +
  
  # Remove the color legend
  labs(color = NULL) +
  
  # Apply a viridis color scale to the points
  scale_color_viridis_d() +
  
  # Set the theme to classic
  theme_classic() +
  
  # Set the plot title and customize visual elements using the theme function
  ggtitle("Major morpho-families of microglia") +
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

```

1. Filter the `PCA$tidied_pca` data to include only the components "PC1" and "PC2".

2. Group the filtered data by the `component` variable.

3. Select the top 15 variables with the highest absolute values of `value` within each component.

4. Ungroup the data to remove the grouping.

5. Mutate the `terms` variable to reorder it within each component based on the absolute values of `value`. This ensures proper ordering in the visualization.

6. Create a bar plot using the `ggplot` function. The absolute values of `value` are mapped to the x-axis (`abs(value)`), the `terms` are mapped to the y-axis, and the fill color is determined by whether the value is greater than 0 (`value > 0`).

7. Facet the plot by the `component` variable, resulting in separate plots for "PC1" and "PC2". The `scales` parameter is set to "free_y" to allow independent y-axis scales for each facet.

8. Reorder the y-axis based on the absolute values of `value` using the `scale_y_reordered` function.

9. Set the x-axis label as "Absolute value of contribution", the y-axis label as NULL, and the fill legend label as "Positive?".

10. Create a scatter plot using the `juice` function to extract the PCA coordinates from `PCA$pca_prep`. The `PC1` values are mapped to the x-axis (`PC1`), and the `PC2` values are mapped to the y-axis (`PC2`). The `label` parameter is set to NA to hide the point labels.

11. Add points to the scatter plot using the `geom_point` function. The `color` aesthetic is mapped to the `Cluster` variable, which is converted to a factor. The `alpha` parameter sets the transparency of the points, and the `size` parameter controls their size.

12. Add text labels to the scatter plot using the `geom_text` function. The `check_overlap` parameter is set to TRUE to avoid overlapping labels. The `hjust` parameter is set to "inward" to align the labels towards the center of the plot. The `family` parameter specifies the font family of the text.

13. Remove the color legend from the plot by setting `color = NULL` in the `labs` function.

14. Apply a viridis color palette to the points using the `scale_color_viridis_d` function.

15. Set the theme of the plot to "classic" using the `theme_classic` function.

16. Set the plot title as "Major morpho-families of microglia" and customize the appearance of the plot title, axis labels, axis text, legend text, and other visual elements using the `theme` function.


**Output:**
![major morpho](https://github.com/vatsal-jari/MicroFace.github.io/assets/85255019/228b21b2-ac09-43da-9107-7a788a70d4d4)

Using the same approach as described above, we further subdivided the four main morpho types into sub-types, resulting in a total of 14 distinct classes of morphology. PCA analysis was employed to perform the sub-clustering, following a similar code methodology. The sub-clusters are shown below. 

**Output:**
![Untitled (19)](https://github.com/vatsal-jari/MicroFace.github.io/assets/85255019/25004d2d-44aa-4e78-97c8-cad0a4c33137)



*******



### Definign the morphology of each morpho-types 

A thorough analysis was conducted by determining the X and Y coordinates of multiple cells from each of the 14 morpho types. Subsequently, these coordinates were utilized to trace back to the original images in order to assess the actual morphology of the selected cells. A meticulous examination of 15-20 cells from each morpho type was performed, and it was observed that the classification of morphology effectively portrayed the unique characteristics associated with each respective morpho type, as illustrated in the diagram below. Through this validation process, the reliability and accuracy of our morphological classification were substantiated.


![Untitled (20)](https://github.com/vatsal-jari/MicroFace.github.io/assets/85255019/ed06552e-f123-42db-bc1b-51037b56493a)

The morphology represented by each morpho type from the dataset was interpreted as follows:

1. Ameboid: This morpho type exhibited a rounded and amoeba-like shape, typically associated with phagocytic activity and inflammation in damaged or diseased brain tissue.

2. Highly Ramified: The highly ramified morpho type displayed an intricate and extensively branched structure, indicative of its involvement in synaptic pruning and neuroprotection in healthy brain tissue.

3. Transition: The transition morpho type had an intermediate morphology, suggesting its ability to switch between ameboid and highly ramified states depending on the microenvironment. These cells may play a role in adaptive responses and transitioning between different functional states.

4. Rod-like: The rod-like morpho type was characterized by an elongated shape, commonly found in white matter tracts. These cells are believed to be involved in myelin maintenance and provide structural support in the brain.

Each of these morpho types represents a distinct phenotype of microglia, reflecting their specialized functions and roles in the central nervous system.


*******

### Spatial distribution of morpho types 

This code snippet is part of a larger analysis that involves clustering and categorizing data. The code focuses on creating a list called `Morpho` and populating it with different dataframes derived from a previous step involving principal component analysis (PCA). 


```R
Morpho <- list()

# Assign the Clust1, Clust2, Clust3, Clust4 dataframes from PCA to Morpho list
Morpho$df_clust1 <- PCA$Clust1
Morpho$df_clust2 <- PCA$Clust2
Morpho$df_clust3 <- PCA$Clust3
Morpho$df_clust4 <- PCA$Clust4

# Rename Cluster_2 in df_clust2 as Cluster_1
names(Morpho$df_clust2)[names(Morpho$df_clust2) == 'Cluster_2'] <- 'Cluster_1'

# Rename Cluster_3 in df_clust3 as Cluster_1
names(Morpho$df_clust3)[names(Morpho$df_clust3) == 'Cluster_3'] <- 'Cluster_1'

# Rename Cluster_4 in df_clust4 as Cluster_1
names(Morpho$df_clust4)[names(Morpho$df_clust4) == 'Cluster_4'] <- 'Cluster_1'

# Merge the four cluster dataframes into a single dataframe
Morpho$df_clust_all <- bind_rows(Morpho$df_clust1, Morpho$df_clust2, Morpho$df_clust3, Morpho$df_clust4)

# Create a new column 'Morpho' based on conditions using case_when
Morpho$df_clust_all$Morpho <- case_when(
  Morpho$df_clust_all$Cluster == 1 & Morpho$df_clust_all$Cluster_1 == 1 ~ "M01",
  Morpho$df_clust_all$Cluster == 1 & Morpho$df_clust_all$Cluster_1 == 2 ~ "M02",
  Morpho$df_clust_all$Cluster == 1 & Morpho$df_clust_all$Cluster_1 == 3 ~ "M03",
  Morpho$df_clust_all$Cluster == 1 & Morpho$df_clust_all$Cluster_1 == 4 ~ "M04",
  Morpho$df_clust_all$Cluster == 2 & Morpho$df_clust_all$Cluster_1 == 1 ~ "M05",
  Morpho$df_clust_all$Cluster == 2 & Morpho$df_clust_all$Cluster_1 == 2 ~ "M06",
  Morpho$df_clust_all$Cluster == 2 & Morpho$df_clust_all$Cluster_1 == 3 ~ "M07",
  Morpho$df_clust_all$Cluster == 3 & Morpho$df_clust_all$Cluster_1 == 1 ~ "M08",
  Morpho$df_clust_all$Cluster == 3 & Morpho$df_clust_all$Cluster_1 == 2 ~ "M09",
  Morpho$df_clust_all$Cluster == 3 & Morpho$df_clust_all$Cluster_1 == 3 ~ "M10",
  Morpho$df_clust_all$Cluster == 3 & Morpho$df_clust_all$Cluster_1 == 4 ~ "M11",
  Morpho$df_clust_all$Cluster == 4 & Morpho$df_clust_all$Cluster_1 == 1 ~ "M12",
  Morpho$df_clust_all$Cluster == 4 & Morpho$df_clust_all$Cluster_1 == 2 ~ "M13",
  Morpho$df_clust_all$Cluster == 4 & Morpho$df_clust_all$Cluster_1 == 3 ~ "M14"
)
```
1. The `Morpho` list is initialized using `Morpho <- list()`.

2. Four dataframes named `df_clust1`, `df_clust2`, `df_clust3`, and `df_clust4` are assigned from the `PCA` object to the corresponding elements of the `Morpho` list.

3. Some column names in `df_clust2`, `df_clust3`, and `df_clust4` are renamed to match the column names in `df_clust1`. This is done to ensure consistency in the column names across the dataframes.

4. The four dataframes (`df_clust1`, `df_clust2`, `df_clust3`, and `df_clust4`) are merged together into a single dataframe called `df_clust_all` using the `bind_rows()` function.

5. A new column called `Morpho` is added to `df_clust_all` based on specific conditions using the `case_when()` function. The values in the `Morpho` column are assigned based on the combinations of values in the `Cluster` and `Cluster_1` columns.


*******

The code segment focuses on generating and visualizing a morpho-type frequency heatmap. It begins by extracting relevant columns from a data frame and filtering the data based on a specific condition. The filtered data is then transformed into a table and scaled. Next, the code defines a function to determine breaks for the heatmap colors based on quantiles. The heatmap is plotted using the scaled data, with customized color mapping and breaks. The code also performs hierarchical clustering on the columns and rows of the heatmap data, allowing for sorting and creating dendrograms. Finally, another heatmap is generated with sorted columns and rows, using a different color scheme and clustering. The resulting heatmaps provide insights into the frequency and patterns of morpho-types.

```R
Morpho <- list()

# Assign the desired columns from df_clust_all to df_Morpho_count dataframe
Morpho$df_Morpho_count <- Morpho$df_clust_all[, c(51, 58)]

# Filter df_Morpho_count to include only rows where Bin_Number_New is less than or equal to 16
Morpho$df_Morpho_count <- Morpho$df_Morpho_count[which(Morpho$df_Morpho_count$Bin_Number_New <= 16), ]

# Create a table from df_Morpho_count
Morpho$df_Morpho_count.t <- table(Morpho$df_Morpho_count)

# Scale the table data using the scale function
Morpho$df_Morpho_count_scale.t <- scale(Morpho$df_Morpho_count.t)

# Define a function quantile_breaks to calculate breaks based on quantiles
Morpho$quantile_breaks <- function(xs, n = 16) {
  breaks <- quantile(xs, probs = seq(0, 1, length.out = n))
  breaks[!duplicated(breaks)]
}

# Apply the quantile_breaks function to df_Morpho_count_scale.t and store the breaks in mat_breaks
Morpho$mat_breaks <- Morpho$quantile_breaks(Morpho$df_Morpho_count_scale.t, n = 16)


## SORTING

# Perform hierarchical clustering on the transpose of df_Morpho_count_scale.t and store the result in morpho_hm_col
Morpho$morpho_hm_col <- hclust(dist(t(Morpho$df_Morpho_count_scale.t)))

# Plot the unsorted dendrogram
plot(Morpho$morpho_hm_col, main = "Unsorted Dendrogram", xlab = "", sub = "")

# Define a sorting function, sort_hclust, that applies dendrogram sorting
Morpho$sort_hclust <- function(...) as.hclust(dendsort(as.dendrogram(...)))

# Sort morpho_hm_col using the sort_hclust function
Morpho$morpho_hm_col <- Morpho$sort_hclust(Morpho$morpho_hm_col)

# Plot the sorted dendrogram
plot(morpho_hm_col, main = "Sorted Dendrogram", xlab = "", sub = "")

# Perform hierarchical clustering on df_Morpho_count_scale.t and store the result in morpho_hm_row
Morpho$morpho_hm_row <- Morpho$sort_hclust(hclust(dist(Morpho$df_Morpho_count_scale.t)))

# Create a heatmap with sorted rows and columns
pheatmap(Morpho$df_Morpho_count_scale.t,
         color = viridis(length(Morpho$mat_breaks) - 2),
         breaks = Morpho$mat_breaks,
         cutree_cols = 1,
         cutree_rows = 4,
         cluster_cols = Morpho$morpho_hm_col,
         cluster_rows = FALSE,
         fontsize = 14,
         Rowv = FALSE,
         main = "Morpho-type Frequency Heatmap Overview")
```

1. `Morpho$df_Morpho_count` is created as a subset of `Morpho$df_clust_all`, containing only columns 51 and 58.

2. Rows in `Morpho$df_Morpho_count` where the value in the column `Bin_Number_New` is less than or equal to 16 are retained using the `which()` function.

3. The table of counts `Morpho$df_Morpho_count.t` is created based on `Morpho$df_Morpho_count`.

4. The count matrix `Morpho$df_Morpho_count.t` is scaled using the `scale()` function and assigned to `Morpho$df_Morpho_count_scale.t`.

5. The `Morpho$quantile_breaks()` function is defined to calculate breaks for the heatmap based on quantiles.

6. `Morpho$mat_breaks` is created by applying `Morpho$quantile_breaks()` to `Morpho$df_Morpho_count_scale.t`, specifying the number of breaks as 16.

7. The heatmap is generated using `pheatmap()` with the scaled count matrix `Morpho$df_Morpho_count_scale.t`. It uses the color palette "inferno" in reverse order (`rev(inferno(length(Morpho$mat_breaks) - 1))`), applies the breaks defined in `Morpho$mat_breaks`, and sets the number of clusters for both columns and rows (`cutree_cols = 4, cutree_rows = 5`).

8. The unsorted dendrogram for column clustering (`morpho_hm_col`) is plotted using `plot()`.

9. The `Morpho$sort_hclust()` function is defined, which performs hierarchical clustering and sorting of a dendrogram.

10. The `Morpho$morpho_hm_col` dendrogram is sorted using `Morpho$sort_hclust()`.

11. The sorted dendrogram for column clustering (`morpho_hm_col`) is plotted.

12. The dendrogram for row clustering (`morpho_hm_row`) is generated by sorting the dendrogram of the distance matrix of `Morpho$df_Morpho_count_scale.t`.

13. Another heatmap is created using `pheatmap()`, similar to the previous one, but with additional options. The column clustering is specified as `Morpho$morpho_hm_col`, row clustering is disabled (`cluster_rows = FALSE`), and the color palette is set to "viridis" with a length equal to the number of breaks minus 2 (`viridis(length(Morpho$mat_breaks)-2)`).

The code performs clustering, sorting, and visualization steps to generate a frequency heatmap of morpho-types. It helps in identifying patterns and relationships among different morpho-types based on their frequencies.

![image](https://github.com/vatsal-jari/MicroFace.github.io/assets/85255019/b6e247f4-0c61-4cf9-8c53-081023c0f16f)




