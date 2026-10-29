# ============================================================================
# SUPPLEMENTARY FIGURE S8: Electrode thickness analysis
# ============================================================================
# This script uses data from ClusterAnalysis_filtered and produces:
#   1. Factor ordering for Electrode_Thickness (6,11,16,50)
#   2. Cluster proportions per thickness (stacked bar + line plot)
#   3. Identification of clusters with largest change
#   4. Top morphological parameters by variance and temporal heatmap
#   5. UMAP coloured by Electrode_Thickness
# All outputs are stored in the list 'Fig_S8'.
# ============================================================================

# Initialize the list
Fig_S8 <- list()

# Load required libraries
library(dplyr)
library(ggplot2)
library(tidyr)

# ----------------------------------------------------------------------------
# 1. Extract the dataframe and order Electrode_Thickness
# ----------------------------------------------------------------------------
if (!exists("Fig4") || is.null(Fig4$df_phate_phenotype)) {
  stop("Fig4$df_phate_phenotype not found. Please run Figure 4 script first.")
}

Fig_S8$df <- Fig4$df_phate_phenotype
df <- Fig_S8$df   # local copy for convenience

# Order Electrode_Thickness as 6, 11, 16, 50
df <- df %>%
  mutate(
    # Ensure it's character before making factor
    Electrode_Thickness = as.character(Electrode_Thickness),
    # Create ordered factor with desired levels
    Electrode_Thickness = factor(Electrode_Thickness,
                                 levels = c("6", "11", "16", "50"),
                                 ordered = TRUE)   # marks as ordinal
  )
Fig_S8$df <- df   # update with factor

# Check that the factor levels are correct
cat("Electrode_Thickness levels:\n")
print(levels(df$Electrode_Thickness))   # Should output: "6" "11" "16" "50"

# ----------------------------------------------------------------------------
# 2. Summarize cluster counts per thickness
# ----------------------------------------------------------------------------
Fig_S8$cluster_summary <- df %>%
  group_by(Electrode_Thickness, Cluster) %>%
  summarise(count = n(), .groups = "drop") %>%
  group_by(Electrode_Thickness) %>%
  mutate(proportion = count / sum(count)) %>%
  ungroup()

print(Fig_S8$cluster_summary)

# ----------------------------------------------------------------------------
# 3. Plot cluster proportions over thickness
# ----------------------------------------------------------------------------
# 3a. Stacked bar chart
Fig_S8$stacked_bar <- ggplot(Fig_S8$cluster_summary, 
                             aes(x = Electrode_Thickness, y = proportion, 
                                 fill = as.factor(Cluster))) +
  geom_col(position = "fill") +
  scale_fill_manual(values = morpho_colours) +
  labs(x = "Electrode thickness", y = "Proportion of cells", fill = "Cluster") +
  theme_classic() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 6),
        axis.text.y = element_text(size = 6),
        legend.position = "right")
print(Fig_S8$stacked_bar)

# 3b. Line plot for each cluster
Fig_S8$line_plot <- ggplot(Fig_S8$cluster_summary, 
                           aes(x = Electrode_Thickness, y = proportion, 
                               group = Cluster, color = as.factor(Cluster))) +
  geom_line(size = 1) +
  geom_point(size = 2) +
  scale_color_manual(values = morpho_colours) +
  labs(x = "Electrode thickness", y = "Proportion of cells", color = "Cluster") +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 6),
        axis.text.y = element_text(size = 6))+
  NoLegend()

print(Fig_S8$line_plot)

# ----------------------------------------------------------------------------
# 4. Identify clusters with largest change
# ----------------------------------------------------------------------------
time_levels <- levels(df$Electrode_Thickness)   # now in correct order
first_time <- time_levels[1]
last_time <- time_levels[length(time_levels)]

Fig_S8$cluster_changes <- Fig_S8$cluster_summary %>%
  filter(Electrode_Thickness %in% c(first_time, last_time)) %>%
  dplyr::select(Electrode_Thickness, Cluster, proportion) %>%
  pivot_wider(names_from = Electrode_Thickness, values_from = proportion) %>%
  mutate(
    change = .[[last_time]] - .[[first_time]],
    abs_change = abs(change),
    rel_change = change / .[[first_time]] * 100
  ) %>%
  arrange(desc(abs_change))

cat("\nCluster changes from first to last thickness:\n")
print(Fig_S8$cluster_changes)

Fig_S8$change_plot <- ggplot(Fig_S8$cluster_changes, 
                             aes(x = reorder(Cluster, abs_change), y = change, 
                                 fill = change > 0)) +
  geom_col() +
  coord_flip() +
  labs(x = "Cluster", y = "Change in proportion (last - first)", 
       title = "Absolute change in cluster proportions") +
  scale_fill_manual(values = c("TRUE" = "darkgreen", "FALSE" = "firebrick"), 
                    guide = FALSE) +
  theme_minimal()
print(Fig_S8$change_plot)

# ----------------------------------------------------------------------------
# 5. Top morphological parameters & heatmap
# ----------------------------------------------------------------------------
metadata_cols <- c(
  "Cell_ID", "UMAP1", "UMAP2", "UMAP1.1", "UMAP2.1", "PC1", "PC2", "PC3",
  "FileName_Original_Iba1_cell", "Animal_No", "Electrode_Thickness", 
  "SubImage", "ImageNumber_cell", "Condition_cell", "Center_X_soma", "Center_Y_soma",
  "Injury_x", "Injury_y", "radial_dist", "bin_number", "bin_range",
  "Bin_Number_New", "bin_range_new", "Impact_Region", "Cluster", "Health_score"
)

# All other numeric columns are potential parameters
all_params <- df %>%
  dplyr::select(-one_of(metadata_cols)) %>%
  select_if(is.numeric) %>%
  colnames()
Fig_S8$all_params <- all_params

# Compute variance of each parameter across all cells
Fig_S8$param_variance <- df %>%
  summarise(across(all_of(all_params), var, na.rm = TRUE)) %>%
  pivot_longer(everything(), names_to = "parameter", values_to = "variance") %>%
  arrange(desc(variance))

Fig_S8$top30_params <- Fig_S8$param_variance$parameter[1:30]
cat("\nTop 30 parameters by variance:\n")
print(Fig_S8$top30_params)

# Create z‑scored columns for these parameters
df_scored <- df
for (param in Fig_S8$top30_params) {
  mean_val <- mean(df_scored[[param]], na.rm = TRUE)
  sd_val   <- sd(df_scored[[param]], na.rm = TRUE)
  scored_col <- paste0(param, "_scored")
  df_scored[[scored_col]] <- (df_scored[[param]] - mean_val) / sd_val
}
Fig_S8$df_scored <- df_scored

# Aggregate mean z‑score per thickness for each parameter
Fig_S8$time_summary <- df_scored %>%
  group_by(Electrode_Thickness) %>%
  summarise(across(ends_with("_scored"), mean, na.rm = TRUE), .groups = "drop") %>%
  pivot_longer(-Electrode_Thickness, names_to = "param_scored", values_to = "mean_z") %>%
  mutate(parameter = gsub("_scored$", "", param_scored))

# Heatmap – y-axis will show 6,11,16,50 in that order
Fig_S8$heatmap_plot <- ggplot(Fig_S8$time_summary, 
                              aes(x = parameter, y = Electrode_Thickness, fill = mean_z)) +
  geom_tile() +
  scale_fill_gradient2(low = "blue", mid = "white", high = "red", midpoint = 0,
                       name = "Mean Z‑score") +
  labs(y = "Electrode thickness", x = "Parameter") +
  theme_classic() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 6),
        axis.text.y = element_text(size = 6))
print(Fig_S8$heatmap_plot)

# Line plot of temporal trends
Fig_S8$lineplot_time <- ggplot(Fig_S8$time_summary,
                               aes(x = Electrode_Thickness, y = mean_z,
                                   group = parameter, color = parameter)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.5) +
  labs(x = "Electrode thickness", y = "Mean Z‑score",
       title = "Temporal trends of top 30 parameters") +
  theme_bw() +
  theme(legend.position = "top", legend.text = element_text(size = 4)) +
  guides(color = guide_legend(ncol = 6)) +
  scale_color_viridis_d()
print(Fig_S8$lineplot_time)

# Table of changes from first to last thickness
first_t <- levels(df$Electrode_Thickness)[1]
last_t  <- levels(df$Electrode_Thickness)[length(levels(df$Electrode_Thickness))]

Fig_S8$time_changes <- Fig_S8$time_summary %>%
  group_by(parameter) %>%
  summarise(
    first = mean_z[Electrode_Thickness == first_t],
    last  = mean_z[Electrode_Thickness == last_t],
    change = last - first,
    .groups = "drop"
  ) %>%
  arrange(desc(abs(change)))

print(Fig_S8$time_changes)

# ----------------------------------------------------------------------------
# 7. Summary of stored objects
# ----------------------------------------------------------------------------
cat("\n=== FIG_S8 COMPLETE ===\n")
cat("All results stored in list 'Fig_S8'.\n")
cat("Contents:\n")
print(names(Fig_S8))

# ============================================================================
# End of Supplementary Figure S8 script
# ============================================================================