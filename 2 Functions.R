

##### CALCULATE THE DISTANCE OF EACH CELL FROM THE MID POINT (IN THIS CASE IT IS 2764, 2196) AND CLASIFY THE CELLS ACCORDING TO THE DISTANCE FROM THECENTER INTO 20 BINS) #####

df_all$radial_dist <- sqrt((df_all$Center_X_soma - 2764 )^2 + (df_all$Center_Y_soma- 2196 )^2)
df_all$bin_number <- ntile(df_all$radial_dist, 25 )
df_all$bin_range <- df_all$bin_number * 139

df_all$Bin_Number_New <- df_all$bin_number 
df_all$Bin_Number_New[df_all$bin_number > 16] <- 17 
df_all$bin_range_new <- df_all$Bin_Number_New * 139



##### RAMIFICATION INEX OF THE CELL #####

df_all$RI <- ((df_all$Perimeter_cell / df_all$Area_cell) / (2*sqrt((pi / df_all$Area_cell))))

##### AREA RATIO OF CELL TO SOMA #####
df_all$area_ratio <- df_all$Area_cell / df_all$Area_soma


##### LENGTH TO WIDTH RATIO OF CELL & SOMA (ROD LIKE MORPHOLOGY OF CELL) #####

df_all$Length_Width_Ratio_cell <- df_all$MaxFeretDiameter_cell / df_all$MinFeretDiameter_cell
df_all$Length_Width_Ratio_soma <- df_all$MaxFeretDiameter_soma / df_all$MinFeretDiameter_soma


##### ASPECT RATIO OF CELL WHICH IS DEFINE AS MAJOR AXIS LENGTH TO MINOR AXIS LENGTH #####

df_all$Aspect_Ratio_cell <- df_all$MajorAxisLength_cell / df_all$MinorAxisLength_cell
df_all$Aspect_Ratio_soma <- df_all$MajorAxisLength_soma / df_all$MinorAxisLength_soma


##### BRANCHING RATIO OF THE SECONDARY (NON-TRUNK) TO PRIMARY(TRUNKS) BRANCHES #####
df_all$Branch_Ratio <-df_all$Non_Trunk_Branch / df_all$Trunk_Branch
df_all$Total_Branch <-df_all$Non_Trunk_Branch + df_all$Trunk_Branch


##### CYTOPLASMIC AREA OF MICROGLIA #####

df_all$Cyto_Area <- df_all$Area_cell - df_all$Area_soma

##### EXCLUSION CRITERIA #####

df_all_filtered_1 <- df_all[!(df_all$Bin_Number_New >= 10 &  df_all$Time_weeks >= 2 & df_all$Total_Branch < 20 & df_all$Electrode_Thickness == 50),]
df_all_filtered_2 <- df_all_filtered_1[!(df_all_filtered_1$Bin_Number_New <= 8 & df_all_filtered_1$Time_weeks >= 18 & df_all_filtered_1$Total_Branch >30),]


##### REORDER THE COLOUMS WHICH ARE NOT NECESSARY TO FIRST #####

df_all_reordered = df_all_filtered_2 %>% dplyr::select(c(9,10,11,12,13,14,19, 29 ,32,33,34,37,38,39,
                                                40,41,42,47,57, 60, 66, 67, 68, 69, 76), everything())


##### SCALING THE DATA FROM 28TH COLOUM. BECAUSE THE ACTUAL PARAMETERS ARE ALIGNED FROM 28. IT MAY VARY. #####

df_all_reordered_new <- scale(df_all_reordered[,32:78])
df_all_reordered_new_df <- as.data.frame(df_all_reordered_new)

df_all_reordered_raw <- df_all_reordered[, colnames(df_all_reordered)[c(20, 22, 26, 27 , 32:78)]]

df_all_reordered_clust <- df_all_reordered[, colnames(df_all_reordered)[c(30:77)]]

df_all_reordered_corr <- df_all_reordered[, colnames(df_all_reordered)[c(17, 30:77)]]


df_all_reordered_raw[,6:50] <- scale(df_all_reordered_raw[,6:50])





