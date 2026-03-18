# ============================================================================
# SUPPLEMENTARY FIGURE S7: Temporal dynamics of clusters and parameters
# ============================================================================
# This script uses data from Fig4 and produces:
#   1. Cluster proportions over time (stacked bar + line plot)
#   2. Identification of clusters with largest change
#   3. Top morphological parameters by variance and their temporal heatmap
#   4. UMAP coloured by time point
# All outputs are stored in the list 'Fig_S7'.
# ============================================================================

# Initialize the list
Fig_S7 <- list()

# ----------------------------------------------------------------------------
# 1. Prepare data (from Fig4)
# ----------------------------------------------------------------------------
if (!exists("Fig4") || is.null(Fig4$df_phate_phenotype)) {
  stop("Fig4$df_phate_phenotype not found. Please run Figure 4 script first.")
}

Fig_S7$df <- Fig4$df_phate_phenotype
df <- Fig_S7$df   # local copy for convenience

# Check structure
cat("Data dimensions:", nrow(df), "cells,", ncol(df), "columns\n")
cat("Time points present:\n")
print(unique(df$Time_weeks))

# ----------------------------------------------------------------------------
# 2. Clean and order time points
# ----------------------------------------------------------------------------
df <- df %>%
  mutate(
    time_num = as.numeric(gsub("WPI", "", Time_weeks)),   # assumes format "00WPI"
    Time_weeks_ordered = factor(Time_weeks, 
                                levels = unique(Time_weeks[order(time_num)]))
  )
Fig_S7$df <- df   # update with new columns

# ----------------------------------------------------------------------------
# 3. Summarize cluster counts per time point
# ----------------------------------------------------------------------------
Fig_S7$cluster_summary <- df %>%
  group_by(Time_weeks_ordered, Cluster) %>%
  summarise(count = n(), .groups = "drop") %>%
  group_by(Time_weeks_ordered) %>%
  mutate(proportion = count / sum(count)) %>%
  ungroup()

print(Fig_S7$cluster_summary)

Fig_S7$phenotype_summary <- df %>%
  group_by(Time_weeks_ordered, Phenotype) %>%
  summarise(count = n(), .groups = "drop") %>%
  group_by(Time_weeks_ordered) %>%
  mutate(proportion = count / sum(count)) %>%
  ungroup()

print(Fig_S7$phenotype_summary)

# ----------------------------------------------------------------------------
# 4. Plot cluster proportions over time
# ----------------------------------------------------------------------------
# 4a. Stacked bar chart
Fig_S7$stacked_bar <- ggplot(Fig_S7$cluster_summary, 
                             aes(x = Time_weeks_ordered, y = proportion, 
                                 fill = as.factor(Cluster))) +
  geom_col(position = "fill") +
  scale_fill_manual(values = morpho_colours) +
  labs(x = "Time (weeks)", y = "Proportion of cells", fill = "Cluster") +
  theme_classic() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 6),
        axis.text.y = element_text(size = 6),
        legend.position = "right")

print(Fig_S7$stacked_bar)

# 4b. Line plot for each cluster (trend)
Fig_S7$line_plot <- ggplot(Fig_S7$cluster_summary, 
                           aes(x = Time_weeks_ordered, y = proportion, 
                               group = Cluster, color = as.factor(Cluster))) +
  geom_line(size = 0.5) +
  geom_point(size = 0.5) +
  scale_color_manual(values = morpho_colours) +
  labs(x = "Time (weeks)", y = "Proportion of cells", color = "Cluster") +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 6),
        axis.text.y = element_text(size = 6),
        legend.position = "none")
print(Fig_S7$line_plot)


# ----------------------------------------------------------------------------
# 4. Plot Phenotype proportions over time
# ----------------------------------------------------------------------------
# 4a. Stacked bar chart
Fig_S7$stacked_bar_2 <- ggplot(Fig_S7$phenotype_summary, 
                             aes(x = Time_weeks_ordered, y = proportion, 
                                 fill = as.factor(Phenotype))) +
  geom_col(position = "fill") +
  scale_fill_manual(values = pheno_colors) +
  labs(x = "Time (weeks)", y = "Proportion of cells", fill = "phenotype") +
  theme_classic() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 6),
        axis.text.y = element_text(size = 6),
        legend.position = "none")

print(Fig_S7$stacked_bar_2)

# 4b. Line plot for each cluster (trend)
Fig_S7$line_plot_2 <- ggplot(Fig_S7$phenotype_summary, 
                           aes(x = Time_weeks_ordered, y = proportion, 
                               group = Phenotype, color = as.factor(Phenotype))) +
  geom_line(size = 0.5) +
  geom_point(size = 0.5) +
  scale_color_manual(values = pheno_colors) +
  labs(x = "Time (weeks)", y = "Proportion of cells", color = "phenotype") +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 6),
        axis.text.y = element_text(size = 6),
        legend.position = "none")
print(Fig_S7$line_plot_2)



# ----------------------------------------------------------------------------
# 5. Identify clusters with largest change
# ----------------------------------------------------------------------------
time_levels <- levels(df$Time_weeks_ordered)
first_time <- time_levels[1]
last_time  <- time_levels[length(time_levels)]

Fig_S7$cluster_changes <- Fig_S7$cluster_summary %>%
  filter(Time_weeks_ordered %in% c(first_time, last_time)) %>%
  dplyr::select(Time_weeks_ordered, Cluster, proportion) %>%
  pivot_wider(names_from = Time_weeks_ordered, values_from = proportion) %>%
  mutate(
    change = .[[last_time]] - .[[first_time]],
    abs_change = abs(change),
    rel_change = change / .[[first_time]] * 100
  ) %>%
  arrange(desc(abs_change))

cat("\nCluster changes from first to last time point:\n")
print(Fig_S7$cluster_changes)

# Bar plot of changes
Fig_S7$change_plot <- ggplot(Fig_S7$cluster_changes, 
                             aes(x = reorder(Cluster, abs_change), 
                                 y = change, fill = change > 0)) +
  geom_col() +
  coord_flip() +
  labs(x = "Cluster", y = "Change in proportion (last - first)",
       title = "Absolute change in cluster proportions") +
  scale_fill_manual(values = c("TRUE" = "darkgreen", "FALSE" = "firebrick"), 
                    guide = FALSE) +
  theme_minimal()
print(Fig_S7$change_plot)

# ----------------------------------------------------------------------------
# 6. Top morphological parameters by variance and temporal heatmap
# ----------------------------------------------------------------------------
# Define metadata columns (adjust if necessary)
metadata_cols <- c(
  "Cell_ID", "UMAP1", "UMAP2", "UMAP1.1", "UMAP2.1", "PC1", "PC2", "PC3",
  "FileName_Original_Iba1_cell", "Animal_No", "Time_weeks", "Electrode_Thickness",
  "SubImage", "ImageNumber_cell", "Condition_cell", "Center_X_soma", "Center_Y_soma",
  "Injury_x", "Injury_y", "radial_dist", "bin_number", "bin_range",
  "Bin_Number_New", "bin_range_new", "Impact_Region", "Cluster", "Health_score", 
  "time_num", "Time_weeks_ordered"
)

# All other numeric columns are potential parameters
all_params <- df %>%
  dplyr::select(-one_of(metadata_cols)) %>%
  select_if(is.numeric) %>%
  colnames()
Fig_S7$all_params <- all_params

# Compute variance of each parameter across all cells
Fig_S7$param_variance <- df %>%
  summarise(across(all_of(all_params), var, na.rm = TRUE)) %>%
  pivot_longer(everything(), names_to = "parameter", values_to = "variance") %>%
  arrange(desc(variance))

Fig_S7$top20_params <- Fig_S7$param_variance$parameter[1:30]
cat("\nTop 20 parameters by variance:\n")
print(Fig_S7$top20_params)

# Create z‑scored columns for these parameters
df_scored <- df
for (param in Fig_S7$top20_params) {
  mean_val <- mean(df_scored[[param]], na.rm = TRUE)
  sd_val   <- sd(df_scored[[param]], na.rm = TRUE)
  scored_col <- paste0(param, "_scored")
  df_scored[[scored_col]] <- (df_scored[[param]] - mean_val) / sd_val
}
Fig_S7$df_scored <- df_scored

# Aggregate mean z‑score per time point for each parameter
Fig_S7$time_summary <- df_scored %>%
  group_by(Time_weeks) %>%
  summarise(across(ends_with("_scored"), mean, na.rm = TRUE), .groups = "drop") %>%
  pivot_longer(-Time_weeks, names_to = "param_scored", values_to = "mean_z") %>%
  mutate(parameter = gsub("_scored$", "", param_scored))

# Heatmap of mean z‑scores over time
Fig_S7$heatmap_plot <- ggplot(Fig_S7$time_summary, 
                              aes(x = parameter, y = Time_weeks, fill = mean_z)) +
  geom_tile() +
  scale_fill_gradient2(low = "blue", mid = "white", high = "red", midpoint = 0,
                       name = "Mean Z‑score") +
  labs(y = "Time (weeks)", x = "Parameter", 
       title = "Top 20 morphological parameters: temporal dynamics") +
  theme_classic() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 6),
        axis.text.y = element_text(size = 6))
print(Fig_S7$heatmap_plot)

# Line plot of temporal trends
Fig_S7$lineplot_time <- ggplot(Fig_S7$time_summary,
                               aes(x = Time_weeks, y = mean_z,
                                   group = parameter, color = parameter)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.5) +
  labs(x = "Time (weeks)", y = "Mean Z‑score",
       title = "Temporal trends of top 20 parameters") +
  theme_bw() +
  theme(legend.position = "top", legend.text = element_text(size = 5)) +
  guides(color = guide_legend(ncol = 6), size=2) +
  scale_color_viridis_d()
print(Fig_S7$lineplot_time)

# Table of changes from first to last time point
time_levels <- levels(factor(df$Time_weeks))
first_t <- time_levels[which.min(as.numeric(gsub("WPI", "", time_levels)))]
last_t  <- time_levels[which.max(as.numeric(gsub("WPI", "", time_levels)))]

Fig_S7$time_changes <- Fig_S7$time_summary %>%
  group_by(parameter) %>%
  summarise(
    first = mean_z[Time_weeks == first_t],
    last  = mean_z[Time_weeks == last_t],
    change = last - first,
    .groups = "drop"
  ) %>%
  arrange(desc(abs(change)))

print(Fig_S7$time_changes)

# ----------------------------------------------------------------------------
# 8. Summary of stored objects
# ----------------------------------------------------------------------------
cat("\n=== FIG_S7 COMPLETE ===\n")
cat("All results stored in list 'Fig_S7'.\n")
cat("Contents:\n")
print(names(Fig_S7))

# ============================================================================
# End of Supplementary Figure S7 script
# ============================================================================