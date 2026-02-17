


##### CALCULATE THE DISTANCE OF EACH CELL FROM THE MID POINT (IN THIS CASE IT IS 2764, 2196) AND CLASIFY THE CELLS ACCORDING TO THE DISTANCE FROM THECENTER INTO 20 BINS) #####

import$df_all$radial_dist <- sqrt((import$df_all$Center_X_soma - import$df_all$Injury_x )^2 + (import$df_all$Center_Y_soma- import$df_all$Injury_y )^2)
import$df_all$bin_number <- ntile(import$df_all$radial_dist, 25)
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
#import$df_all$Branch_Ratio <-import$df_all$Non_Trunk_Branch / import$df_all$Trunk_Branch
import$df_all$Total_Branch <-import$df_all$Non_Trunk_Branch + import$df_all$Trunk_Branch


##### CYTOPLASMIC AREA OF MICROGLIA #####

import$df_all$Cyto_Area <- import$df_all$Area_cell - import$df_all$Area_soma

##### GROUPING THT DATAFRAME INTO FAR & NEAR THE INJURG LOCATION USING BINS < 6 is near and >13 IS FAR & REST MIDDLE #####
import$df_all$Impact_Region <- case_when(
  import$df_all$Bin_Number_New <= 6 ~ "Close",
  import$df_all$Bin_Number_New > 10 ~ "Far",
  import$df_all$Bin_Number_New > 6 & import$df_all$Bin_Number_New <= 10 ~ "Middle",
  TRUE ~ as.character(import$df_all$Bin_Number_New)
)
##### HEALTH SCORE OF CELLS FROM 0-1 #####

import$df_all$Health_score <- case_when(import$df_all$Total_Branch >= 20 ~ 1,
                                        import$df_all$Total_Branch <= 19 ~ (1 - (((20 - import$df_all$Total_Branch) / 2))/10))



##### Colour pallet #####

company_colors <-c("#E50000", "#008A8A", "#AF0076", "#E56800", "#1717A0", "#E5AC00", "#00B700")


company_colors2 <-c("#E50000", "#0080FF","#E56800", "#AF0076", "#1717A0")

morpho_colours <- c("#FF0000", "#00FF00", "#0000FF", "#FFFF00", "#FF00FF", "#00FFFF",
                    "#FF8000", "#8000FF", "#00FF80", "#FF0080", "#0080FF", "#80FF00",
                    "#800000", "#008000")


##### EXCLUSION CRITERIA #####


##### REORDER THE COLOUMS WHICH ARE NOT NECESSARY TO FIRST #####

import$df_all <- subset(import$df_all, select = -c(Staining, Bagsub, Parent_Soma_Filtered_cell, ObjectNumber_cell,PathName_Original_Iba1_cell,
                                                   BoundingBoxMaximum_X_cell, BoundingBoxMaximum_Y_cell, BoundingBoxMinimum_X_cell, BoundingBoxMinimum_Y_cell,
                                                   EulerNumber_cell,Orientation_cell,  Number_Object_Number_cell, Parent_Soma_Merged_cell, ObjectNumber_soma, FileName_Original_Iba1_soma,
                                                   PathName_Original_Iba1_soma, BoundingBoxMaximum_X_soma, BoundingBoxMaximum_Y_soma, BoundingBoxMinimum_X_soma, BoundingBoxMinimum_Y_soma,
                                                   Center_X_cell, Center_Y_cell, EulerNumber_soma, Extent_soma, Orientation_soma, Number_Object_Number_soma 
                                                   ))

colnames(import$df_all)

import$df_all_PCA = na.omit(import$df_all %>% dplyr::select(c(1:7, 27, 28, 47:53, 62 ), everything()))

colnames(import$df_all_PCA)
str(import$df_all_PCA)







