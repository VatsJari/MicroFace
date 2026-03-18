# ============================================================================
# FIGURE 5: PHATE, Transition sub‑clustering, and enrichment
# ============================================================================
# This script uses data from Fig4$df_phate_phenotype and produces:
#   - PHATE visualizations coloured by phenotype
#   - Dendrogram of transition clusters (to manually define T1/T2/T3)
#   - Dot plot of top morphological features for T1 vs T2
#   - Heatmaps of T1/T2 distribution across bins and time
# All results are stored in the list 'Fig5'.
# ============================================================================


# Initialize Fig5 list
Fig5 <- list()

# Check that Fig4 exists
if (!exists("Fig4") || is.null(Fig4$df_phate_phenotype)) {
  stop("Fig4$df_phate_phenotype not found. Please run Figure 4 script first.")
}

Fig5$df_phate_phenotype <- Fig4$df_phate_phenotype

# ---------------------------- Colour definitions ----------------------------
pheno_colors <- c("Ameboid" = "red", "Transition" = "grey", "Ramified" = "darkgreen")

# ============================================================================
# 1. PHATE PLOTS coloured by phenotype
# ============================================================================

# 1a. PHATE 2D
Fig5$phate_2d_phenotype <- ggplot(Fig5$df_phate_phenotype, 
                                  aes(x = PHATE1_2D, y = PHATE2_2D, color = Phenotype)) +
  geom_point(size = 0.01, alpha = 0.7, shape=".") +
  scale_color_manual(values = pheno_colors) +
  theme_void() +
  coord_fixed()+
  labs(x = "PHATE1", y = "PHATE2") +
  theme(plot.title = element_text(hjust = 0.5, face = "bold")) +
  guides(color = "none")
print(Fig5$phate_2d_phenotype)



# 1d. PHATE 2D faceted by phenotype
Fig5$phate_2d_facet_phenotype <- ggplot(Fig5$df_phate_phenotype, 
                                        aes(x = PHATE1_2D, y = PHATE2_2D, color = Phenotype)) +
  geom_point(size = 0.3, alpha = 0.6) +
  scale_color_manual(values = pheno_colors) +
  theme_classic() +
  facet_wrap(~Phenotype) +
  labs(x = "PHATE1", y = "PHATE2") +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"),
        strip.background = element_rect(fill = "lightgray"))
print(Fig5$phate_2d_facet_phenotype)

# 1e. Density plots of PHATE1/PHATE2 by phenotype
Fig5$phate1_density <- ggplot(Fig5$df_phate_phenotype, aes(x = PHATE1_2D, fill = Phenotype)) +
  geom_density(alpha = 0.5) + scale_fill_manual(values = pheno_colors) + theme_classic()
Fig5$phate2_density <- ggplot(Fig5$df_phate_phenotype, aes(x = PHATE2_2D, fill = Phenotype)) +
  geom_density(alpha = 0.5) + scale_fill_manual(values = pheno_colors) + theme_classic()
print(Fig5$phate1_density); print(Fig5$phate2_density)

# ============================================================================
# 2. DENDROGRAM OF TRANSITION CLUSTERS (based on morphological features)
# ============================================================================
# Subset transition cells

df_full_phenotype <-Fig4$df_full %>%
  mutate(Phenotype = case_when(
    Cluster %in% c(13,3, 4)   ~ "Ramified",
    Cluster %in% c(2,7,5,11)   ~ "Transition",
    Cluster %in% c(9,8,6,10)  ~ "Ameboid",
    TRUE                        ~ NA_character_
  ))


df_trans <- df_full_phenotype %>% filter(Phenotype == "Transition")
if (nrow(df_trans) == 0) stop("No Transition cells found.")

# Identify morphological feature columns (exclude metadata)
metadata_cols <- c("Cell_ID", "UMAP1", "UMAP2", "PC1", "PC2", "PC3", "Cluster",
                   "FileName_Original_Iba1_cell", "Animal_No", "Time_weeks",
                   "Electrode_Thickness", "SubImage", "ImageNumber_cell",
                   "Condition_cell", "Center_X_soma", "Center_Y_soma",
                   "Injury_x", "Injury_y", "radial_dist", "bin_number",
                   "bin_range", "Bin_Number_New", "bin_range_new", "Impact_Region",
                   "PHATE1_2D", "PHATE2_2D", "PHATE1_3D", "PHATE2_3D", "PHATE3_3D",
                   "Phenotype", "Health_score", "time_num")
feature_cols <- setdiff(colnames(df_trans), metadata_cols)
feature_cols <- feature_cols[sapply(df_trans[, feature_cols], is.numeric)]
Fig5$transition_features <- feature_cols

# Compute median feature values per cluster within transition
cluster_medians <- df_trans %>%
  group_by(Cluster) %>%
  summarise(across(all_of(feature_cols), median, na.rm = TRUE)) %>%
  column_to_rownames(var = "Cluster")

# Scale across clusters
cluster_medians_scaled <- scale(cluster_medians)

# Distance and clustering
dist_mat <- dist(cluster_medians_scaled, method = "euclidean")
hc <- hclust(dist_mat, method = "ward.D2")
Fig5$transition_cluster_dendrogram <- hc

# Plot dendrogram
library(ggdendro)
dend_data <- dendro_data(hc)
Fig5$dendrogram_plot <- ggplot(segment(dend_data)) +
  geom_segment(aes(x = x, y = y, xend = xend, yend = yend)) +
  geom_text(data = label(dend_data), 
            aes(x = x, y = y, label = label), hjust = -2, size = 3) +
  coord_flip() + scale_y_reverse(expand = c(01, 0)) +
  labs(title = "Dendrogram of Transition clusters (based on median morphology)")
print(Fig5$dendrogram_plot)

# ============================================================================
# 3. MANUAL ASSIGNMENT OF TRANSITION SUBGROUPS (T1, T2, T3)
#    Edit the cluster numbers below based on dendrogram branches
# ============================================================================
transition_1_clusters <- c(7, 5)    # <-- CHANGE THESE NUMBERS
transition_2_clusters <- c(2)   # <-- CHANGE THESE NUMBERS
transition_3_clusters <- c(11)   # optional, if a third branch exists

df_full_phenotype <- df_full_phenotype %>%
  mutate(Phenotype_new = case_when(
    Phenotype != "Transition" ~ as.character(Phenotype),
    Phenotype == "Transition" & Cluster %in% transition_1_clusters ~ "T1",
    Phenotype == "Transition" & Cluster %in% transition_2_clusters ~ "T2",
    Phenotype == "Transition" & Cluster %in% transition_3_clusters ~ "T3",
    Phenotype == "Ramified" ~ "Ramified",
    Phenotype == "Ameboid" ~ "Ameboid",
    TRUE ~ NA_character_
  )) %>%
  mutate(Phenotype_new = factor(Phenotype_new,
                                levels = c("Ameboid", "T1", "T2", "T3", "Ramified")))

table(df_full_phenotype$Phenotype_new, useNA = "ifany")

# Optional: PHATE plot with new groups
Fig5$phate_2d_phenotype_new <- ggplot(Fig5$df_phate_phenotype, 
                                      aes(x = PHATE1_3D, y = PHATE3_3D, color = Phenotype_new)) +
  geom_point(size = 0.2, alpha = 0.7) +
  scale_color_manual(values = c("Ameboid" = "red", 
                                "T2" = "#E98811", 
                                "T1" = "#7D65D9", 
                                "T3" = "maroon", 
                                "Ramified" = "darkgreen")) +
  facet_grid(~Phenotype_new)+
  coord_fixed()+
  theme_bw()
print(Fig5$phate_2d_phenotype_new)


# ============================================================================
# 4. HEATMAP OF Z‑SCORED FEATURES ACROSS T1, T2, T3
# ============================================================================
# Subset cells belonging to T1, T2, T3 (if T3 exists, otherwise T1/T2 only)
df_T <- Fig5$df_phate_phenotype %>%
  filter(Phenotype_new %in% c("T1", "T2", "T3", "Ramified")) %>%
  drop_na(Phenotype_new)

# Feature columns (from earlier)
feature_cols_T <- Fig5$transition_features   # list of morphological parameters

# ---- 1. Global z‑scoring (within the subset) ----
# Scale each feature to mean 0, sd 1 across all T1/T2/T3 cells
scaled_matrix <- scale(df_T[, feature_cols_T])
colnames(scaled_matrix) <- feature_cols_T
rownames(scaled_matrix) <- NULL

# Combine with group labels
df_scaled <- cbind(df_T[, "Phenotype_new", drop = FALSE], as.data.frame(scaled_matrix))

# ---- 2. Compute median z‑score per group ----
group_medians <- df_scaled %>%
  group_by(Phenotype_new) %>%
  summarise(across(all_of(feature_cols_T), median, na.rm = TRUE)) %>%
  column_to_rownames(var = "Phenotype_new") %>%
  t()  # transpose so rows = features, columns = groups

Fig5$T_group_medians <- group_medians

# ---- 3. (Optional) Force‑include specific features ----
forced_features <- c("Trunk_Branch", "Non_Trunk_Branch", "MaxFeretDiameter_soma")
forced_features <- intersect(forced_features, rownames(group_medians))

# Select top N features by variance across groups (or keep all)
feature_variance <- apply(group_medians, 1, var, na.rm = TRUE)
topN <- 40   # adjust as desired
top_features <- names(sort(feature_variance, decreasing = TRUE))[1:topN]

# Ensure forced features are included
top_features <- unique(c(forced_features, top_features))
top_features <- intersect(top_features, rownames(group_medians))

# Subset matrix
heatmap_matrix <- group_medians[top_features, , drop = FALSE]
Fig5$heatmap_matrix_Tgroups <- heatmap_matrix

# ---- 4. Hierarchical clustering of groups and features (features as rows) ----
dist_col <- dist(t(heatmap_matrix), method = "euclidean")
hc_col <- hclust(dist_col, method = "complete")
dist_row <- dist(heatmap_matrix, method = "euclidean")
hc_row <- hclust(dist_row, method = "complete")

Fig5$heatmap_Tgroups <- pheatmap(
  heatmap_matrix,
  cluster_rows = hc_row,
  cluster_cols = hc_col,
  display_numbers = TRUE,
  number_format = "%.2f",
  color = colorRampPalette(c("blue", "white", "red"))(100),
  angle_col = 45,
  fontsize_row = 8,
  fontsize_col = 10,
  cellwidth = 20,
  cellheight = 10,
  main = "Median z‑score of top morphological features\n(features as rows)"
)
print(Fig5$heatmap_Tgroups)

# ---- 5. Transposed heatmap (groups as rows) ----
heatmap_matrix_T <- t(heatmap_matrix)
Fig5$heatmap_matrix_Tgroups_T <- heatmap_matrix_T

# Cluster groups (now rows) and features (now columns)
dist_row_T <- dist(heatmap_matrix_T, method = "euclidean")
hc_row_T <- hclust(dist_row_T, method = "complete")
dist_col_T <- dist(t(heatmap_matrix_T), method = "euclidean")
hc_col_T <- hclust(dist_col_T, method = "complete")

Fig5$heatmap_Tgroups_transposed <- pheatmap(
  heatmap_matrix_T,
  cluster_rows = hc_row_T,
  cluster_cols = hc_col_T,
  display_numbers = F,
  color = colorRampPalette(c("blue", "white", "red"))(100),
  angle_col = 45,
  fontsize_row = 6,
  fontsize_col = 6,
  cellwidth = 10,
  cellheight = 10
)


# Optional: also store the scaled data and group medians
Fig5$scaled_T_data <- df_scaled


# ============================================================================
# 5. DENSITY MAPS OF PHATE SPACE FOR NEW GROUPS
# ============================================================================
Fig5$density_phate_phenotype_new_contour <- ggplot(Fig5$df_phate_phenotype, 
                                                   aes(x = PHATE1_3D, y = PHATE3_3D)) +
  geom_point(aes(color = Phenotype_new), size = 0.1, alpha = 0.2) +
  stat_density_2d(aes(fill = after_stat(level)), geom = "polygon", contour = TRUE, alpha = 0.5) +
  scale_fill_viridis_c() +
  scale_color_manual(values = c("Ameboid" = "red", 
                                "T2" = "#E98811", 
                                "T1" = "#7D65D9", 
                                "T3" = "maroon", 
                                "Ramified" = "darkgreen")) +
  facet_grid(~ Phenotype_new) +
 # coord_fixed()+
  theme_bw() +
  labs(x = "PHATE1", y = "PHATE3")+
  theme(legend.position = "bottom")
print(Fig5$density_phate_phenotype_new_contour)

# ============================================================================
# 6. HEATMAP OF T1 vs T2 DISTRIBUTION ACROSS BINS (1–16)
# ============================================================================
df_bins <- Fig5$df_phate_phenotype %>%
  filter(Phenotype_new %in% c("T1", "T2", "T3"), Bin_Number_New <= 16) %>%
  drop_na(Bin_Number_New)

df_bins$Bin_Number_New <- factor(df_bins$Bin_Number_New, levels = 1:16, ordered = TRUE)

count_bins <- dcast(df_bins, Bin_Number_New ~ Phenotype_new, fun.aggregate = length)
rownames(count_bins) <- count_bins$Bin_Number_New
count_bins <- as.matrix(count_bins[, -1])
Fig5$freq_bins_raw <- count_bins

# Scale each column to [-1,1] centered at mean
scale_to_minus1_1 <- function(x) {
  centered <- x - mean(x, na.rm = TRUE)
  max_abs <- max(abs(centered), na.rm = TRUE)
  if (max_abs == 0) return(rep(0, length(x)))
  centered / max_abs
}
scaled_bins <- apply(count_bins, 2, scale_to_minus1_1)
rownames(scaled_bins) <- rownames(count_bins)
Fig5$freq_bins_scaled <- scaled_bins

Fig5$heatmap_bins <- pheatmap(
  scaled_bins,
  cluster_rows = FALSE,
  cluster_cols = FALSE,
  display_numbers = FALSE,
  color = colorRampPalette(c("white", "#C8F8C8", "#91DC90", "#016700", "#015300"))(100),
  angle_col = 45,
  fontsize_row = 10,
  fontsize_col = 10,
  cellwidth = 14,
  cellheight = 14,
  main = "T1 vs T2 scaled frequency (bins 1‑16)"
)
print(Fig5$heatmap_bins)

# ============================================================================
# 7. HEATMAP OF T1 vs T2 DISTRIBUTION ACROSS TIME POINTS
# ============================================================================
df_time <- Fig5$df_phate_phenotype %>%
  filter(Phenotype_new %in% c("T1", "T2", "T3")) %>%
  drop_na(Time_weeks)

# Order time points
time_levels <- c("00WPI", "01WPI", "02WPI", "08WPI", "18WPI")
df_time$Time_weeks <- factor(df_time$Time_weeks, levels = time_levels, ordered = TRUE)

count_time <- dcast(df_time, Time_weeks ~ Phenotype_new, fun.aggregate = length)
rownames(count_time) <- count_time$Time_weeks
count_time <- as.matrix(count_time[, -1])
Fig5$freq_time_raw <- count_time

scaled_time <- apply(count_time, 2, scale_to_minus1_1)
rownames(scaled_time) <- rownames(count_time)
Fig5$freq_time_scaled <- scaled_time

Fig5$heatmap_time <- pheatmap(
  scaled_time,
  cluster_rows = FALSE,
  cluster_cols = FALSE,
  display_numbers = FALSE,
  color = colorRampPalette(c("white", "white","#91DC90","#016700", "#016700", "#015300","#015300"))(10),
  angle_col = 45,
  fontsize_row = 10,
  fontsize_col = 10,
  cellwidth = 14,
  cellheight = 14,
)
print(Fig5$heatmap_time)



# ============================================================================
# 7. HEATMAP OF T1, T2, T3 DISTRIBUTION ACROSS TIME POINTS (raw counts)
# ============================================================================
df_time <- Fig5$df_phate_phenotype %>%
  filter(Phenotype_new %in% c("T1", "T2", "T3")) %>%   # include T3 if it exists
  drop_na(Time_weeks)

# Order time points
time_levels <- c("00WPI", "01WPI", "02WPI", "08WPI", "18WPI")
df_time$Time_weeks <- factor(df_time$Time_weeks, levels = time_levels, ordered = TRUE)

# Create count matrix (rows = time, cols = T1/T2/T3)
count_time <- dcast(df_time, Time_weeks ~ Phenotype_new, fun.aggregate = length)
rownames(count_time) <- count_time$Time_weeks
count_time <- as.matrix(count_time[, -1, drop = FALSE])
Fig5$freq_time_raw <- count_time

# Optional: percentages within each column (if you prefer relative abundance)
# percent_time <- sweep(count_time, 2, colSums(count_time), FUN = "/") * 100
# Fig5$freq_time_percent <- percent_time

# Heatmap of raw counts (no scaling)
Fig5$heatmap_time_raw <- pheatmap(
  count_time,
  cluster_rows = FALSE,
  cluster_cols = FALSE,
  display_numbers = F,
  number_format = "%.0f",
  color = colorRampPalette(c("white", "#C8F8C8", "#91DC90", "#016700", "#015300"))(100),
  angle_col = 45,
  fontsize_row = 10,
  fontsize_col = 10,
  cellwidth = 14,
  cellheight = 14,
  main = "Cell counts per time point (T1, T2, T3)"
)
print(Fig5$heatmap_time_raw)
# ============================================================================
# 8. SUMMARY OF STORED OBJECTS
# ============================================================================
cat("\n=== FIG5 COMPLETE ===\n")
cat("All results stored in list 'Fig5'.\n")
cat("Contents:\n")
print(names(Fig5))

# ============================================================================
# End of Figure 5 script
# ============================================================================