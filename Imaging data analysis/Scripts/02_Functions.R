# ===================================================
# MICROGLIA MORPHOLOGICAL ANALYSIS PIPELINE
# ===================================================

# -------------------------------
# 1. DISTANCE CALCULATIONS & BINNING
# -------------------------------

# Calculate radial distance from injury center (2764, 2196)
import$df_all <- import$df_all %>%
  mutate(
    radial_dist = sqrt((Center_X_soma - Injury_x)^2 + (Center_Y_soma - Injury_y)^2),
    
    # Create 25 bins based on distance
    bin_number = ntile(radial_dist, 25),
    bin_range = bin_number * 139,
    
    # Consolidate bins >16 into single bin (17)
    Bin_Number_New = ifelse(bin_number > 16, 17, bin_number),
    bin_range_new = Bin_Number_New * 139,
    
    # Classify impact regions
    Impact_Region = case_when(
      Bin_Number_New <= 5 ~ "Near",
      Bin_Number_New >= 8 ~ "Far",
      TRUE ~ "Middle"
    )
  )

# -------------------------------
# 2. MORPHOLOGICAL METRICS CALCULATION
# -------------------------------

# Calculate various morphological parameters
import$df_all <- import$df_all %>%
  mutate(
    # Ramification Index
    RI = (Perimeter_cell / Area_cell) / (2 * sqrt(pi / Area_cell)),
    
    # Area ratios
    area_ratio = Area_cell / Area_soma,
    Cyto_Area = Area_cell - Area_soma,
    
    # Length/Width ratios
    Length_Width_Ratio_cell = MaxFeretDiameter_cell / MinFeretDiameter_cell,
    Length_Width_Ratio_soma = MaxFeretDiameter_soma / MinFeretDiameter_soma,
    
    # Aspect ratios
    Aspect_Ratio_cell = MajorAxisLength_cell / MinorAxisLength_cell,
    Aspect_Ratio_soma = MajorAxisLength_soma / MinorAxisLength_soma,
    
    # Branching metrics
    Branch_Ratio = Non_Trunk_Branch / Trunk_Branch,
    Total_Branch = Non_Trunk_Branch + Trunk_Branch,
    
    # Health score (0-1 scale)
    Health_score = case_when(
      Total_Branch >= 20 ~ 1,
      TRUE ~ (1 - ((20 - Total_Branch) / 2)/10)
    )
  )

# -------------------------------
# 3. COLOR PALETTES
# -------------------------------
company_colors <- c("#E50000", "#008A8A", "#AF0076", "#E56800", "#1717A0", "#E5AC00", "#00B700")
company_colors2 <- c("#E50000", "#0080FF","#E56800", "#AF0076", "#1717A0")
morpho_colours <- c("#FF0000", "#00FF00", "#0000FF", "#FFFF00", "#FF00FF", "#00FFFF",
                    "#FF8000", "#8000FF", "#00FF80", "#FF0080", "#0080FF", "#80FF00",
                    "#800000", "#008000")


# -------------------------------
# 4. DATA REORGANIZATION
# -------------------------------

# Reorder columns to prioritize important variables
import$df_all_reordered <- import$df_all %>%
  dplyr::select(
    # Selected important columns first
    c(9:14,19,29,32,33,34,37,38,39,40,41,42,47,57,60,65:72),
    # All remaining columns
    everything()
  )


# -------------------------------
# 5. DATA EXPORT
# -------------------------------
write.csv(import$df_all_reordered, 
          "D:/Brain Injury project/4 Datasheet/df_all_reordered.csv", 
          row.names = FALSE)