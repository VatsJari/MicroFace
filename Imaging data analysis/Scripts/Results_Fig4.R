# RESTART YOUR R SESSION FIRST, THEN RUN THIS ENTIRE CODE

# Step 1: Set the Python environment BEFORE loading any other libraries
library(reticulate)

# Set the correct virtual environment FIRST
use_virtualenv("~/.virtualenvs/r-reticulate", required = TRUE)

# Verify it's using the right Python
cat("Using Python:", py_exe(), "\n")

# Now load other libraries
library(phateR)
library(Rmagic)

# Step 2: Verify phate is available
cat("\n=== VERIFYING PHATE INSTALLATION ===\n")
if(py_module_available("phate")) {
  cat("✓ phate module successfully found\n")
} else {
  cat("✗ phate module not found. Installing...\n")
  py_install("phate", pip = TRUE)
}

# Step 3: Now run PHATE
cat("\n=== RUNNING PHATE ===\n")

# Run all PHATE variations
cat("Running PHATE variations...\n")

# ============================================
# FIG4 - PHATE Analysis and Visualization
# ============================================

Fig4 <- list()

# ============================================
# 1. PHATE ANALYSIS
# ============================================

# Get data from ClusterAnalysis
Fig4$df_phate <- ClusterAnalysis$final_df_sampled

# Select feature columns for PHATE (adjust column indices as needed)
Fig4$feature_start_col <- which(colnames(Fig4$df_phate) == "Area_cell")[1]
if(is.na(Fig4$feature_start_col)) {
  # If Area_cell not found, use columns after metadata
  Fig4$metadata_cols <- c("Cell_ID", "UMAP1", "UMAP2", "PC1", "PC2", "PC3", "Cluster",
                          "FileName_Original_Iba1_cell", "Animal_No", "Time_weeks", 
                          "Electrode_Thickness", "SubImage", "ImageNumber_cell", 
                          "Condition_cell", "Center_X_soma", "Center_Y_soma", 
                          "Injury_x", "Injury_y", "radial_dist", "bin_number", 
                          "bin_range", "Bin_Number_New", "bin_range_new", "Impact_Region")
  Fig4$feature_cols <- setdiff(colnames(Fig4$df_phate), Fig4$metadata_cols)
} else {
  Fig4$feature_cols <- colnames(Fig4$df_phate)[Fig4$feature_start_col:ncol(Fig4$df_phate)]
}

cat("\n=== RUNNING PHATE ANALYSIS ===\n")
cat("Using", length(Fig4$feature_cols), "features for PHATE\n")

# Normalize data (using library.size.normalize from Rmagic if available)
if (requireNamespace("Rmagic", quietly = TRUE)) {
  Fig4$df_phate_norm <- Rmagic::library.size.normalize(Fig4$df_phate[, Fig4$feature_cols])
} else {
  # Simple normalization if Rmagic not available
  Fig4$df_phate_norm <- Fig4$df_phate[, Fig4$feature_cols]
  Fig4$df_phate_norm <- scale(Fig4$df_phate_norm)
}

# Run PHATE with different dimensions
cat("\nRunning PHATE (2D)...\n")
Fig4$phate_2d <- phate(Fig4$df_phate_norm,
                       ndim = 2,
                       knn = 30,
                       t = 'auto',
                       gamma = 1,
                       n.jobs = -1,
                       verbose = 0)

cat("Running PHATE (3D)...\n")
Fig4$phate_3d <- phate(Fig4$df_phate_norm,
                       ndim = 3,
                       knn = 30,
                       t = 'auto',
                       gamma = 0.5,
                       n.jobs = -1,
                       verbose = 0)

# Extract coordinates
Fig4$phate_2d_coords <- as.data.frame(Fig4$phate_2d)
colnames(Fig4$phate_2d_coords) <- c("PHATE1", "PHATE2")

Fig4$phate_3d_coords <- as.data.frame(Fig4$phate_3d)
colnames(Fig4$phate_3d_coords) <- c("PHATE1", "PHATE2", "PHATE3")

# Add to dataframe
Fig4$df_phate$PHATE1_2D <- Fig4$phate_2d_coords$PHATE1
Fig4$df_phate$PHATE2_2D <- Fig4$phate_2d_coords$PHATE2
Fig4$df_phate$PHATE1_3D <- Fig4$phate_3d_coords$PHATE1
Fig4$df_phate$PHATE2_3D <- Fig4$phate_3d_coords$PHATE2
Fig4$df_phate$PHATE3_3D <- Fig4$phate_3d_coords$PHATE3

# ============================================
# 2. 2D PHATE PLOTS
# ============================================

cat("\n=== CREATING 2D PHATE PLOTS ===\n")

# Define cluster colors
Fig4$n_clusters <- length(unique(Fig4$df_phate$Cluster))

# Plot 1: PHATE 2D colored by Cluster
Fig4$phate_2d_cluster <- ggplot(Fig4$df_phate, aes(x = PHATE1_2D, y = PHATE2_2D, color = Cluster)) +
  geom_point(size = 0.1, alpha = 0.7) +
  scale_color_manual(values = morpho_colours) +
  theme_classic() +
  labs(
    title = "PHATE 2D - Colored by Cluster",
    x = "PHATE1", y = "PHATE2"
  ) +
  theme(
    plot.title = element_text(size = 14, hjust = 0.5, face = "bold"),
    axis.title = element_text(size = 12, face = "bold"),
    legend.position = "right",
    legend.title = element_text(face = "bold"),
    legend.key.size = unit(0.8, "lines")
  )

print(Fig4$phate_2d_cluster)

# Plot 2: PHATE 2D colored by Impact Region
if ("Impact_Region" %in% colnames(Fig4$df_phate)) {
  Fig4$phate_2d_region <- ggplot(Fig4$df_phate, aes(x = PHATE1_2D, y = PHATE2_2D, color = Impact_Region)) +
    geom_point(size = 0.5, alpha = 0.7) +
    scale_color_manual(values = c("Close" = "#E66F74", "Middle" = "gray70", "Far" = "#A4D38F")) +
    theme_classic() +
    labs(
      title = "PHATE 2D - Colored by Impact Region",
      x = "PHATE1", y = "PHATE2"
    ) +
    theme(
      plot.title = element_text(size = 14, hjust = 0.5, face = "bold"),
      axis.title = element_text(size = 12, face = "bold"),
      legend.position = "right"
    )
  
  print(Fig4$phate_2d_region)
}

# Plot 3: PHATE 2D colored by Time
if ("Time_weeks" %in% colnames(Fig4$df_phate)) {
  Fig4$phate_2d_time <- ggplot(Fig4$df_phate, aes(x = PHATE1_2D, y = PHATE2_2D, color = as.factor(Time_weeks))) +
    geom_point(size = 0.5, alpha = 0.7) +
    scale_color_viridis_d() +
    theme_classic() +
    labs(
      title = "PHATE 2D - Colored by Time (weeks)",
      x = "PHATE1", y = "PHATE2",
      color = "Weeks"
    ) +
    theme(
      plot.title = element_text(size = 14, hjust = 0.5, face = "bold"),
      axis.title = element_text(size = 12, face = "bold"),
      legend.position = "right"
    )
  
  print(Fig4$phate_2d_time)
}

# Plot 4: PHATE 2D faceted by Cluster
Fig4$phate_2d_facet <- ggplot(Fig4$df_phate, aes(x = PHATE1_2D, y = PHATE2_2D, color = Cluster)) +
  geom_point(size = 0.3, alpha = 0.6) +
  scale_color_manual(values = morpho_colours) +
  facet_wrap(~Cluster, ncol = 4) +
  theme_classic() +
  labs(
    title = "PHATE 2D - Faceted by Cluster",
    x = "PHATE1", y = "PHATE2"
  ) +
  theme(
    plot.title = element_text(size = 14, hjust = 0.5, face = "bold"),
    strip.text = element_text(size = 10, face = "bold"),
    legend.position = "none",
    axis.text = element_text(size = 8)
  )

print(Fig4$phate_2d_facet)

# ============================================
# 3. 3D PHATE PLOTS
# ============================================

cat("\n=== CREATING 3D PHATE PLOTS ===\n")

# Option 1: Plotly 3D (interactive)
if (requireNamespace("plotly", quietly = TRUE)) {
  library(plotly)
  
  Fig4$phate_3d_plotly <- plot_ly(Fig4$df_phate, 
                                  x = ~PHATE1_3D, 
                                  y = ~PHATE2_3D, 
                                  z = ~PHATE3_3D,
                                  color = ~Cluster,
                                  colors = morpho_colours,
                                  type = "scatter3d",
                                  mode = "markers",
                                  marker = list(size = 2),
                                  text = ~paste('Cluster:', Cluster,
                                                '<br>Region:', Impact_Region,
                                                '<br>Time:', Time_weeks),
                                  hoverinfo = 'text') %>%
    layout(
      title = "PHATE 3D - Colored by Cluster",
      scene = list(
        xaxis = list(title = 'PHATE1'),
        yaxis = list(title = 'PHATE2'),
        zaxis = list(title = 'PHATE3'),
        camera = list(eye = list(x = 1.5, y = 1.5, z = 1.5))
      )
    )
  
  Fig4$phate_3d_plotly  # This will display in Viewer if interactive
  
  # Save as HTML for sharing
  # htmlwidgets::saveWidget(Fig4$phate_3d_plotly, "PHATE_3D_Cluster.html")
}

# Option 2: scatterplot3d (static)
if (requireNamespace("scatterplot3d", quietly = TRUE)) {
  library(scatterplot3d)
  
  # Create a new plotting window
  dev.new(width = 10, height = 8)
  
  # Convert cluster to numeric for coloring
  Fig4$cluster_numeric <- as.numeric(Fig4$df_phate$Cluster)
  
  Fig4$phate_3d_scatter <- scatterplot3d(
    x = Fig4$df_phate$PHATE1_3D,
    y = Fig4$df_phate$PHATE2_3D,
    z = Fig4$df_phate$PHATE3_3D,
    color = Fig4$cluster_colors[Fig4$cluster_numeric],
    pch = 16,
    cex.symbols = 0.5,
    xlab = "PHATE1",
    ylab = "PHATE2",
    zlab = "PHATE3",
    main = "PHATE 3D - Colored by Cluster",
    angle = 45
  )
  
  # Add legend
  legend("topright", 
         legend = levels(Fig4$df_phate$Cluster),
         col = Fig4$cluster_colors[1:Fig4$n_clusters],
         pch = 16,
         title = "Cluster",
         cex = 0.8)
}

# Option 3: rgl (rotatable 3D)
if (requireNamespace("rgl", quietly = TRUE)) {
  library(rgl)
  
  # Clear any existing plots
  rgl::clear3d()
  
  # Create color vector
  Fig4$colors_3d <- Fig4$cluster_colors[as.numeric(Fig4$df_phate$Cluster)]
  
  # Plot 3D points
  rgl::plot3d(
    x = Fig4$df_phate$PHATE1_3D,
    y = Fig4$df_phate$PHATE2_3D,
    z = Fig4$df_phate$PHATE3_3D,
    col = Fig4$colors_3d,
    size = 3,
    xlab = "PHATE1",
    ylab = "PHATE2",
    zlab = "PHATE3",
    main = "PHATE 3D"
  )
  
  # Add legend
  rgl::legend3d("topright", 
                legend = levels(Fig4$df_phate$Cluster),
                col = Fig4$cluster_colors[1:Fig4$n_clusters],
                pch = 16)
  
  # Save snapshot
  # rgl::rgl.snapshot("PHATE_3D_rgl.png")
}

# ============================================
# 4. 2D PHATE with Density Contours
# ============================================

Fig4$phate_2d_density <- ggplot(Fig4$df_phate, aes(x = PHATE1_2D, y = PHATE2_2D)) +
  stat_density_2d(aes(fill = after_stat(density)), geom = "raster", contour = FALSE) +
  scale_fill_gradientn(colors = c("white", "#E66F74", "#A4D38F", "#4DAF4A")) +
  geom_density2d(color = "white", alpha = 0.5, linewidth = 0.2) +
  theme_classic() +
  labs(
    title = "PHATE 2D - Density Plot",
    x = "PHATE1", y = "PHATE2"
  ) +
  theme(
    plot.title = element_text(size = 14, hjust = 0.5, face = "bold"),
    axis.title = element_text(size = 12, face = "bold")
  )

print(Fig4$phate_2d_density)

# ============================================
# 5. PHATE by Cluster Summary Statistics
# ============================================

Fig4$cluster_summary <- Fig4$df_phate %>%
  group_by(Cluster) %>%
  summarise(
    n_cells = n(),
    mean_PHATE1 = mean(PHATE1_2D),
    mean_PHATE2 = mean(PHATE2_2D),
    sd_PHATE1 = sd(PHATE1_2D),
    sd_PHATE2 = sd(PHATE2_2D),
    .groups = "drop"
  )

cat("\n=== CLUSTER SUMMARY IN PHATE SPACE ===\n")
print(Fig4$cluster_summary)

# ============================================
# 6. Combined Figure
# ============================================

if (requireNamespace("patchwork", quietly = TRUE)) {
  library(patchwork)
  
  Fig4$combined_2d <- (Fig4$phate_2d_cluster | Fig4$phate_2d_region) /
    (Fig4$phate_2d_time | Fig4$phate_2d_density) +
    plot_annotation(
      title = "Figure 4: PHATE Analysis",
      subtitle = paste("2D PHATE with", Fig4$n_clusters, "clusters"),
      theme = theme(
        plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 12, hjust = 0.5)
      )
    )
  
  print(Fig4$combined_2d)
}

# ============================================
# 7. Save Results
# ============================================

# Save 2D plots
# ggsave("Fig4_PHATE_2D_Cluster.png", Fig4$phate_2d_cluster, width = 8, height = 6, dpi = 300)
# ggsave("Fig4_PHATE_2D_Region.png", Fig4$phate_2d_region, width = 8, height = 6, dpi = 300)
# ggsave("Fig4_PHATE_2D_Combined.png", Fig4$combined_2d, width = 14, height = 10, dpi = 300)

# ============================================
# 8. Summary
# ============================================

Fig4$summary <- list(
  n_cells = nrow(Fig4$df_phate),
  n_clusters = Fig4$n_clusters,
  n_features = length(Fig4$feature_cols),
  phate_2d_range = list(
    PHATE1 = range(Fig4$df_phate$PHATE1_2D),
    PHATE2 = range(Fig4$df_phate$PHATE2_2D)
  ),
  phate_3d_range = list(
    PHATE1 = range(Fig4$df_phate$PHATE1_3D),
    PHATE2 = range(Fig4$df_phate$PHATE2_3D),
    PHATE3 = range(Fig4$df_phate$PHATE3_3D)
  )
)

cat("\n=== FIG4 SUMMARY ===\n")
cat("Cells analyzed:", Fig4$summary$n_cells, "\n")
cat("Number of clusters:", Fig4$summary$n_clusters, "\n")
cat("Features used:", Fig4$summary$n_features, "\n")

cat("\n=== FIG4 COMPLETE ===\n")
cat("Available plots:\n")
cat("  - Fig4$phate_2d_cluster: 2D PHATE colored by cluster\n")
cat("  - Fig4$phate_2d_region: 2D PHATE colored by region\n")
cat("  - Fig4$phate_2d_time: 2D PHATE colored by time\n")
cat("  - Fig4$phate_2d_facet: 2D PHATE faceted by cluster\n")
cat("  - Fig4$phate_2d_density: 2D PHATE with density contours\n")
cat("  - Fig4$phate_3d_plotly: Interactive 3D PHATE (if plotly installed)\n")
cat("  - Fig4$combined_2d: Combined 2D plots\n")





# ============================================
# FIG4 - Top Parameters by Cluster (Violin Plots)
# ============================================

# Using the same dataframe from Fig4
Fig4$df_violin <- ClusterAnalysis$final_df_sampled

# ============================================
# 1. IDENTIFY TOP PARAMETERS BY CLUSTER VARIATION
# ============================================

# Identify parameter columns (exclude metadata)
Fig4$metadata_cols_violin <- c("Cell_ID", "UMAP1", "UMAP2", "PC1", "PC2", "PC3",
                               "FileName_Original_Iba1_cell", "Animal_No", "Time_weeks", 
                               "Electrode_Thickness", "SubImage", "ImageNumber_cell", 
                               "Condition_cell", "Center_X_soma", "Center_Y_soma", 
                               "Injury_x", "Injury_y", "radial_dist", "bin_number", 
                               "bin_range", "Bin_Number_New", "bin_range_new", 
                               "Impact_Region", "Cluster", "PHATE1_2D", "PHATE2_2D", 
                               "PHATE1_3D", "PHATE2_3D", "PHATE3_3D")

Fig4$all_params_violin <- Fig4$df_violin %>%
  dplyr::select(-one_of(Fig4$metadata_cols_violin))

cat("\n=== TOP PARAMETERS BY CLUSTER ===\n")
cat("Total parameters found:", ncol(Fig4$all_params_violin), "\n")

# Calculate variance across clusters to find most differentiating parameters
Fig4$param_variance_cluster <- Fig4$df_violin %>%
  group_by(Cluster) %>%
  summarise(across(all_of(colnames(Fig4$all_params_violin)), ~ mean(.x, na.rm = TRUE))) %>%
  dplyr::select(-Cluster) %>%
  summarise(across(everything(), var, na.rm = TRUE)) %>%
  pivot_longer(everything(), names_to = "Parameter", values_to = "Variance") %>%
  arrange(desc(Variance))

# Get top 10 most varying parameters across clusters
Fig4$top10_params_cluster <- Fig4$param_variance_cluster$Parameter[1:10]
cat("\nTop 10 parameters varying most across clusters:\n")
print(Fig4$top10_params_cluster)

# ============================================
# 2. CREATE VIOLIN PLOTS FOR TOP 10 PARAMETERS
# ============================================

# Define cluster colors
Fig4$n_clusters <- length(unique(Fig4$df_violin$Cluster))
Fig4$cluster_colors_violin <- morpho_colours

# Function to create violin plot for a parameter
Fig4$create_violin_plot <- function(data, param, param_clean_name) {
  
  ggplot(data, aes(x = Cluster, y = .data[[param]], fill = Cluster)) +
    geom_violin(trim = FALSE, alpha = 0.7) +
    geom_boxplot(width = 0.1, fill = "white", alpha = 0.5, outlier.size = 0.5) +
   # geom_jitter(width = 0.2, size = 0.2, alpha = 0.3) +
    scale_fill_manual(values = Fig4$cluster_colors_violin) +
    theme_classic() +
    labs(
      title = param_clean_name,
      x = "Cluster",
      y = param_clean_name
    ) +
    theme(
      plot.title = element_text(size = 12, hjust = 0.5, face = "bold"),
      axis.title.x = element_text(size = 10, face = "bold"),
      axis.title.y = element_text(size = 10, face = "bold"),
      axis.text.x = element_text(size = 9, angle = 45, hjust = 1),
      axis.text.y = element_text(size = 9),
      legend.position = "none"
    )
}

# Create clean parameter names
Fig4$param_names_clean <- gsub("_", " ", Fig4$top10_params_cluster)
Fig4$param_names_clean <- gsub("cell", "(Cell)", Fig4$param_names_clean)
Fig4$param_names_clean <- gsub("soma", "(Soma)", Fig4$param_names_clean)
Fig4$param_names_clean <- gsub("ratio", "Ratio", Fig4$param_names_clean)

# Generate violin plots for top 10 parameters
Fig4$violin_plots <- list()

for(i in 1:length(Fig4$top10_params_cluster)) {
  param <- Fig4$top10_params_cluster[i]
  param_clean <- Fig4$param_names_clean[i]
  
  Fig4$violin_plots[[i]] <- Fig4$create_violin_plot(Fig4$df_violin, param, param_clean)
  
  # Print each plot individually
  print(Fig4$violin_plots[[i]])
}

# ============================================
# 3. ARRANGE VIOLIN PLOTS IN A GRID
# ============================================

if (requireNamespace("patchwork", quietly = TRUE)) {
  library(patchwork)
  
  # Arrange in 2x5 grid for 10 plots
  Fig4$violin_grid <- wrap_plots(Fig4$violin_plots, ncol = 2) +
    plot_annotation(
      title = "Top 10 Parameters by Cluster",
      subtitle = paste("Distribution across", Fig4$n_clusters, "clusters"),
      theme = theme(
        plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 12, hjust = 0.5)
      )
    )
  
  print(Fig4$violin_grid)
  
  # Save the grid
  # ggsave("Fig4_Violin_Grid_Top10.png", Fig4$violin_grid, width = 14, height = 20, dpi = 300)
}

# ============================================
# 4. SUMMARY STATISTICS FOR TOP PARAMETERS
# ============================================

Fig4$cluster_stats <- Fig4$df_violin %>%
  group_by(Cluster) %>%
  summarise(across(all_of(Fig4$top10_params_cluster), 
                   list(mean = ~mean(.x, na.rm = TRUE),
                        sd = ~sd(.x, na.rm = TRUE),
                        median = ~median(.x, na.rm = TRUE)),
                   .names = "{.col}_{.fn}")) %>%
  pivot_longer(-Cluster, names_to = "Metric", values_to = "Value") %>%
  separate(Metric, into = c("Parameter", "Stat"), sep = "_") %>%
  pivot_wider(names_from = Stat, values_from = Value)

cat("\n=== CLUSTER STATISTICS FOR TOP 10 PARAMETERS ===\n")
print(Fig4$cluster_stats)

# ============================================
# 5. HEATMAP OF MEAN VALUES BY CLUSTER
# ============================================

# Calculate mean values for top parameters by cluster
Fig4$mean_by_cluster <- Fig4$df_violin %>%
  group_by(Cluster) %>%
  summarise(across(all_of(Fig4$top10_params_cluster), ~ mean(.x, na.rm = TRUE)))

# Reshape for heatmap
Fig4$heatmap_cluster_data <- reshape2::melt(Fig4$mean_by_cluster, id.vars = "Cluster")
colnames(Fig4$heatmap_cluster_data) <- c("Cluster", "Parameter", "Mean_Value")

# Calculate z-scores across clusters
Fig4$heatmap_cluster_data <- Fig4$heatmap_cluster_data %>%
  group_by(Parameter) %>%
  mutate(Z_Score = scale(Mean_Value)[,1]) %>%
  ungroup()

# Create clean parameter names
Fig4$heatmap_cluster_data$Parameter_Clean <- gsub("_", " ", Fig4$heatmap_cluster_data$Parameter)
Fig4$heatmap_cluster_data$Parameter_Clean <- gsub("cell", "(Cell)", Fig4$heatmap_cluster_data$Parameter_Clean)
Fig4$heatmap_cluster_data$Parameter_Clean <- gsub("soma", "(Soma)", Fig4$heatmap_cluster_data$Parameter_Clean)

# Create heatmap
Fig4$cluster_heatmap <- ggplot(Fig4$heatmap_cluster_data, 
                               aes(x = Cluster, 
                                   y = reorder(Parameter_Clean, Z_Score), 
                                   fill = Z_Score)) +
  geom_tile(color = "white", linewidth = 0.5) +
 # geom_text(aes(label = round(Mean_Value, 2)), size = 3, fontface = "bold") +
  scale_fill_gradient2(
    low = "blue",
    mid = "black",
    high = "green",
    midpoint = 0,
    name = "Z-Score"
  ) +
  theme_classic() +
  labs(
    title = "Top 10 Parameters: Mean Values by Cluster",
    x = "Cluster",
    y = "Parameter"
  ) +
  theme(
    plot.title = element_text(size = 14, hjust = 0.5, face = "bold"),
    axis.title.x = element_text(size = 12, face = "bold"),
    axis.title.y = element_text(size = 12, face = "bold"),
    axis.text.x = element_text(size = 11, face = "bold"),
    axis.text.y = element_text(size = 10, face = "bold"),
    legend.position = "right"
  )

print(Fig4$cluster_heatmap)

# ============================================
# 6. COMPLETE FIGURE WITH VIOLINS AND HEATMAP
# ============================================

if (requireNamespace("patchwork", quietly = TRUE)) {
  
  # Take first 6 violin plots for a more compact figure with heatmap
  Fig4$violin_subset <- wrap_plots(Fig4$violin_plots[1:6], ncol = 3)
  
  Fig4$complete_figure <- (Fig4$violin_subset) /
    (Fig4$cluster_heatmap) +
    plot_annotation(
      title = "Figure 4: Top Parameters by Cluster",
      subtitle = paste("Violin plots (top 6) and heatmap of mean values for top 10 parameters"),
      theme = theme(
        plot.title = element_text(size = 18, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 12, hjust = 0.5)
      )
    )
  
  print(Fig4$complete_figure)
  
  # Save complete figure
  # ggsave("Fig4_Complete_Top10_Parameters.png", Fig4$complete_figure, width = 16, height = 14, dpi = 300)
}

# ============================================
# 7. SUMMARY STATISTICS
# ============================================





# ============================================
# FIG4 - Cluster Proportion Heatmap (Fixed Bins, Clustered Clusters)
# ============================================

library(pheatmap)
library(viridis)
library(dendsort)

# Get data from ClusterAnalysis
Fig4$df_heatmap <- ClusterAnalysis$final_df_full

# ============================================
# 1. PREPARE DATA FOR HEATMAP
# ============================================

# Filter bins <= 16 (or adjust as needed)
Fig4$df_heatmap <- Fig4$df_heatmap %>%
  filter(Bin_Number_New <= 20) %>%
  filter(!is.na(Cluster) & !is.na(Bin_Number_New))

cat("\n=== CLUSTER PROPORTION HEATMAP ===\n")
cat("Total cells:", nrow(Fig4$df_heatmap), "\n")
cat("Bin range:", min(Fig4$df_heatmap$Bin_Number_New), "to", max(Fig4$df_heatmap$Bin_Number_New), "\n")
cat("Number of clusters:", length(unique(Fig4$df_heatmap$Cluster)), "\n")

# Create contingency table (Cluster x Bin)
Fig4$count_table <- table(Fig4$df_heatmap$Cluster, 
                          Fig4$df_heatmap$Bin_Number_New)

# Calculate proportions within each bin (columns sum to 100%)
Fig4$prop_table <- prop.table(Fig4$count_table, margin = 2) * 100

# TRANSPOSE so bins are on Y-axis and clusters on X-axis
Fig4$heatmap_matrix <- t(Fig4$prop_table)

# Ensure bins are in correct order (1 to max)
Fig4$heatmap_matrix <- Fig4$heatmap_matrix[order(as.numeric(rownames(Fig4$heatmap_matrix))), ]

cat("\nHeatmap dimensions (Bins x Clusters):", dim(Fig4$heatmap_matrix), "\n")
cat("Bins:", rownames(Fig4$heatmap_matrix), "\n")
cat("Clusters:", colnames(Fig4$heatmap_matrix), "\n")

# ============================================
# 2. CREATE DENDROGRAM FOR CLUSTERS (X-AXIS)
# ============================================

# Calculate distance matrix between clusters (based on their distribution across bins)
# Using correlation distance to group clusters with similar patterns
Fig4$cluster_dist <- dist(t(Fig4$heatmap_matrix), method = "euclidean")

# Hierarchical clustering of clusters
Fig4$cluster_hclust <- hclust(Fig4$cluster_dist, method = "ward.D2")

# Sort dendrogram for better visualization
Fig4$cluster_dendro <- as.hclust(dendsort(as.dendrogram(Fig4$cluster_hclust)))

# Plot dendrogram
dev.new(width = 10, height = 4)
par(mar = c(5, 4, 4, 2))
plot(Fig4$cluster_dendro, 
     main = "Cluster Dendrogram (based on bin distribution)",
     xlab = "Clusters", 
     sub = "",
     cex = 0.8)
Fig4$cluster_dendro_plot <- recordPlot()

# ============================================
# 3. CREATE COLOR BREAKS
# ============================================

# Create quantile-based breaks for better color distribution
Fig4$quantile_breaks <- function(xs, n = 100) {
  breaks <- quantile(xs, probs = seq(0, 1, length.out = n), na.rm = TRUE)
  # Remove duplicate breaks
  breaks[!duplicated(round(breaks, 10))]
}

Fig4$breaks <- Fig4$quantile_breaks(Fig4$heatmap_matrix, n = 100)

# ============================================
# 4. CREATE HEATMAP WITH PHEATMAP
# ============================================

# Define color palette (white -> red -> green)
Fig4$heatmap_colors <- colorRampPalette(c("white", "#E66F74", "#A4D38F", "#4DAF4A"))(length(Fig4$breaks) - 1)

# Create the heatmap
Fig4$pheatmap <- pheatmap(
  Fig4$heatmap_matrix,
  color = Fig4$heatmap_colors,
  breaks = Fig4$breaks,
  
  # Clustering
  cluster_rows = FALSE,           # Bins fixed (no clustering)
  cluster_cols = Fig4$cluster_dendro,  # Clusters clustered
  cutree_cols = 4,                 # Optional: cut dendrogram into 4 groups
  
  # Labels
  main = "Cluster Distribution Across Bins\n(Bins fixed, Clusters clustered)",
  fontsize = 10,
  fontsize_row = 10,
  fontsize_col = 10,
  
  # Display values
  display_numbers = F,
  number_format = "%.1f%%",
  number_color = "black",
  fontsize_number = 8,
  
  # Angle for column labels
  angle_col = 45,
  
  # Legend
  legend = TRUE,
  legend_breaks = seq(0, max(Fig4$heatmap_matrix, na.rm = TRUE), length.out = 5),
  legend_labels = paste0(round(seq(0, max(Fig4$heatmap_matrix, na.rm = TRUE), length.out = 5), 1), "%"),
  
  # Borders
  border_color = "grey80"
)

# ============================================
# 5. ALTERNATIVE HEATMAP WITH DIFFERENT COLOR SCHEMES
# ============================================

# Version 2: Using viridis colors
Fig4$pheatmap_viridis <- pheatmap(
  Fig4$heatmap_matrix,
  color = viridis(length(Fig4$breaks) - 1),
  breaks = Fig4$breaks,
  cluster_rows = FALSE,
  #cluster_cols = Fig4$cluster_dendro,
  #cutree_cols = 4,
  main = "Cluster Distribution - Viridis Scale",
  fontsize = 10,
  display_numbers = F,
  number_format = "%.1f%%",
  angle_col = 45,
  border_color = "grey80"
)

# Version 3: Using custom red-blue palette
Fig4$pheatmap_custom <- pheatmap(
  Fig4$heatmap_matrix,
  color = colorRampPalette(c("#2166AC", "#F7F7F7", "#B2182B"))(100),
  breaks = Fig4$breaks,
  cluster_rows = FALSE,
  cluster_cols = Fig4$cluster_dendro,
  cutree_cols = 4,
  main = "Cluster Distribution - Custom Palette",
  fontsize = 10,
  display_numbers = TRUE,
  number_format = "%.1f%%",
  angle_col = 45,
  border_color = "grey80"
)

# ============================================
# 6. EXTRACT CLUSTER ORDER FOR REFERENCE
# ============================================

# Get the order of clusters from dendrogram
Fig4$cluster_order <- colnames(Fig4$heatmap_matrix)[Fig4$cluster_dendro$order]
cat("\n=== CLUSTER ORDER FROM DENDROGRAM (left to right) ===\n")
print(Fig4$cluster_order)

# Get cluster groups from cutting dendrogram
Fig4$cluster_groups <- cutree(Fig4$cluster_dendro, k = 4)
cat("\n=== CLUSTER GROUPS ===\n")
print(Fig4$cluster_groups)


# ============================================
# 8. ADD ROW AND COLUMN ANNOTATIONS
# ============================================

# Create annotation for clusters (based on dendrogram groups)
Fig4$cluster_annotation <- data.frame(
  Cluster_Group = factor(cutree(Fig4$cluster_dendro, k = 4))
)
rownames(Fig4$cluster_annotation) <- colnames(Fig4$heatmap_matrix)

# Create annotation for bins (distance)
Fig4$bin_annotation <- data.frame(
  Distance_mm = paste0(rownames(Fig4$heatmap_matrix), " (", 
                       as.numeric(rownames(Fig4$heatmap_matrix)) * 139, "µm)")
)
rownames(Fig4$bin_annotation) <- rownames(Fig4$heatmap_matrix)

# Heatmap with annotations
Fig4$pheatmap_annotated <- pheatmap(
  Fig4$heatmap_matrix,
  color = Fig4$heatmap_colors,
  breaks = Fig4$breaks,
  cluster_rows = FALSE,
  cluster_cols = Fig4$cluster_dendro,
  annotation_col = Fig4$cluster_annotation,
  annotation_colors = list(
    Cluster_Group = c("1" = "#E66F74", "2" = "#A4D38F", 
                      "3" = "#4DAF4A", "4" = "#377EB8")
  ),
  main = "Cluster Distribution with Annotations",
  fontsize = 10,
  display_numbers = TRUE,
  number_format = "%.1f%%",
  angle_col = 45,
  border_color = "grey80"
)

# ============================================
# 9. SUMMARY STATISTICS
# ============================================

# Calculate dominant cluster per bin
Fig4$dominant_cluster <- data.frame(
  Bin = rownames(Fig4$heatmap_matrix),
  Dominant_Cluster = apply(Fig4$heatmap_matrix, 1, function(x) {
    colnames(Fig4$heatmap_matrix)[which.max(x)]
  }),
  Percentage = apply(Fig4$heatmap_matrix, 1, max)
)

cat("\n=== DOMINANT CLUSTER PER BIN ===\n")
print(Fig4$dominant_cluster)

# Calculate cluster distribution summary
Fig4$cluster_summary <- data.frame(
  Cluster = colnames(Fig4$heatmap_matrix),
  Mean_Percentage = colMeans(Fig4$heatmap_matrix),
  Max_Percentage = apply(Fig4$heatmap_matrix, 2, max),
  Min_Percentage = apply(Fig4$heatmap_matrix, 2, min),
  Bin_with_Max = apply(Fig4$heatmap_matrix, 2, function(x) {
    rownames(Fig4$heatmap_matrix)[which.max(x)]
  })
)

cat("\n=== CLUSTER SUMMARY ===\n")
print(Fig4$cluster_summary)

# ============================================
# 10. SAVE HEATMAP
# ============================================

# Save pheatmap as PNG
# png("Fig4_Cluster_Proportion_Heatmap.png", width = 10, height = 8, units = "in", res = 300)
# Fig4$pheatmap
# dev.off()

# Save ggplot version
# ggsave("Fig4_Cluster_Proportion_ggplot.png", Fig4$ggplot_heatmap, width = 10, height = 8, dpi = 300)

# ============================================
# 11. FINAL SUMMARY
# ============================================

Fig4$heatmap_summary <- list(
  n_bins = nrow(Fig4$heatmap_matrix),
  n_clusters = ncol(Fig4$heatmap_matrix),
  total_cells = sum(Fig4$count_table),
  bin_range = range(as.numeric(rownames(Fig4$heatmap_matrix))),
  cluster_order = Fig4$cluster_order,
  cluster_groups = Fig4$cluster_groups,
  dominant_clusters = Fig4$dominant_cluster
)

cat("\n=== FIG4 HEATMAP SUMMARY ===\n")
cat("Bins analyzed:", Fig4$heatmap_summary$n_bins, "\n")
cat("Clusters analyzed:", Fig4$heatmap_summary$n_clusters, "\n")
cat("Total cells:", Fig4$heatmap_summary$total_cells, "\n")
cat("\nAvailable heatmaps:\n")
cat("  - Fig4$pheatmap: Main pheatmap\n")
cat("  - Fig4$pheatmap_viridis: Viridis color scheme\n")
cat("  - Fig4$pheatmap_custom: Custom color palette\n")
cat("  - Fig4$pheatmap_annotated: With cluster annotations\n")
cat("  - Fig4$ggplot_heatmap: ggplot version\n")
cat("  - Fig4$cluster_dendro_plot: Dendrogram of clusters\n")
Fig4$violin_summary <- list(
  n_clusters = Fig4$n_clusters,
  n_parameters_analyzed = ncol(Fig4$all_params_violin),
  top10_parameters = Fig4$top10_params_cluster,
  top10_parameters_clean = Fig4$param_names_clean,
  cluster_sizes = table(Fig4$df_violin$Cluster)
)

cat("\n=== FIG4 VIOLIN PLOT SUMMARY ===\n")
cat("Number of clusters:", Fig4$violin_summary$n_clusters, "\n")
cat("Total parameters analyzed:", Fig4$violin_summary$n_parameters_analyzed, "\n")
cat("\nTop 10 parameters:\n")
for(i in 1:10) {
  cat(sprintf("  %d. %s\n", i, Fig4$violin_summary$top10_parameters_clean[i]))
}

cat("\n=== FIG4 COMPLETE ===\n")
cat("Available plots:\n")
cat("  - Fig4$violin_plots[[1:10]]: Individual violin plots\n")
cat("  - Fig4$violin_grid: Grid of all 10 violin plots\n")
cat("  - Fig4$cluster_heatmap: Heatmap of mean values by cluster\n")
cat("  - Fig4$complete_figure: Combined figure with violins and heatmap\n")



