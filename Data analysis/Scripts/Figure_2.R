# ============================================================================
# FIGURE 2: MicroFace Validation and Cell Density Analysis
# FIGURE S2: VALIDATION CORRELATION
# FIGURE S4: facet by probe size 
# ============================================================================
# This script generates two main panels:
# 1. Correlation scatter plots comparing manual vs automated (MicroFace) measurements.
# 2. Density line plots showing cell density vs distance from injury, grouped by time,
#    optionally faceted by electrode thickness.
# All outputs are stored in the 'Fig2' list.
# ============================================================================

# Initialize list
Fig2 <- list()

# ============================================================================
# PART A: VALIDATION – Manual vs Automated Correlation
# ============================================================================

cat("\n=== Loading validation data ===\n")

# Load validation datasets
Fig2$val_data_Mask <- read_csv("/Users/vatsaljariwala/Documents/Brain Injury project/Revised_Submission/Datasheet/validation/Validation_IdentifyPrimaryObjects.csv")
Fig2$val_data_OGsoma <- read_csv("/Users/vatsaljariwala/Documents/Brain Injury project/Revised_Submission/Datasheet/validation/Validation_Soma_Filtered.csv")
Fig2$val_data_OGcell <- read_csv('/Users/vatsaljariwala/Documents/Brain Injury project/Revised_Submission/Datasheet/validation/Validation_Cell.csv')

# Rename columns: remove "AreaShape_" prefix and add "_soma"/"_cell" suffix
colnames(Fig2$val_data_OGsoma) <- gsub("AreaShape_", "", colnames(Fig2$val_data_OGsoma)) %>%
  paste("soma", sep = "_")
colnames(Fig2$val_data_OGcell) <- gsub("AreaShape_", "", colnames(Fig2$val_data_OGcell)) %>%
  paste("cell", sep = "_")

# Merge cell and soma data
Fig2$val_data_OGall <- merge(Fig2$val_data_OGcell, Fig2$val_data_OGsoma,
                             by.x = c('ImageNumber_cell', 'Parent_Soma_Filtered_cell'),
                             by.y = c('ImageNumber_soma', 'Parent_Soma_Merged_soma'))

# Merge with manual mask data
Fig2$val_data_all <- merge(Fig2$val_data_OGall, Fig2$val_data_Mask,
                           by.x = c('ImageNumber_cell', 'Parent_ShrunkenNuclei_cell'),
                           by.y = c('ImageNumber', 'ObjectNumber'))

cat("Validation data merged. Dimensions:", dim(Fig2$val_data_all), "\n")

# ============================================================================
# Helper function: Correlation scatter plot with stats
# ============================================================================

Fig2$cor_plot <- function(data, xvar, yvar, title, xlabel, ylabel) {
  ggplot(data, aes(x = .data[[xvar]], y = .data[[yvar]])) +
    geom_point(size = 0.4, color = 'blue') +
    geom_jitter(size = 0.4, width = 0.5, colour = 'blue') +
    geom_smooth(method = "lm", se = TRUE, color = 'green') +
    stat_cor(method = "pearson",
             label.x.npc = "left",
             label.y.npc = "top",
             size = 3) +
    labs(title = title, x = xlabel, y = ylabel) +
    theme_classic()
}

# ============================================================================
# Generate key correlation plots (keep only essential ones)
# ============================================================================

cat("\n=== Generating correlation plots ===\n")

# 1. Cell area correlation
Fig2$cor_area <- Fig2$cor_plot(
  Fig2$val_data_all,
  "AreaShape_Area",          # Manual measurement (from mask)
  "Area_cell",                # MicroFace measurement
  "Cell Area",
  "Manual (pixels²)",
  "MicroFace (pixels²)"
)
print(Fig2$cor_area)

# 2. Perimeter correlation
Fig2$cor_perimeter <- Fig2$cor_plot(
  Fig2$val_data_all,
  "AreaShape_Perimeter",
  "Perimeter_cell",
  "Cell Perimeter",
  "Manual (pixels)",
  "MicroFace (pixels)"
)
print(Fig2$cor_perimeter)

# 3. Max Feret Diameter correlation
Fig2$cor_maxferet <- Fig2$cor_plot(
  Fig2$val_data_all,
  "AreaShape_MaxFeretDiameter",
  "MaxFeretDiameter_cell",
  "Max Feret Diameter",
  "Manual (pixels)",
  "MicroFace (pixels)"
)
print(Fig2$cor_maxferet)

# 4. Solidity correlation
Fig2$cor_solidity <- Fig2$cor_plot(
  Fig2$val_data_all,
  "AreaShape_Solidity",
  "Solidity_cell",
  "Solidity",
  "Manual",
  "MicroFace"
)
print(Fig2$cor_solidity)

# 5. convex area correlation
Fig2$convex_area <- Fig2$cor_plot(
  Fig2$val_data_all,
  "AreaShape_ConvexArea",
  "ConvexArea_cell",
  "Convex Area",
  "MicroFace",
  "Manual"
)
print(Fig2$convex_area)

# 6. radius correlation
Fig2$radius_cor <- Fig2$cor_plot(
  Fig2$val_data_all,
  "AreaShape_MeanRadius",
  "MeanRadius_cell",
  "Radius(cell)",
  "MicroFace",
  "Manual"
)

Fig2$radius_cor

# ============================================================================
# PART B: CELL DENSITY ANALYSIS (using clustered/filtered data)
# ============================================================================

cat("\n=== Computing cell density from filtered data ===\n")

# 1. Count cells per image per bin
Fig2$df_raw <- ClusterAnalysis$final_df_full %>% 
  group_by(ImageNumber_cell, SubImage, Animal_No, 
           Bin_Number_New, Time_weeks, Electrode_Thickness) %>% 
  summarise(cells_per_image_bin = n(), .groups = "drop")

# Remove bin 17 (combined far bins)
Fig2$df_raw <- filter(Fig2$df_raw, Bin_Number_New != 17)

# Compute radial distance and area of each annular bin
Fig2$df_raw$radial_dist <- 139 * Fig2$df_raw$Bin_Number_New
Fig2$df_raw$bin_area <- pi * (Fig2$df_raw$radial_dist)^2 - 
  pi * (Fig2$df_raw$radial_dist - 139)^2

# 2. Apply density formula (normalized to area)
Fig2$df_raw <- Fig2$df_raw %>%
  mutate(
    density = 100 * (cells_per_image_bin / 2 * sqrt(pi / bin_area))
  )

# 3. Summarise per bin, time, and electrode thickness
Fig2$df_summary <- Fig2$df_raw %>%
  group_by(Bin_Number_New, Time_weeks, Electrode_Thickness) %>%
  summarise(
    mean_density = mean(density, na.rm = TRUE),
    sd_density   = sd(density, na.rm = TRUE),
    n_images     = n_distinct(ImageNumber_cell),
    radial_dist  = first(radial_dist),
    bin_area     = first(bin_area),
    .groups = "drop"
  ) %>%
  mutate(
    sem_density  = sd_density / sqrt(n_images),
    density_upper = mean_density + sem_density,
    density_lower = mean_density - sem_density
  )

# Show summary
cat("\n=== Density summary (first few rows) ===\n")
print(head(Fig2$df_summary))

# ============================================================================
# Density plots
# ============================================================================

# Define color palette (use company_colors if available, otherwise default)
if (!exists("company_colors")) {
  company_colors <- c("#E50000", "#008A8A", "#AF0076", "#E56800", "#1717A0", "#E5AC00")
}

# Plot 1: All thicknesses together (log scale for y)
Fig2$plot_density_all <- ggplot(Fig2$df_summary, 
                                aes(x = radial_dist, 
                                    y = (mean_density), 
                                    color = as.factor(Time_weeks))) +
  geom_smooth(aes(group = Time_weeks), method = "loess", se = FALSE, linewidth = 1) +
  geom_errorbar(aes(ymin = (density_lower), ymax = (density_upper)), 
                width = 50, alpha = 0.5) +
  geom_point(size = 1, alpha = 0.7) +
  scale_color_manual(values = company_colors, name = "Time (Weeks)") +
  labs(
    x = "Distance from implantation site (µm)", 
    y = expression(log[10]("Cell density (normalized)"))
  ) +
  theme_classic() +
  theme(
    plot.title = element_text(size = 12, hjust = 0.5),
    axis.title = element_text(size = 12),
    axis.text = element_text(size = 10),
    legend.text = element_text(size = 8),
    legend.title = element_text(size = 8),
    legend.key.size = unit(1.5, "lines"),
    legend.position = "right"          # remove if legend needed
  )
(Fig2$plot_density_all)

# Plot 2: Faceted by Electrode Thickness (linear scale)
Fig2$plot_density_facet <- ggplot(Fig2$df_summary, 
                                  aes(x = radial_dist, 
                                      y = mean_density, 
                                      color = as.factor(Time_weeks))) +
  geom_smooth(aes(group = Time_weeks), method = "loess", se = FALSE, linewidth = 1) +
  geom_errorbar(aes(ymin = density_lower, ymax = density_upper), 
                width = 50, alpha = 0.5) +
  geom_point(size = 1, alpha = 0.7) +
  scale_color_manual(values = company_colors, name = "Time (Weeks)") +
  facet_grid(~ Electrode_Thickness) +
  labs(
    x = "Distance from implantation site (µm)", 
    y = "Cell density (normalized)"Clustering_UMAP
  ) +
  theme_classic() +
  theme(
    plot.title = element_text(size = 12, hjust = 0.5),
    axis.title = element_text(size = 12),
    axis.text = element_text(size = 10),
    legend.text = element_text(size = 8),
    legend.title = element_text(size = 8),
    legend.key.size = unit(1.5, "lines"),
    legend.position = "right",
    strip.text = element_text(size = 10)
  )
print(Fig2$plot_density_facet)

# ============================================================================
# End of Figure 2 script
# ============================================================================
cat("\n=== FIGURE 2 COMPLETE ===\n")
cat("Key plots stored in Fig2 list:\n")
cat("  - cor_area, cor_perimeter, cor_maxferet, cor_solidity\n")
cat("  - plot_density_all, plot_density_facet\n")
