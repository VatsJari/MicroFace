
import <- list()

##### COPY THE PATH OF FOLDER THAT CONTAINS ALL THE TEXT FILES #####

import$folder_path_soma = "/Volumes/JARI-NES/Brain Injury project/4 Datasheet/Datasheet_all_soma/"
import$folder_path_cell = "/Volumes/JARI-NES/Brain Injury project/4 Datasheet/Datasheet_all_cell/"


# STORE ALL THE FILE NAMES INTO ON OBJECT = LIST_OF_ALL_FILES_SOMA

import$list_of_files_soma <- list.files(path = import$folder_path_soma , recursive = TRUE,
                            pattern = "*.txt", full.names = TRUE)
import$list_of_files_cell <- list.files(path = import$folder_path_cell , recursive = TRUE,
                                 pattern = "*.txt", full.names = TRUE)  



##### MERGE ALL THEFILES INTO ONE BIG DATAFRAME. ALSO ADDING FILENAME TO A NEW COLOUM #####

import$df_soma <- vroom(import$list_of_files_soma, id = "FileName")
import$df_cell <- vroom(import$list_of_files_cell, id = "FileName")



##### CREATE A NEW COLOUM WITH NAME = CONDITON AND APPEND THE VALUE IN FORM OF (PROBESIZE_TIMEPOINT). THIS INFORMATION WILL BE AUTOMATICALLY TAKEN FROM COLOUM = FILENAME (CREATED IN PREVIOUS STEP) #####

import$df_soma <- import$df_soma %>%
  mutate(Condition = str_remove(FileName, pattern = import$folder_path_soma)) %>%
  mutate(Condition = str_remove(Condition, pattern = ".txt")) %>%
  mutate(Condition = str_remove(Condition, pattern = "/"))

import$df_cell <- import$df_cell %>%
  mutate(Condition = str_remove(FileName, pattern = import$folder_path_cell)) %>%
  mutate(Condition = str_remove(Condition, pattern = ".txt")) %>%
  mutate(Condition = str_remove(Condition, pattern = "/"))

##### DELETING THE COLOUM FILENAME. (ITS OF NO USE MATE :=) #####

import$df_soma <-subset(import$df_soma, select = -c(FileName))
import$df_cell <-subset(import$df_cell, select = -c(FileName))


##### RENAMING THE COLOUM NAMES: BY SUBSTRACTING "AREASHAPE_" & ADDING "_SOMA" TO THE COLOUM NAMES #####

colnames(import$df_soma)<-gsub("AreaShape_","",colnames(import$df_soma)) %>%
  paste("soma",sep="_")
colnames(import$df_cell)<-gsub("AreaShape_","",colnames(import$df_cell)) %>%
  paste("cell",sep="_")




##### MERGE DATAFRAMES: DF_SOMA & DF_CELL INTO ONE BIG ASS FILE #####

import$df_all <- merge(import$df_cell, import$df_soma, by.x = c('ImageNumber_cell', 'Parent_Soma_cell', 'Condition_cell'), 
                by.y = c('ImageNumber_soma', 'Parent_Soma_soma', 'Condition_soma'))


##### REMOVE UNWANTED COLOUMS FROM THE FINAL DATASET #####

import$df_all <- subset(import$df_all, select = -c(Location_Center_X_soma, Location_Center_Z_soma,Location_Center_Y_soma, Location_Center_X_cell,
                                     Location_Center_Z_cell, Location_Center_Y_cell, Children_Cell_Count_soma))


##### IMPORT THE DATASHEET WHICH CONTAINS INJURY COORDINATES #####

import$Injury_center <- read_excel("/Volumes/JARI-NES/Brain Injury project/4 Datasheet/Injury center.xls")



##### ADD THE INJURY X & Y COORDINATES TO THE MAIN DATA SHEET (DF_ALL) #####


import$df_all <- merge(import$df_all, import$Injury_center, by.x = c("ImageNumber_cell", "Condition_cell"), by.y = c("Image_Number", "Condition"), all.x=TRUE)



##### ADDING COLOUMS FOR CONDITION AND TIME POINT #####

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

##### EXPORT THE DATASHEET AS A .CSV FILE #####

write_xlsx(import$df_all,"/Volumes/JARI-NES/Extra/df_all.xlsx")












