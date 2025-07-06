# ===================================================
# DATA IMPORT AND PROCESSING PIPELINE
# ===================================================

# -------------------------------
# 1. INITIALIZATION
# -------------------------------
import <- list()

# Set paths (modify these as needed)
import$folder_path_soma <- "/Users/vatsaljariwala/Documents/Brain Injury project/4 Datasheet/Datasheet_all_soma"
import$folder_path_cell <- "/Users/vatsaljariwala/Documents/Brain Injury project/4 Datasheet/Datasheet_all_cell"
import$injury_path <- "/Users/vatsaljariwala/Documents/Brain Injury project/4 Datasheet/Injury center.xls"
import$output_path <- "/Users/vatsaljariwala/Documents/Brain Injury project/4 Datasheet/df_all_git.xlsx"

# -------------------------------
# 2. DATA IMPORT
# -------------------------------
# Get file lists
import$list_of_files_soma <- list.files(
  path = import$folder_path_soma,
  pattern = "*.txt",
  recursive = TRUE,
  full.names = TRUE
)

import$list_of_files_cell <- list.files(
  path = import$folder_path_cell,
  pattern = "*.txt",
  recursive = TRUE,
  full.names = TRUE
)

# Read files using vroom
import$df_soma <- vroom::vroom(import$list_of_files_soma, id = "FileName")
import$df_cell <- vroom::vroom(import$list_of_files_cell, id = "FileName")

# -------------------------------
# 3. DATA CLEANING AND PROCESSING
# -------------------------------
# Process Condition column to extract just the last segment (e.g. "06_00")
clean_condition <- function(df) {
  df %>%
    dplyr::mutate(
      # Extract just the last segment after last /
      Condition = stringr::str_extract(FileName, "[^/]+(?=\\.txt$)")
    ) %>%
    dplyr::select(-FileName)
}

import$df_soma <- clean_condition(import$df_soma)
import$df_cell <- clean_condition(import$df_cell)


# Rename columns
rename_columns <- function(df, suffix) {
  names(df) <- gsub("AreaShape_", "", names(df)) %>% 
    paste(suffix, sep = "_")
  return(df)
}

import$df_soma <- rename_columns(import$df_soma, "soma")
import$df_cell <- rename_columns(import$df_cell, "cell")

# -------------------------------
# 4. DATA MERGING
# -------------------------------
import$df_all <- merge(import$df_cell, import$df_soma, by.x = c('ImageNumber_cell', 'Parent_Soma_cell', 'Condition_cell'), 
                       by.y = c('ImageNumber_soma', 'Parent_Soma_soma', 'Condition_soma'))


# Remove unwanted columns
import$df_all <- import$df_all %>%
  dplyr::select(-c(
    Location_Center_X_soma, Location_Center_Z_soma, Location_Center_Y_soma,
    Location_Center_X_cell, Location_Center_Z_cell, Location_Center_Y_cell,
    Children_Cell_Count_soma
  ))

# -------------------------------
# 5. ADD INJURY COORDINATES
# -------------------------------
import$Injury_center <- readxl::read_excel(import$injury_path)

import$df_all <- merge(
  import$df_all,
  import$Injury_center,
  by.x = c("ImageNumber_cell", "Condition_cell"),
  by.y = c("Image_Number", "Condition"),
  all.x = TRUE
)

# -------------------------------
# 6. FINAL DATA PROCESSING
# -------------------------------
# Split Condition column
import$df_all <- import$df_all %>%
  tidyr::separate(
    col = Condition_cell,
    sep = "_",
    into = c("Electrode_Thickness", "Time_weeks"),
    remove = FALSE
  )

# Rename columns
import$df_all <- import$df_all %>%
  dplyr::rename(
    Branch_Ends = ObjectSkeleton_NumberBranchEnds_MorphologicalSkeleton_soma,
    Non_Trunk_Branch = ObjectSkeleton_NumberNonTrunkBranches_MorphologicalSkeleton_soma,
    Trunk_Branch = ObjectSkeleton_NumberTrunks_MorphologicalSkeleton_soma,
    Skeleton_Length = ObjectSkeleton_TotalObjectSkeletonLength_MorphologicalSkeleton_soma,
    Injury_x = x,
    Injury_y = y
  )

# -------------------------------
# 7. EXPORT FINAL DATASET
# -------------------------------
writexl::write_xlsx(import$df_all, import$output_path)

# ===================================================
# SESSION INFO FOR REPRODUCIBILITY
# ===================================================
cat("\n===== PROCESSING COMPLETE =====\n")
cat("Final dataset saved to:", import$output_path, "\n")
sessionInfo()