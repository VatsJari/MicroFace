# ============================================================================
# FIGURE 4: PHATE, UMAP, Cluster Parameter Scoring, and Phenotype Analysis
# ============================================================================
# This script performs:
#   1. PHATE dimensionality reduction on morphological features.
#   2. UMAP visualization of clusters with centroid labels.
#   3. Heatmap of z‑scored feature means per cluster.
#   4. Heatmap of cluster proportions across radial bins (with dendrogram).
#   5. PHATE1 distribution per cluster.
#   6. Phenotype assignment, Z‑score heatmap, and bin proportion trends.
# All outputs are stored in the 'Fig4' list
# ============================================================================
# RESTART YOUR R SESSION FIRST, THEN RUN THIS ENTIRE CODE

# Step 1: Set the Python environment BEFORE loading any other libraries
library(reticulate)

# Set the correct virtual environment (adjust path if needed)
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

# ============================================================================
# Initialize Fig4 list
# ============================================================================
Fig4 <- list()

# ============================================================================
# Check required data objects
# ============================================================================
if (!exists("ClusterAnalysis")) {
  stop("ClusterAnalysis not found. Please run clustering script first.")
}
if (!exists("ClusterAnalysis_Filter")) {
  stop("ClusterAnalysis_Filter not found. Please run the filtering script first.")
}

# Use the filtered full dataset for most analyses
Fig4$df_full <- ClusterAnalysis_Filter$final_df_full
Fig4$df_sampled <- ClusterAnalysis_Filter$final_df_sampled  # optional, for PHATE

# ============================================================================
# 1. PHATE ANALYSIS (using sampled data for speed)
# ============================================================================
# If sampled data not available, use full but downsample internally
if (!is.null(Fig4$df_sampled) && nrow(Fig4$df_sampled) > 0) {
  df_phate_input <- Fig4$df_sampled
} else {
  # Downsample full data to 30k cells for PHATE
  set.seed(123)
  idx <- sample(1:nrow(Fig4$df_full), min(30000, nrow(Fig4$df_full)))
  df_phate_input <- Fig4$df_full[idx, ]
}
Fig4$df_phate <- df_phate_input

# Identify feature columns for PHATE (exclude metadata and coordinates)
metadata_cols <- c("Cell_ID", "UMAP1", "UMAP2", "PC1", "PC2", "PC3", "Cluster",
                   "FileName_Original_Iba1_cell", "Animal_No", "Time_weeks",
                   "Electrode_Thickness", "SubImage", "ImageNumber_cell",
                   "Condition_cell", "Center_X_soma", "Center_Y_soma",
                   "Injury_x", "Injury_y", "radial_dist", "bin_number",
                   "bin_range", "Bin_Number_New", "bin_range_new", "Impact_Region")
feature_cols <- setdiff(colnames(Fig4$df_phate), metadata_cols)
feature_cols <- feature_cols[sapply(Fig4$df_phate[, feature_cols], is.numeric)]
Fig4$feature_cols <- feature_cols
cat("\nUsing", length(feature_cols), "features for PHATE\n")

# Normalize data (library size normalization or simple scaling)
if (requireNamespace("Rmagic", quietly = TRUE)) {
  Fig4$df_phate_norm <- Rmagic::library.size.normalize(Fig4$df_phate[, feature_cols])
} else {
  Fig4$df_phate_norm <- scale(Fig4$df_phate[, feature_cols])
}

# Run PHATE 2D and 3D
cat("\nRunning PHATE (2D)...\n")
Fig4$phate_2d <- phate(Fig4$df_phate_norm,
                       ndim = 2,
                       knn = 10,
                       t = 70, decay = 150, gamma = 0.6,
                       n.jobs = -1, verbose = 1)

cat("Running PHATE (3D)...\n")
Fig4$phate_3d <- phate(Fig4$df_phate_norm,
                       ndim = 3,
                       knn = 10,
                       t = 70, decay = 150, gamma = 0.6,
                       n.jobs = -1, verbose = 1)

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


Fig4$phate_cluster <- ggplot(Fig4$df_phate, aes(x = PHATE1_2D, y = PHATE2_2D, color = Cluster)) +
  geom_point(size = 0.3, alpha = 0.7) +
  scale_color_manual(values = Fig4$cluster_colors) +
  theme_classic() +
  coord_fixed()+
  labs(title = "PHATE 2D by Cluster", x = "PHATE1", y = "PHATE2") +
  theme(legend.position = "right")
print(Fig4$phate_cluster)


# ============================================================================
# 2. UMAP PLOT BY CLUSTER WITH CENTROIDS AND LABELS
# ============================================================================
# Use full data for UMAP (coordinates already present)
if (!all(c("PHATE1_2D", "PHATE2_2D") %in% colnames(Fig4$df_phate))) {
  stop("UMAP coordinates not found in Fig4$df_phate")
}

# Define cluster colors (use morpho_colours if available)
if (exists("morpho_colours") && length(morpho_colours) >= length(unique(Fig4$df_phate$Cluster))) {
  Fig4$cluster_colors <- morpho_colours[1:length(unique(Fig4$df_phate$Cluster))]
} else {
  Fig4$cluster_colors <- colorRampPalette(RColorBrewer::brewer.pal(12, "Paired"))(length(unique(Fig4$df_phate$Cluster)))
}
names(Fig4$cluster_colors) <- levels(factor(Fig4$df_phate$Cluster))

# Compute centroids
centroids_umap <- Fig4$df_phate %>%
  group_by(Cluster) %>%
  summarise(PHATE1_2D = mean(PHATE1_2D, na.rm = TRUE),
            PHATE2_2D = mean(PHATE2_2D, na.rm = TRUE),
            .groups = "drop") %>%
  mutate(Cluster = factor(Cluster, levels = levels(factor(Fig4$df_phate$Cluster))))

# Assign text color from palette
centroids_umap$text_color <- Fig4$cluster_colors[as.numeric(centroids_umap$Cluster)]

Fig4$umap_cluster <- ggplot(Fig4$df_phate, aes(x = PHATE1_2D, y = PHATE2_2D, color = Cluster)) +
  geom_point(size = 0.1, alpha = 0.5, shape=".") +
  scale_color_manual(values = Fig4$cluster_colors) +
  theme_classic() +
  coord_fixed()+
  theme(legend.position = "none")

# Add centroid labels
Fig4$umap_cluster <- Fig4$umap_cluster +
  ggrepel::geom_label_repel(
    data = centroids_umap,
    aes(x = PHATE1_2D, y = PHATE2_2D, label = Cluster),
    fill = "white", color = centroids_umap$text_color,
    fontface = "bold", size = 4,
    box.padding = 0.5, point.padding = 0.2,
    show.legend = FALSE
  )

print(Fig4$umap_cluster)


# PHATE1 boxplot per cluster (ordered by median)
Fig4$phate1_boxplot <- ggplot(Fig4$df_phate,
                              aes(x = PHATE1_2D,
                                  color = Cluster,
                                  y = reorder(Cluster, PHATE1_2D, FUN = median)
                                  )) +
  geom_boxplot(alpha = 0.7, outlier.colour = "NA") +
  scale_color_manual(values = Fig4$cluster_colors) +
  theme_classic() +
  labs(x = "PHATE1", y = "Cluster") +
  theme(legend.position = "none")
print(Fig4$phate1_boxplot)


# ============================================================================
# 3. HEATMAP OF Z‑SCORED FEATURE MEANS PER CLUSTER
# ============================================================================
# Use full data
df_heat_features <- Fig4$df_sampled

# Identify parameter columns (exclude metadata)
metadata_cols_features <- c("Cell_ID", "UMAP1", "UMAP2","UMAP1.1", "UMAP2.1", "PC1", "PC2", "PC3",
                            "FileName_Original_Iba1_cell", "Animal_No", "Time_weeks",
                            "Electrode_Thickness", "SubImage", "ImageNumber_cell",
                            "Condition_cell", "Center_X_soma", "Center_Y_soma",
                            "Injury_x", "Injury_y", "radial_dist", "bin_number",
                            "bin_range", "Bin_Number_New", "bin_range_new",
                            "Impact_Region", "Cluster")
all_params <- df_heat_features %>%
  dplyr::select(-one_of(metadata_cols_features))

cat("\n=== TOP PARAMETERS BY CLUSTER ===\n")
cat("Total parameters found:", ncol(all_params), "\n")

# Calculate variance across clusters to find most differentiating parameters
param_variance <- df_heat_features %>%
  group_by(Cluster) %>%
  summarise(across(all_of(colnames(all_params)), ~ median(.x, na.rm = TRUE))) %>%
  dplyr::select(-Cluster) %>%
  summarise(across(everything(), var, na.rm = TRUE)) %>%
  pivot_longer(everything(), names_to = "Parameter", values_to = "Variance") %>%
  arrange(desc(Variance))

# Select top N parameters (e.g., 20)
n_top <- 30
top_params <- param_variance$Parameter[1:n_top]
Fig4$top_params <- top_params

# Calculate mean values for top parameters by cluster
mean_by_cluster <- df_heat_features %>%
  group_by(Cluster) %>%
  summarise(across(all_of(top_params), ~ median(.x, na.rm = TRUE)))

# Reshape for heatmap
heatmap_data <- reshape2::melt(mean_by_cluster, id.vars = "Cluster")
colnames(heatmap_data) <- c("Cluster", "Parameter", "Mean_Value")

# Calculate z‑scores across clusters (per parameter)
heatmap_data <- heatmap_data %>%
  group_by(Parameter) %>%
  mutate(Z_Score = scale(Mean_Value)[,1]) %>%
  ungroup()

# Create clean parameter names
heatmap_data$Parameter_Clean <- gsub("_", " ", heatmap_data$Parameter)
heatmap_data$Parameter_Clean <- gsub("cell", "(Cell)", heatmap_data$Parameter_Clean)
heatmap_data$Parameter_Clean <- gsub("soma", "(Soma)", heatmap_data$Parameter_Clean)

# Reorder parameters by Z‑score (optional, can use hierarchical clustering instead)
# Here we order by the mean Z‑score across clusters for a sensible default
param_order <- heatmap_data %>%
  group_by(Parameter) %>%
  summarise(avg_z = mean(Z_Score)) %>%
  arrange(avg_z) %>%
  pull(Parameter)
heatmap_data$Parameter <- factor(heatmap_data$Parameter, levels = param_order)
heatmap_data$Parameter_Clean <- factor(heatmap_data$Parameter_Clean, levels = unique(heatmap_data$Parameter_Clean[order(heatmap_data$Parameter)]))

# Create heatmap
Fig4$cluster_heatmap <- ggplot(heatmap_data, 
                               aes(x = Cluster, 
                                   y = Parameter_Clean, 
                                   fill = Z_Score)) +
  geom_tile(color = "white", linewidth = 0.5) +
  scale_fill_gradient2(
    low = "blue",
    mid = "white",
    high = "red",
    midpoint = 0,
    name = "Z‑Score"
  ) +
  theme_classic() +
  labs(
    x = "Cluster",
    y = "Parameter"
  ) +
  theme(
    axis.title.x = element_text(size = 6, face = "bold"),
    axis.title.y = element_text(size = 6, face = "bold"),
    axis.text.x = element_text(size = 6, angle = 45, hjust = 1),
    axis.text.y = element_text(size = 6),
    legend.position = "right"
  )

print(Fig4$cluster_heatmap)

# ============================================================================
# 4. FREQUENCY HEATMAP (Cluster proportion across bins) – Detailed version
# ============================================================================
Fig4$df_heatmap <- ClusterAnalysis$final_df_full

# ============================================
# 1. PREPARE DATA FOR HEATMAP
# ============================================
Fig4$df_heatmap <- Fig4$df_heatmap %>%
  filter(Bin_Number_New <= 20) %>%          # keep bins ≤20
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
Fig4$cluster_dist <- dist(t(Fig4$heatmap_matrix), method = "euclidean")

# Hierarchical clustering of clusters
Fig4$cluster_hclust <- hclust(Fig4$cluster_dist, method = "ward.D2")

# Sort dendrogram for better visualization
Fig4$cluster_dendro <- as.hclust(dendsort(as.dendrogram(Fig4$cluster_hclust)))

# Plot dendrogram
par(mar = c(5, 4, 4, 2))
plot(Fig4$cluster_dendro, 
     main = "Cluster Dendrogram (based on bin distribution)",
     xlab = "Clusters", 
     sub = "",
     cex = 0.8)
Fig4$cluster_dendro_plot <- recordPlot()  # store if needed

# ============================================
# 3. CREATE COLOR BREAKS
# ============================================
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



# Version 2: Using viridis colors
Fig4$pheatmap_viridis <- pheatmap(
  Fig4$heatmap_matrix,
  color = inferno(length(Fig4$breaks) + 2),
  breaks = Fig4$breaks,
  cluster_rows = FALSE,
  cluster_cols = Fig4$cluster_dendro,
  main = "Cluster Distribution - Viridis Scale",
  fontsize = 4,
  display_numbers = FALSE,
  number_format = "%.1f%%",
  angle_col = 45,
  border_color = "grey80"
)

# ============================================================================
# 5. PHATE PLOTS AND PHATE1 BOXPLOT PER CLUSTER
# ============================================================================

# Use full data for UMAP (coordinates already present)
if (!all(c("PHATE1_2D", "PHATE2_2D") %in% colnames(Fig4$df_phate))) {
  stop("PHATE coordinates not found in Fig4$df_phate")
}

# Define cluster colors (use morpho_colours if available)
if (exists("morpho_colours") && length(morpho_colours) >= length(unique(Fig4$df_phate$Cluster))) {
  Fig4$cluster_colors <- morpho_colours[1:length(unique(Fig4$df_phate$Cluster))]
} else {
  Fig4$cluster_colors <- colorRampPalette(RColorBrewer::brewer.pal(12, "Paired"))(length(unique(Fig4$df_phate$Cluster)))
}
names(Fig4$cluster_colors) <- levels(factor(Fig4$df_phate$Cluster))

# Compute centroids
centroids_phate <- Fig4$df_phate %>%
  group_by(Cluster) %>%
  summarise(PHATE1_2D = mean(PHATE1_2D, na.rm = TRUE),
            PHATE2_2D = mean(PHATE2_2D, na.rm = TRUE),
            .groups = "drop") %>%
  mutate(Cluster = factor(Cluster, levels = levels(factor(Fig4$df_phate$Cluster))))

# Assign text color from palette
centroids_phate$text_color <- Fig4$cluster_colors[as.numeric(centroids_phate$Cluster)]

Fig4$umap_cluster <- ggplot(Fig4$df_phate, aes(x = PHATE1_2D, y = PHATE2_2D, color = Cluster)) +
  geom_point(size = 0.1, alpha = 0.5, shape=".") +
  scale_color_manual(values = Fig4$cluster_colors) +
  theme_classic() +
  coord_fixed()+
  theme(legend.position = "none")

# Add centroid labels
Fig4$umap_cluster <- Fig4$umap_cluster +
  ggrepel::geom_label_repel(
    data = centroids_phate,
    aes(x = PHATE1_2D, y = PHATE2_2D, label = Cluster),
    fill = "white", color = centroids_phate$text_color,
    fontface = "bold", size = 4,
    box.padding = 0.5, point.padding = 0.2,
    show.legend = FALSE
  )

print(Fig4$umap_cluster)


# PHATE1 boxplot per cluster (ordered by median)
Fig4$phate1_boxplot <- ggplot(Fig4$df_phate,
                              aes(x = PHATE1_2D,
                                  color = Cluster,
                                  y = reorder(Cluster, PHATE1_2D, FUN = median)
                              )) +
  geom_boxplot(alpha = 0.7, outlier.colour = "NA") +
  scale_color_manual(values = Fig4$cluster_colors) +
  theme_classic() +
  labs(x = "PHATE1", y = "Cluster") +
  theme(legend.position = "none")
print(Fig4$phate1_boxplot)



# ============================================================================
# 6. PHENOTYPE ANNOTATION AND PHENOTYPE PLOTS
# ============================================================================
# Assign phenotypes based on cluster numbers (user-defined mapping)
Fig4$df_phate_phenotype <- Fig4$df_phate %>%
  mutate(Phenotype = case_when(
    Cluster %in% c(13,3, 4)   ~ "Ramified",
    Cluster %in% c(2,7,5,11)   ~ "Transition",
    Cluster %in% c(9,8,6,10)  ~ "Ameboid",
    TRUE                        ~ NA_character_
  ))

cat("\nPhenotype counts:\n")
print(table(Fig4$df_phate_phenotype$Phenotype, useNA = "always"))

# Define phenotype colors
pheno_colors <- c("Ameboid" = "red", "Transition" = "grey", "Ramified" = "darkgreen")

# --- Phenotype Z‑score heatmap (top parameters) ---
top20_params <- param_variance$Parameter[1:25]
top20_params <- intersect(top20_params, colnames(Fig4$df_phate_phenotype))

if (length(top20_params) > 0) {
  df_z <- Fig4$df_phate_phenotype %>%
    dplyr::select(Phenotype, all_of(top20_params)) %>%
    drop_na(Phenotype)
  df_z_scaled <- df_z %>%
    mutate(across(all_of(top20_params), ~ scale(.)[, 1]))
  
  df_mean_z <- df_z_scaled %>%
    group_by(Phenotype) %>%
    summarise(across(all_of(top20_params), mean, na.rm = TRUE)) %>%
    tidyr::pivot_longer(-Phenotype, names_to = "Parameter", values_to = "Mean_Z")
  
  # Reorder parameters by overall mean
  param_order <- df_mean_z %>%
    group_by(Parameter) %>%
    summarise(avg = mean(Mean_Z)) %>%
    arrange(avg) %>% pull(Parameter)
  df_mean_z$Parameter <- factor(df_mean_z$Parameter, levels = param_order)
  
  phenotype_order <- c("Ramified", "Transition", "Ameboid")  # adjust as desired
  df_mean_z$Phenotype <- factor(df_mean_z$Phenotype, levels = phenotype_order)
  
  
  Fig4$phenotype_heatmap <- ggplot(df_mean_z, aes(x = Phenotype, y = Parameter, fill = Mean_Z)) +
    geom_tile(color = "white", size = 0.5) +
    scale_fill_gradient2(low = "blue", mid = "white", high = "red", midpoint = 0,
                         name = "Mean Z‑score") +
    theme_classic() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 6),
          axis.text.y = element_text(size = 6))
  print(Fig4$phenotype_heatmap)
}

# --- Phenotype proportion across bins (deviation plot) ---
bin_counts <- Fig4$df_phate_phenotype %>%
  filter(Bin_Number_New %in% 1:17) %>%
  group_by(Bin_Number_New, Phenotype) %>%
  summarise(count = n(), .groups = "drop") %>%
  group_by(Bin_Number_New) %>%
  mutate(proportion = count / sum(count)) %>%
  ungroup()

prop_at_bin1 <- bin_counts %>%
  filter(Bin_Number_New == 1) %>%
  dplyr::select(Phenotype, prop_bin1 = proportion)

bin_props <- bin_counts %>%
  left_join(prop_at_bin1, by = "Phenotype") %>%
  mutate(proportion_norm = proportion / prop_bin1,
         proportion_center = proportion - prop_bin1)

Fig4$phenotype_deviation <- ggplot(bin_props,
                                   aes(x = Bin_Number_New, y = proportion_center,
                                       color = Phenotype, fill = Phenotype)) +
  geom_point(alpha = 0.5, size = 1) +
  geom_smooth(method = "loess", se = TRUE, alpha = 0.2, span = 0.75) +
  scale_color_manual(values = pheno_colors) +
  scale_fill_manual(values = pheno_colors) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "black") +
  labs(x = "Radial Bin", y = "Proportion (centered at bin 1)") +
  theme_classic() +
  theme(legend.position = "none")
print(Fig4$phenotype_deviation)

# ============================================================================
# 7. SUMMARY
# ============================================================================
Fig4$summary <- list(
  n_cells_phate = nrow(Fig4$df_phate),
  n_clusters = length(unique(Fig4$df_full$Cluster)),
  n_features = length(feature_cols),
  top_params = Fig4$top_params,
  phenotype_counts = table(Fig4$df_phate_phenotype$Phenotype)
)

cat("\n=== FIG4 COMPLETE ===\n")
cat("All results stored in Fig4 list.\n")
cat("Key elements:\n")
cat("  - umap_cluster (UMAP with centroids)\n")
cat("  - cluster_heatmap (z‑scored feature means per cluster)\n")
cat("  - pheatmap (cluster proportion across bins, custom colors)\n")
cat("  - pheatmap_viridis (alternative viridis version)\n")
cat("  - phate_cluster (PHATE 2D)\n")
cat("  - phate1_boxplot (PHATE1 distribution per cluster)\n")
if (!is.null(Fig4$phenotype_heatmap)) cat("  - phenotype_heatmap (Z‑score by phenotype)\n")
cat("  - phenotype_deviation (phenotype trends across bins)\n")

# ============================================================================
# End of Figure 4 script
# ============================================================================