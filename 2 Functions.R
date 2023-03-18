


##### CALCULATE THE DISTANCE OF EACH CELL FROM THE MID POINT (IN THIS CASE IT IS 2764, 2196) AND CLASIFY THE CELLS ACCORDING TO THE DISTANCE FROM THECENTER INTO 20 BINS) #####

import$df_all$radial_dist <- sqrt((import$df_all$Center_X_soma - import$df_all$Injury_x )^2 + (import$df_all$Center_Y_soma- import$df_all$Injury_y )^2)
import$df_all$bin_number <- ntile(import$df_all$radial_dist, 25 )
import$df_all$bin_range <- import$df_all$bin_number * 139

import$df_all$Bin_Number_New <- import$df_all$bin_number 

import$df_all$Bin_Number_New[import$df_all$bin_number > 16] <- 17 
import$df_all$bin_range_new <- import$df_all$Bin_Number_New * 139



##### RAMIFICATION INEX OF THE CELL #####

import$df_all$RI <- ((import$df_all$Perimeter_cell / import$df_all$Area_cell) / (2*sqrt((pi / import$df_all$Area_cell))))

##### AREA RATIO OF CELL TO SOMA #####
import$df_all$area_ratio <- import$df_all$Area_cell / import$df_all$Area_soma


##### LENGTH TO WIDTH RATIO OF CELL & SOMA (ROD LIKE MORPHOLOGY OF CELL) #####

import$df_all$Length_Width_Ratio_cell <- import$df_all$MaxFeretDiameter_cell / import$df_all$MinFeretDiameter_cell
import$df_all$Length_Width_Ratio_soma <- import$df_all$MaxFeretDiameter_soma / import$df_all$MinFeretDiameter_soma


##### ASPECT RATIO OF CELL WHICH IS DEFINE AS MAJOR AXIS LENGTH TO MINOR AXIS LENGTH #####

import$df_all$Aspect_Ratio_cell <- import$df_all$MajorAxisLength_cell / import$df_all$MinorAxisLength_cell
import$df_all$Aspect_Ratio_soma <- import$df_all$MajorAxisLength_soma / import$df_all$MinorAxisLength_soma


##### BRANCHING RATIO OF THE SECONDARY (NON-TRUNK) TO PRIMARY(TRUNKS) BRANCHES #####
import$df_all$Branch_Ratio <-import$df_all$Non_Trunk_Branch / import$df_all$Trunk_Branch
import$df_all$Total_Branch <-import$df_all$Non_Trunk_Branch + import$df_all$Trunk_Branch


##### CYTOPLASMIC AREA OF MICROGLIA #####

import$df_all$Cyto_Area <- import$df_all$Area_cell - import$df_all$Area_soma

##### GROUPING THT DATAFRAME INTO FAR & NEAR THE INJURG LOCATION USING BINS < 6 is near and >13 IS FAR & REST MIDDLE #####
import$df_all$Impact_Region <- case_when(import$df_all$Bin_Number_New <= 5 ~ "Near",
                                         import$df_all$Bin_Number_New >= 8 ~ "Far",
                                  TRUE ~ "Middle")


##### HEALTH SCORE OF CELLS FROM 0-1 #####

import$df_all$Health_score <- case_when(import$df_all$Total_Branch >= 20 ~ 1,
                                        import$df_all$Total_Branch <= 19 ~ (1 - (((20 - import$df_all$Total_Branch) / 2))/10))



##### Colour pallet #####

company_colors <-c("#E50000", "#008A8A", "#AF0076", "#E56800", "#1717A0", "#E5AC00", "#00B700")


##### EXCLUSION CRITERIA #####


#para_plot


filter_data_1 <- function(df)
  {
df_all_filtered_10 <- df[!(df$Bin_Number_New >= 11 & df$RI < 2),]
df_all_filtered_20 <- df_all_filtered_10[!(df_all_filtered_10$Bin_Number_New <= 6 &  df_all_filtered_10$RI >5),]
df_all_filtered_30 <- df_all_filtered_20[!(df_all_filtered_20$Total_Branch > 90),]
df_all_filtered_40 <- df_all_filtered_30[!(df_all_filtered_30$Bin_Number_New >= 11 & df_all_filtered_30$area_ratio < 2 & df_all_filtered_30$Time_weeks > 00 & df_all_filtered_30$Time_weeks < 08),]
df_all_filtered_50 <- df_all_filtered_40[!(df_all_filtered_40$Bin_Number_New <= 6 & df_all_filtered_40$Non_Trunk_Branch > 10 & df_all_filtered_40$Time_weeks > 00 & df_all_filtered_40$Time_weeks < 08),]
return(df_all_filtered_50)
}


filter_data_2 <- function(df)
{
df_all_filtered_1 <- df_all[!(df_all$Bin_Number_New >= 10 &  df_all$Time_weeks >= 2 & df_all$Total_Branch < 20 & df_all$Electrode_Thickness == 50),]
df_all_filtered_2 <- df_all_filtered_1[!(df_all_filtered_1$Bin_Number_New <= 8 & df_all_filtered_1$Time_weeks >= 18 & df_all_filtered_1$Total_Branch >20),]
df_all_filtered_3 <- df_all_filtered_2[!(df_all_filtered_2$Bin_Number_New >= 14 & df_all_filtered_2$Total_Branch <= 20),]
df_all_filtered_4 <- df_all_filtered_3[!(df_all_filtered_3$Total_Branch > 70),]
return(df_all_filtered_4)
}




##### REORDER THE COLOUMS WHICH ARE NOT NECESSARY TO FIRST #####

import$df_all_reordered = import$df_all %>% dplyr::select(c(9,10,11,12,13,14,19, 29 ,32,33,34,37,38,39,
                                                40,41,42,47,57, 60, 65, 66, 68, 69, 70, 71, 78, 81), everything())


##### select the coloums which gives out actual values of microglia morphology #####

import$df_all_reordered_raw <- import$df_all_reordered[, colnames(import$df_all_reordered)[c(25, 31, 32 , 35:81)]]



write.csv(df_all_reordered,"D:/Brain Injury project/4 Datasheet/df_all_reordered.csv", row.names = FALSE)










##### SCALING THE DATA FROM 28TH COLOUM. BECAUSE THE ACTUAL PARAMETERS ARE ALIGNED FROM 28. IT MAY VARY. #####

df_all_reordered_clust <- df_all_reordered[, colnames(df_all_reordered)[c(35:81)]]





