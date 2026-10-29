# ============================================================================
# FIGURE 3: Microglial Morphological Feature Program
# ============================================================================
# This script performs:
# 1. Correlation heatmap of morphological features with module detection.
# 2. NMF rank selection.
# 3. NMF on features (basis matrix W) to identify feature programs.
# 4. NMF on cells (coefficient matrix H) to show program activity across cells.
# 5. Parameter score comparison across impact regions (Close, Middle, Far).
# All outputs are stored in the 'Fig3' list.
# ============================================================================

# Initialize container
Fig3 <- list()

# ============================================================================
# STEP 1: Load and filter data
# ============================================================================
# Assumes ClusterAnalysis exists from previous clustering script
if (!exists("ClusterAnalysis")) {
  stop("ClusterAnalysis not found. Please run clustering script first.")
}

Fig3$df <- ClusterAnalysis$final_df_sampled 

# Filter spatial bin (optional, keep bins ≤ 25)
Fig3$df <- Fig3$df %>%
  filter(Bin_Number_New <= 25)

# Extract morphometric features (columns 23 onward)
Fig3$features <- Fig3$df[, 27:ncol(Fig3$df)]

# Remove zero‑variance features
Fig3$features <- Fig3$features[, apply(Fig3$features, 2, var, na.rm = TRUE) > 0]

# ============================================================================
# STEP 2: Create two normalized datasets
# ============================================================================
# Z‑score for correlation analysis
Fig3$features_z <- scale(Fig3$features)

# Min‑max normalization for NMF (non‑negative)
min_max_norm <- function(x) {
  rng <- max(x, na.rm = TRUE) - min(x, na.rm = TRUE)
  if (rng == 0) return(rep(0, length(x)))
  (x - min(x, na.rm = TRUE)) / rng
}
Fig3$features_nmf <- apply(Fig3$features, 2, min_max_norm)
Fig3$features_nmf <- as.matrix(Fig3$features_nmf)
Fig3$features_nmf[is.na(Fig3$features_nmf)] <- 0

# ============================================================================
# STEP 3: Correlation matrix and module detection (Figure 3A)
# ============================================================================
Fig3$cor_mat <- cor(Fig3$features_z,
                    use = "pairwise.complete.obs",
                    method = "pearson")

# Hierarchical clustering
Fig3$hc <- hclust(dist(1 - Fig3$cor_mat), method = "ward.D2")

# Choose number of modules (adjustable)
Fig3$n_modules <- 6
Fig3$modules <- cutree(Fig3$hc, k = Fig3$n_modules)

# Annotation dataframe for pheatmap
Fig3$annotation <- data.frame(Module = as.factor(Fig3$modules))
rownames(Fig3$annotation) <- names(Fig3$modules)

# Generate correlation heatmap
Fig3$heatmap_cor <- pheatmap(
  Fig3$cor_mat,
  clustering_method = "ward.D2",
 # annotation_row = Fig3$annotation,
  annotation_col = Fig3$annotation,
  color = viridis(100),
  border_color = NA,
  fontsize = 4,
  cellwidth = 5,
  cellheight = 5,
  silent = TRUE
)
(Fig3$heatmap_cor)

# ============================================================================
# STEP 4: Downsample cells for NMF (speed)
# ============================================================================
set.seed(123)
n_cells_use <- 1000
cell_subset <- sample(1:nrow(Fig3$features_nmf),
                      size = min(n_cells_use, nrow(Fig3$features_nmf)))
Fig3$features_nmf_subset <- Fig3$features_nmf[cell_subset, ]

# ============================================================================
# STEP 5: Estimate optimal NMF rank (Figure 3B)
# ============================================================================
rank_range <- 2:10
Fig3$rank_est <- nmfEstimateRank(
  Fig3$features_nmf_subset,
  range = rank_range,
  nrun = 20,
  method = "brunet",
  seed = 123
)

# Extract best rank (max cophenetic coefficient)
metrics <- Fig3$rank_est$measures
metrics$rank <- as.numeric(metrics$rank)
Fig3$best_rank <- metrics$rank[which.max(metrics$cophenetic)]
Fig3$best_rank <- 7

# Plot rank selection with highlighted best rank
dev.new(width = 7, height = 5)
plot(Fig3$rank_est)
points(Fig3$best_rank,
       metrics$cophenetic[which.max(metrics$cophenetic)],
       col = "red", pch = 19, cex = 1.5)
abline(v = Fig3$best_rank, col = "red", lty = 2)
title(main = "NMF Rank Selection")
Fig3$rank_plot <- recordPlot()
dev.off()

# ============================================================================
# STEP 6: Run final NMF at best rank
# ============================================================================
set.seed(123)
Fig3$nmf_rank <- Fig3$best_rank
Fig3$nmf_res <- nmf(
  Fig3$features_nmf_subset,
  rank = Fig3$nmf_rank,
  nrun = 50,
  method = "brunet",
  seed = 123
)

# Extract basis (W) and coefficient (H) matrices
Fig3$W <- basis(Fig3$nmf_res)      # features × programs
Fig3$H <- coef(Fig3$nmf_res)       # programs × cells

# Rename programs
colnames(Fig3$W) <- paste0("NMF_", seq_len(ncol(Fig3$W)))
rownames(Fig3$H) <- paste0("NMF_", seq_len(nrow(Fig3$H)))

# ============================================================================
# STEP 7: NMF on features – heatmap of W (Figure 3C)
# ============================================================================
# Hierarchical clustering on rows (features) and columns (programs) using correlation
row_dist <- as.dist(1 - cor(t(Fig3$W), method = "pearson"))
Fig3$row_clust <- hclust(row_dist, method = "ward.D2")

col_dist <- as.dist(1 - cor(Fig3$W, method = "pearson"))
Fig3$col_clust <- hclust(col_dist, method = "ward.D2")

# Heatmap of W (feature programs)
Fig3$heatmap_W <- pheatmap(
  Fig3$W,
  scale = "row",
  cluster_rows = Fig3$row_clust,
  cluster_cols = Fig3$col_clust,
  treeheight_row = 50,
  treeheight_col = 30,
  color = inferno(100),
  fontsize = 4,
  cellwidth = 7,
  show_rownames = F,
  border_color = "black",
  main = "NMF Feature Programs",
  angle_col = 45,
  silent = TRUE
)
print(Fig3$heatmap_W)

# ============================================================================
# STEP 8: NMF on cells – heatmap of Hᵀ (program activity per cell) (Figure 3D)
# ============================================================================
Fig3$H_t <- t(Fig3$H)                 # cells × programs
colnames(Fig3$H_t) <- paste0("NMF_", seq_len(ncol(Fig3$H_t)))

# Distance between cells (based on program activity)
cell_dist <- as.dist(1 - cor(t(Fig3$H_t), method = "pearson"))
Fig3$cell_clust <- hclust(cell_dist, method = "ward.D2")

# Distance between programs (based on activity across cells)
prog_dist <- as.dist(1 - cor(Fig3$H_t, method = "pearson"))
Fig3$prog_clust <- hclust(prog_dist, method = "ward.D2")

# Heatmap of Hᵗ (program activity per cell)
Fig3$heatmap_Ht <- pheatmap(
  Fig3$H_t,
  scale = "row",
  cluster_rows = Fig3$cell_clust,
  cluster_cols = Fig3$prog_clust,
  treeheight_row = 100,
  treeheight_col = 50,
  color = inferno(100),
  border_color = NA,
  fontsize = 4,
  cellwidth = 7,
  cellheight = 4,
  main = "Morphological program activity across cells",
  show_rownames = T,
  angle_col = 45,
  silent = TRUE
)
print(Fig3$heatmap_Ht)

# ============================================================================
# STEP 9: Parameter scores across impact regions (Close, Middle, Far)
# ============================================================================
# Use the sampled data for this comparison
Fig3$df_clust <- ClusterAnalysis$final_df_full

# Metadata columns to exclude from parameters
Fig3$metadata_cols <- c("Cell_ID", "PC1", "PC2", "PC3", "UMAP1", "UMAP2",
                        "FileName_Original_Iba1_cell", "Animal_No", "Time_weeks",
                        "Electrode_Thickness", "SubImage", "ImageNumber_cell",
                        "Condition_cell", "Center_X_soma", "Center_Y_soma",
                        "Injury_x", "Injury_y", "radial_dist", "bin_number",
                        "bin_range", "Bin_Number_New", "bin_range_new",
                        "Impact_Region", "Cluster")

Fig3$all_params <- Fig3$df_clust %>%
  dplyr::select(-one_of(Fig3$metadata_cols))

cat("\nTotal parameters found:", ncol(Fig3$all_params), "\n")

# Select top 40 most varying parameters across regions
Fig3$param_variance <- Fig3$df_clust %>%
  group_by(Impact_Region) %>%
  summarise(across(all_of(colnames(Fig3$all_params)), ~ median(.x, na.rm = TRUE))) %>%
  dplyr::select(-Impact_Region) %>%
  summarise(across(everything(), var, na.rm = TRUE)) %>%
  tidyr::pivot_longer(everything(), names_to = "Parameter", values_to = "Variance") %>%
  arrange(desc(Variance))

Fig3$top40_params <- Fig3$param_variance$Parameter[1:30]

# Calculate median values for these parameters per region
Fig3$summary_stats <- Fig3$df_clust %>%
  group_by(Impact_Region) %>%
  summarise(across(all_of(Fig3$top40_params), ~ median(.x, na.rm = TRUE)))

# Reshape and compute z‑scores
Fig3$heatmap_data <- reshape2::melt(Fig3$summary_stats, id.vars = "Impact_Region")
colnames(Fig3$heatmap_data) <- c("Impact_Region", "Parameter", "Mean_Value")
Fig3$heatmap_data$Impact_Region <- factor(Fig3$heatmap_data$Impact_Region,
                                          levels = c("Close", "Middle", "Far"))

Fig3$heatmap_data <- Fig3$heatmap_data %>%
  group_by(Parameter) %>%
  mutate(Z_Score = scale(Mean_Value)[,1]) %>%
  ungroup()

# Clean parameter names
Fig3$heatmap_data$Parameter_Clean <- gsub("_", " ", Fig3$heatmap_data$Parameter)
Fig3$heatmap_data$Parameter_Clean <- gsub("cell", "(Cell)", Fig3$heatmap_data$Parameter_Clean)
Fig3$heatmap_data$Parameter_Clean <- gsub("soma", "(Soma)", Fig3$heatmap_data$Parameter_Clean)

# Order parameters by Z‑score in Far region
Fig3$parameter_order <- Fig3$heatmap_data %>%
  filter(Impact_Region == "Far") %>%
  arrange(Z_Score) %>%
  pull(Parameter_Clean)
Fig3$heatmap_data$Parameter_Clean <- factor(Fig3$heatmap_data$Parameter_Clean,
                                            levels = Fig3$parameter_order)

# Heatmap with actual values (Figure 3E)
Fig3$heatmap_actual <- ggplot(Fig3$heatmap_data,
                              aes(x = Impact_Region,
                                  y = Parameter_Clean,
                                  fill = Mean_Value)) +
  geom_tile(color = "white", linewidth = 0.5) +
  geom_text(aes(label = round(Mean_Value, 2)), size = 2) +
  scale_fill_gradientn(colors = c("#E66F74", "white", "#A4D38F"),
                       name = "Mean Value") +
  theme_classic() +
  labs(x = "Impact Region", y = "") +
  theme(axis.text.y = element_text(size = 6),
        legend.position = "right")
print(Fig3$heatmap_actual)

# Heatmap with z‑scores (Figure 3F)
Fig3$heatmap_scaled <- ggplot(Fig3$heatmap_data,
                              aes(x = Impact_Region,
                                  y = Parameter_Clean,
                                  fill = Z_Score)) +
  geom_tile(color = "white", linewidth = 0.5) +
  geom_text(aes(label = round(Z_Score, 2)), size = 1.5) +
  scale_fill_gradient2(low = "#E66F74", mid = "white", high = "#A4D38F",
                       midpoint = 0, name = "Z‑Score") +
  theme_classic() +
  labs(x = "Impact Region", y = "") +
  theme(axis.text.y = element_text(size = 6),
        legend.position = "right")
print(Fig3$heatmap_scaled)

# ============================================================================
# STEP 10: Save module assignments (optional)
# ============================================================================
Fig3$module_assignments <- data.frame(
  Feature = names(Fig3$modules),
  Module = Fig3$modules
)
# write.csv(Fig3$module_assignments, "Figure3_Feature_Module_Assignments.csv", row.names = FALSE)

# ============================================================================
# Summary
# ============================================================================
cat("\n========================================\n")
cat("Figure 3 analysis complete.\n")
cat("Best NMF rank automatically selected:", Fig3$best_rank, "\n")
cat("All results stored in 'Fig3' list.\n")
cat("Key elements:\n")
cat("  - heatmap_cor (correlation with modules)\n")
cat("  - rank_plot (NMF rank selection)\n")
cat("  - heatmap_W (feature programs)\n")
cat("  - heatmap_Ht (program activity per cell)\n")
cat("  - heatmap_actual / heatmap_scaled (region comparison)\n")
cat("========================================\n")

