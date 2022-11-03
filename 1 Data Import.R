


##### COPY THE PATH OF FOLDER THAT CONTAINS ALL THE TEXT FILES #####

folder_path_soma = "/media/patrick/JARI-NES/Brain Injury project/4 Datasheet/Datasheet_all_soma/"
folder_path_cell = "/media/patrick/JARI-NES/Brain Injury project/4 Datasheet/Datasheet_all_cell/"


# STORE ALL THE FILE NAMES INTO ON OBJECT = LIST_OF_ALL_FILES_SOMA

list_of_files_soma <- list.files(path = folder_path_soma , recursive = TRUE,
                            pattern = "*.txt", full.names = TRUE)
list_of_files_cell <- list.files(path = folder_path_cell , recursive = TRUE,
                                 pattern = "*.txt", full.names = TRUE)  



##### MERGE ALL THEFILES INTO ONE BIG DATAFRAME. ALSO ADDING FILENAME TO A NEW COLOUM #####

df_soma <- vroom(list_of_files_soma, id = "FileName")
df_cell <- vroom(list_of_files_cell, id = "FileName")



##### CREATE A NEW COLOUM WITH NAME = CONDITON AND APPEND THE VALUE IN FORM OF (PROBESIZE_TIMEPOINT). THIS INFORMATION WILL BE AUTOMATICALLY TAKEN FROM COLOUM = FILENAME (CREATED IN PREVIOUS STEP) #####

df_soma <- df_soma %>%
  mutate(Condition = str_remove(FileName, pattern = folder_path_soma)) %>%
  mutate(Condition = str_remove(Condition, pattern = ".txt")) %>%
  mutate(Condition = str_remove(Condition, pattern = "/"))

df_cell <- df_cell %>%
  mutate(Condition = str_remove(FileName, pattern = folder_path_cell)) %>%
  mutate(Condition = str_remove(Condition, pattern = ".txt")) %>%
  mutate(Condition = str_remove(Condition, pattern = "/"))

##### DELETING THE COLOUM FILENAME. (ITS OF NO USE MATE :=) #####

df_soma <-subset(df_soma, select = -c(FileName))
df_cell <-subset(df_cell, select = -c(FileName))


##### RENAMING THE COLOUM NAMES: BY SUBSTRACTING "AREASHAPE_" & ADDING "_SOMA" TO THE COLOUM NAMES #####

colnames(df_soma)<-gsub("AreaShape_","",colnames(df_soma)) %>%
  paste("soma",sep="_")
colnames(df_cell)<-gsub("AreaShape_","",colnames(df_cell)) %>%
  paste("cell",sep="_")




##### MERGE DATAFRAMES: DF_SOMA & DF_CELL INTO ONE BIG ASS FILE #####

df_all <- merge(df_cell, df_soma, by.x = c('ImageNumber_cell', 'Parent_Soma_cell', 'Condition_cell'), 
                by.y = c('ImageNumber_soma', 'Parent_Soma_soma', 'Condition_soma'))


##### REMOVE UNWANTED COLOUMS FROM THE FINAL DATASET #####

df_all <- subset(df_all, select = -c(Location_Center_X_soma, Location_Center_Z_soma,Location_Center_Y_soma, Location_Center_X_cell,
                                     Location_Center_Z_cell, Location_Center_Y_cell, Children_Cell_Count_soma))

##### ADDING COLOUMS FOR CONDITION AND TIME POINT #####

colmn <- paste('Electrode_Thickness',1:2)

df_all <- tidyr::separate(
  data = df_all,
  col = Condition_cell,
  sep = "_",
  into = colmn,
  remove = FALSE)

names(df_all)[names(df_all) == 'Electrode_Thickness 2'] <- 'Time_weeks'
names(df_all)[names(df_all) == 'Electrode_Thickness 1'] <- 'Electrode_Thickness'
names(df_all)[names(df_all) == 'ObjectSkeleton_NumberBranchEnds_MorphologicalSkeleton_soma'] <- 'Branch_Ends'
names(df_all)[names(df_all) == 'ObjectSkeleton_NumberNonTrunkBranches_MorphologicalSkeleton_soma'] <- 'Non_Trunk_Branch'
names(df_all)[names(df_all) == 'ObjectSkeleton_NumberTrunks_MorphologicalSkeleton_soma'] <- 'Trunk_Branch'
names(df_all)[names(df_all) == 'ObjectSkeleton_TotalObjectSkeletonLength_MorphologicalSkeleton_soma'] <- 'Skeleton_Length'



##### EXPORT THE DATASHEET AS A .CSV FILE #####

# write.csv(df_all,"/media/patrick/JARI-NES/Brain Injury project/4 Datasheet/df_merged.csv", row.names = FALSE)












