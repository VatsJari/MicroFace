# ============================================================================
# Data Import and Preprocessing Script for Microglial Morphology Analysis
# (Adapted: two direct input files instead of folders)
# ============================================================================

# Initialize list to store all data and intermediate objects
import <- list()


##### 1. SET FILE PATHS FOR SOMA AND CELL DATA (TWO FILES) #####

import$file_path_soma <- "/Users/vatsjari/Documents/STAR_Protocol/Datasheet/_TestSoma_Filtered.txt"
import$file_path_cell <- "/Users/vatsjari/Documents/STAR_Protocol/Datasheet/_TestCell.txt"

# ============================================================================
# Data Import and Preprocessing Script for Microglial Morphology Analysis
# (Two-file merge, no metadata / no condition)
# ============================================================================


##### 2. READ THE TWO FILES DIRECTLY #####

import$df_soma <- vroom::vroom(import$file_path_soma)
import$df_cell <- vroom::vroom(import$file_path_cell)


##### 3. RENAME COLUMNS: REMOVE "AreaShape_" PREFIX AND ADD "_soma"/"_cell" SUFFIX #####

colnames(import$df_soma) <- gsub("AreaShape_", "", colnames(import$df_soma)) %>%
  paste("soma", sep = "_")
colnames(import$df_cell) <- gsub("AreaShape_", "", colnames(import$df_cell)) %>%
  paste("cell", sep = "_")


##### 4. MERGE SOMA AND CELL DATAFRAMES INTO ONE MASTER DATAFRAME #####
# Keys: ImageNumber + FileName_Original_Iba1 (+ Parent_Soma_Merged to keep the
# soma<->cell pairing correct, since a single image contains many objects).

import$df_all <- merge(
  import$df_cell, import$df_soma,
  by.x = c("FileName_Original_Iba1_cell",
           "ImageNumber_cell",
           "Parent_Soma_Merged_cell"),
  by.y = c("FileName_Original_Iba1_soma",
           "ImageNumber_soma",
           "Parent_Soma_Merged_soma")
)

colnames(import$df_all)


##### 5. REMOVE UNWANTED LOCATION / CHILD-COUNT COLUMNS #####

import$df_all <- subset(
  import$df_all,
  select = -c(Location_Center_X_soma, Location_Center_Z_soma,
              Location_Center_Y_soma, Location_Center_X_cell,
              Location_Center_Z_cell, Location_Center_Y_cell,
              Children_Cell_Count_soma)
)

colnames(import$df_all)


##### 6. RENAME KEY MORPHOLOGY COLUMNS FOR EASIER REFERENCE #####

names(import$df_all)[names(import$df_all) == "ObjectSkeleton_NumberBranchEnds_MorphologicalSkeleton_soma"]      <- "Branch_Ends"
names(import$df_all)[names(import$df_all) == "ObjectSkeleton_NumberNonTrunkBranches_MorphologicalSkeleton_soma"] <- "Non_Trunk_Branch"
names(import$df_all)[names(import$df_all) == "ObjectSkeleton_NumberTrunks_MorphologicalSkeleton_soma"]           <- "Trunk_Branch"
names(import$df_all)[names(import$df_all) == "ObjectSkeleton_TotalObjectSkeletonLength_MorphologicalSkeleton_soma"] <- "Skeleton_Length"

colnames(import$df_all)


##### 7. COMPUTE MORPHOLOGY METRICS #####

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


##### 8. COMPUTE HEALTH SCORE (0-1) BASED ON TOTAL BRANCHES #####

import$df_all$Health_score <- case_when(
  import$df_all$Total_Branch >= 20 ~ 1,
  import$df_all$Total_Branch <= 19 ~ (1 - (((20 - import$df_all$Total_Branch) / 2)) / 10)
)


##### 9. DROP NON-METRIC / IDENTIFIER COLUMNS #####

import$df_all <- subset(
  import$df_all,
  select = -c(
    Parent_Soma_Filtered_cell,
    ObjectNumber_cell,
    PathName_Original_Iba1_cell,
    BoundingBoxMaximum_X_cell, BoundingBoxMaximum_Y_cell,
    BoundingBoxMinimum_X_cell, BoundingBoxMinimum_Y_cell,
    EulerNumber_cell, Orientation_cell,
    Number_Object_Number_cell,
    # Parent_Soma_Merged_cell,   <-- REMOVED from drop-list
    ObjectNumber_soma,
    PathName_Original_Iba1_soma,
    BoundingBoxMaximum_X_soma, BoundingBoxMaximum_Y_soma,
    BoundingBoxMinimum_X_soma, BoundingBoxMinimum_Y_soma,
    Center_X_cell, Center_Y_cell, EulerNumber_soma,
    Extent_soma, Orientation_soma, Number_Object_Number_soma
  )
)

colnames(import$df_all)


##### 10. DEFINE COLOR PALETTES FOR PLOTTING #####

import$company_colors  <- c("#E50000", "#008A8A", "#AF0076", "#E56800",
                            "#1717A0", "#E5AC00", "#00B700")

import$company_colors2 <- c("#E50000", "#0080FF", "#E56800", "#AF0076", "#1717A0")

import$morpho_colours  <- c("#FF0000", "#00FF00", "#0000FF", "#FFFF00",
                            "#FF00FF", "#00FFFF", "#FF8000", "#8000FF",
                            "#00FF80", "#FF0080", "#0080FF", "#80FF00",
                            "#800000", "#008000")



##### 11. CREATE A CLEANED DATAFRAME FOR PCA #####
# Column order:
#   identifiers (file name, image number, soma parent)
#   -> soma center coordinates
#   -> all remaining morphology metric columns

id_cols <- c("FileName_Original_Iba1_cell",
             "ImageNumber_cell",
             "Parent_Soma_Merged_cell")

coord_cols <- c("Center_X_soma", "Center_Y_soma")

# Keep only columns that actually exist (defensive)
id_cols    <- intersect(id_cols,    colnames(import$df_all))
coord_cols <- intersect(coord_cols, colnames(import$df_all))

front_cols  <- c(id_cols, coord_cols)
metric_cols <- setdiff(colnames(import$df_all), front_cols)

import$df_all_PCA <- na.omit(
  import$df_all %>%
    dplyr::select(all_of(front_cols), all_of(metric_cols))
)

colnames(import$df_all_PCA)
str(import$df_all_PCA)
