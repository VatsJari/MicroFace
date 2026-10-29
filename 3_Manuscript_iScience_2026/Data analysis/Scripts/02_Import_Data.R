# ============================================================================
# Data Import and Preprocessing Script for Microglial Morphology Analysis
# ============================================================================
# This script imports soma and cell morphology text files, merges them,
# adds metadata (condition, injury coordinates), computes derived metrics,
# and organizes everything into a single list object 'import'.
# ============================================================================

# Initialize list to store all data and intermediate objects
import <- list()


##### 1. SET FILE PATHS FOR SOMA AND CELL DATA FOLDERS #####
# Copy the path of the folder that contains all the text files

import$folder_path_soma <- "/Users/vatsaljariwala/Documents/Brain Injury project/Revised_Submission/Datasheet/df_soma"
import$folder_path_cell <- "/Users/vatsaljariwala/Documents/Brain Injury project/Revised_Submission/Datasheet/df_cell"


##### 2. STORE ALL FILE NAMES INTO LISTS #####

import$list_of_files_soma <- list.files(path = import$folder_path_soma,
                                        recursive = TRUE,
                                        pattern = "*.txt",
                                        full.names = TRUE)
import$list_of_files_cell <- list.files(path = import$folder_path_cell,
                                        recursive = TRUE,
                                        pattern = "*.txt",
                                        full.names = TRUE)


##### 3. MERGE ALL FILES INTO ONE BIG DATAFRAME, ADD FILENAME COLUMN #####

import$df_soma <- vroom::vroom(import$list_of_files_soma, id = "FileName")
import$df_cell <- vroom::vroom(import$list_of_files_cell, id = "FileName")


##### 4. CREATE A NEW COLUMN "Condition" FROM FILENAME #####
# Extract condition (probesize_timepoint) from the file path

import$df_soma <- import$df_soma %>%
  mutate(Condition = str_remove(FileName, pattern = import$folder_path_soma)) %>%
  mutate(Condition = str_remove(Condition, pattern = ".txt")) %>%
  mutate(Condition = str_remove(Condition, pattern = "/"))

import$df_cell <- import$df_cell %>%
  mutate(Condition = str_remove(FileName, pattern = import$folder_path_cell)) %>%
  mutate(Condition = str_remove(Condition, pattern = ".txt")) %>%
  mutate(Condition = str_remove(Condition, pattern = "/"))


##### 5. DELETE THE FILENAME COLUMN (NO LONGER NEEDED) #####

import$df_soma <- subset(import$df_soma, select = -c(FileName))
import$df_cell <- subset(import$df_cell, select = -c(FileName))


##### 6. RENAME COLUMNS: REMOVE "AreaShape_" PREFIX AND ADD "_soma"/"_cell" SUFFIX #####

colnames(import$df_soma) <- gsub("AreaShape_", "", colnames(import$df_soma)) %>%
  paste("soma", sep = "_")
colnames(import$df_cell) <- gsub("AreaShape_", "", colnames(import$df_cell)) %>%
  paste("cell", sep = "_")


##### 7. MERGE SOMA AND CELL DATAFRAMES INTO ONE MASTER DATAFRAME #####
# Merge based on ImageNumber, Parent_Soma, and Condition

import$df_all <- merge(import$df_cell, import$df_soma,
                       by.x = c('FileName_Original_Iba1_cell','ImageNumber_cell', 'Parent_Soma_Merged_cell', 'Condition_cell'),
                       by.y = c('FileName_Original_Iba1_soma','ImageNumber_soma', 'Parent_Soma_Merged_soma', 'Condition_soma'))

# Check column names after merge
colnames(import$df_all)


##### 8. REMOVE UNWANTED COLUMNS FROM THE FINAL DATASET #####

import$df_all <- subset(import$df_all,
                        select = -c(Location_Center_X_soma, Location_Center_Z_soma,
                                    Location_Center_Y_soma, Location_Center_X_cell,
                                    Location_Center_Z_cell, Location_Center_Y_cell,
                                    Children_Cell_Count_soma))

colnames(import$df_all)


##### 9. IMPORT THE INJURY COORDINATES DATASHEET #####

import$Injury_center <- read_csv("/Users/vatsaljariwala/Documents/Brain Injury project/Revised_Submission/Datasheet/Injury_Center/coordinates.csv")


##### 10. ADD INJURY X & Y COORDINATES TO THE MAIN DATA SHEET #####

import$df_all <- merge(import$df_all, import$Injury_center,
                       by.x = c("FileName_Original_Iba1_cell"),
                       by.y = c("Image"),
                       all.x = TRUE)

colnames(import$df_all)


##### 11. EXTRACT METADATA FROM FILENAME INTO SEPARATE COLUMNS #####

# Create temporary column names for splitting
import$colmn <- paste('Electrode_Thickness', 1:6)

import$df_all <- tidyr::separate(
  data = import$df_all,
  col = FileName_Original_Iba1_cell,
  sep = "_",
  into = import$colmn,
  remove = FALSE)

# Rename extracted columns to meaningful names
names(import$df_all)[names(import$df_all) == 'Electrode_Thickness 6'] <- 'Bagsub'
names(import$df_all)[names(import$df_all) == 'Electrode_Thickness 5'] <- 'SubImage'
names(import$df_all)[names(import$df_all) == 'Electrode_Thickness 4'] <- 'Staining'
names(import$df_all)[names(import$df_all) == 'Electrode_Thickness 3'] <- 'Electrode_Thickness'
names(import$df_all)[names(import$df_all) == 'Electrode_Thickness 2'] <- 'Time_weeks'
names(import$df_all)[names(import$df_all) == 'Electrode_Thickness 1'] <- 'Animal_No'

# Rename some morphology columns for easier reference
names(import$df_all)[names(import$df_all) == 'ObjectSkeleton_NumberBranchEnds_MorphologicalSkeleton_soma'] <- 'Branch_Ends'
names(import$df_all)[names(import$df_all) == 'ObjectSkeleton_NumberNonTrunkBranches_MorphologicalSkeleton_soma'] <- 'Non_Trunk_Branch'
names(import$df_all)[names(import$df_all) == 'ObjectSkeleton_NumberTrunks_MorphologicalSkeleton_soma'] <- 'Trunk_Branch'
names(import$df_all)[names(import$df_all) == 'ObjectSkeleton_TotalObjectSkeletonLength_MorphologicalSkeleton_soma'] <- 'Skeleton_Length'
names(import$df_all)[names(import$df_all) == 'X'] <- 'Injury_x'
names(import$df_all)[names(import$df_all) == 'Y'] <- 'Injury_y'

# Standardize time point labels
import$df_all$Time_weeks <- case_when(
  import$df_all$Time_weeks == "14dpi" ~ "02WPI",
  import$df_all$Time_weeks == "2wpi"  ~ "02WPI",
  import$df_all$Time_weeks == "5dpi"  ~ "01WPI",
  import$df_all$Time_weeks == "4hpi"  ~ "00WPI",
  import$df_all$Time_weeks == "8wpi"  ~ "08WPI",
  import$df_all$Time_weeks == "18wpi" ~ "18WPI"
)


##### 12. EXPORT THE DATASHEET AS A .CSV FILE (OPTIONAL, COMMENTED OUT) #####

# write_xlsx(import$df_all, "/Volumes/JARI-NES/Extra/df_all.xlsx")

colnames(import$df_all)


##### 13. CALCULATE RADIAL DISTANCE FROM INJURY CENTER AND BIN CELLS #####

# Euclidean distance from injury center (coordinates 2764, 2196 used implicitly via Injury_x, Injury_y)
import$df_all$radial_dist <- sqrt((import$df_all$Center_X_soma - import$df_all$Injury_x)^2 +
                                    (import$df_all$Center_Y_soma - import$df_all$Injury_y)^2)

# Divide into 25 bins based on distance
import$df_all$bin_number <- ntile(import$df_all$radial_dist, 25)
import$df_all$bin_range <- import$df_all$bin_number * 139

# Collapse bins >16 into bin 17
import$df_all$Bin_Number_New <- import$df_all$bin_number
import$df_all$Bin_Number_New[import$df_all$bin_number > 16] <- 17
import$df_all$bin_range_new <- import$df_all$Bin_Number_New * 139


##### 14. COMPUTE MORPHOLOGY METRICS #####

# Ramification Index (RI)
import$df_all$RI <- ((import$df_all$Perimeter_cell / import$df_all$Area_cell) /
                       (2 * sqrt(pi / import$df_all$Area_cell)))

# Area ratio of cell to soma
import$df_all$area_ratio <- import$df_all$Area_cell / import$df_all$Area_soma

# Length-to-width ratio (rod-like morphology) for cell and soma
import$df_all$Length_Width_Ratio_cell <- import$df_all$MaxFeretDiameter_cell / import$df_all$MinFeretDiameter_cell
import$df_all$Length_Width_Ratio_soma <- import$df_all$MaxFeretDiameter_soma / import$df_all$MinFeretDiameter_soma

# Aspect ratio (major/minor axis) for cell and soma
import$df_all$Aspect_Ratio_cell <- import$df_all$MajorAxisLength_cell / import$df_all$MinorAxisLength_cell
import$df_all$Aspect_Ratio_soma <- import$df_all$MajorAxisLength_soma / import$df_all$MinorAxisLength_soma

# Total number of branches (non-trunk + trunk)
import$df_all$Total_Branch <- import$df_all$Non_Trunk_Branch + import$df_all$Trunk_Branch

# Cytoplasmic area
import$df_all$Cyto_Area <- import$df_all$Area_cell - import$df_all$Area_soma


##### 15. CLASSIFY CELLS INTO IMPACT REGIONS BASED ON BINS #####

import$df_all$Impact_Region <- case_when(
  import$df_all$Bin_Number_New <= 6               ~ "Close",
  import$df_all$Bin_Number_New > 10                ~ "Far",
  import$df_all$Bin_Number_New > 6 & import$df_all$Bin_Number_New <= 10 ~ "Middle",
  TRUE ~ as.character(import$df_all$Bin_Number_New)
)


##### 16. COMPUTE HEALTH SCORE (0-1) BASED ON TOTAL BRANCHES #####
# Health score formula: if branches >=20, score = 1; else score decreases linearly.

import$df_all$Health_score <- case_when(
  import$df_all$Total_Branch >= 20 ~ 1,
  import$df_all$Total_Branch <= 19 ~ (1 - (((20 - import$df_all$Total_Branch) / 2)) / 10)
)


##### 17. DEFINE COLOR PALLETTES FOR PLOTTING (STORED IN IMPORT LIST) #####

company_colors <- c("#E50000", "#008A8A", "#AF0076", "#E56800", "#1717A0",
                           "#E5AC00", "#00B700")

company_colors2 <- c("#E50000", "#0080FF", "#E56800", "#AF0076", "#1717A0")

morpho_colours <- c("#FF0000", "#00FF00", "#0000FF", "#FFFF00", "#FF00FF", "#00FFFF",
                           "#FF8000", "#8000FF", "#00FF80", "#FF0080", "#0080FF", "#80FF00",
                           "#800000", "#008000")


##### 18. REORDER COLUMNS: MOVE UNNECESSARY ONES TO THE FRONT (OPTIONAL) #####
# The original code uses subset to drop many columns. We'll keep it as is.

colnames(import$df_all)
import$df_all <- subset(import$df_all,
                        select = -c(Staining, Bagsub, Parent_Soma_Filtered_cell,
                                    ObjectNumber_cell, PathName_Original_Iba1_cell,
                                    BoundingBoxMaximum_X_cell, BoundingBoxMaximum_Y_cell,
                                    BoundingBoxMinimum_X_cell, BoundingBoxMinimum_Y_cell,
                                    EulerNumber_cell, Orientation_cell,PathName_Original_Iba1_cell,
                                    Number_Object_Number_cell, Parent_Soma_Merged_cell,
                                    ObjectNumber_soma,
                                    PathName_Original_Iba1_cell,PathName_Original_Iba1_soma,
                                    BoundingBoxMaximum_X_soma, BoundingBoxMaximum_Y_soma,
                                    BoundingBoxMinimum_X_soma, BoundingBoxMinimum_Y_soma,
                                    Center_X_cell, Center_Y_cell, EulerNumber_soma,
                                    Extent_soma, Orientation_soma, Number_Object_Number_soma))

# View final column names
colnames(import$df_all)


##### 19. CREATE A CLEANED DATAFRAME FOR PCA (REMOVE NAs, SELECT SPECIFIC COLUMNS) #####

import$df_all_PCA <- na.omit(import$df_all %>%
                               dplyr::select(c(1:6, 27, 28, 47:53, 62), everything()))

# Inspect PCA dataframe
colnames(import$df_all_PCA)
str(import$df_all_PCA)


# ============================================================================
# End of data import and preprocessing
# All objects are stored within the 'import' list.
# ============================================================================