
# Load required libraries
library(reshape2)
library(dplyr)
library(ggplot2)
library(patchwork)



Fig3 <- list()


# Step 0: Filter to keep only Close and Far regions
Fig3$df_clust <- ClusterAnalysis$final_df_full
Fig3$df_filter <- filter(Fig3$df_clust, Bin_Number_New <= 25)
Fig3$scale <- Fig3$df_filter[, 23:ncol(Fig3$df_filter)]

# Remove Middle region - keep only Close and Far
#Fig3$df_clust <- Fig3$df_clust %>% filter(Impact_Region %in% c("Close", "Far"))

# Verify the filtering
cat("\n=== IMPACT REGIONS AFTER FILTERING ===\n")
print(table(Fig3$df_clust$Impact_Region))

# Calculate correlation matrix with pairwise complete observations
Fig3$cor_mat <- cor(Fig3$scale, use = "pairwise.complete.obs")

# Calculate p-values for correlation matrix
Fig3$testRes <- list()
n <- ncol(Fig3$scale)
Fig3$p_matrix <- matrix(NA, n, n)
colnames(Fig3$p_matrix) <- colnames(Fig3$scale)
rownames(Fig3$p_matrix) <- colnames(Fig3$scale)

for(i in 1:n) {
  for(j in 1:n) {
    if(i != j) {
      test <- cor.test(Fig3$scale[,i], Fig3$scale[,j], use = "pairwise.complete.obs")
      Fig3$p_matrix[i,j] <- test$p.value
    } else {
      Fig3$p_matrix[i,j] <- 0
    }
  }
}
Fig3$testRes$p_clean <- Fig3$p_matrix

# Plot correlation matrix
corrplot(Fig3$cor_mat, 
         method = "circle",
         type = "full",
         order = "hclust",
         p.mat = Fig3$testRes$p_clean,
         sig.level = 0.05,
         insig = "blank",
         tl.col = "black",
         cl.cex = 0.8,
         col = COL2('PiYG'))

# ============================================
# TOP 20 PARAMETER ANALYSIS (CLOSE VS FAR)
# ============================================

# Step 1: Identify all parameter columns (exclude metadata and identifiers)
Fig3$metadata_cols <- c("Cell_ID", "PC1", "PC2", "PC3",
                        "FileName_Original_Iba1_cell", "Animal_No", "Time_weeks", 
                        "Electrode_Thickness", "SubImage", "ImageNumber_cell", 
                        "Condition_cell", "Center_X_soma", "Center_Y_soma", 
                        "Injury_x", "Injury_y", "radial_dist", "bin_number", 
                        "bin_range", "Bin_Number_New", "bin_range_new", 
                        "Impact_Region", "Cluster")

# Get all parameter columns (everything not in metadata)
Fig3$all_params <- Fig3$df_clust %>%
  dplyr::select(-one_of(Fig3$metadata_cols))

cat("\nTotal parameters found:", ncol(Fig3$all_params), "\n")

# Step 2: Calculate variance across Impact Regions to find top varying parameters
Fig3$param_variance <- Fig3$df_clust %>%
  group_by(Impact_Region) %>%
  summarise(across(all_of(colnames(Fig3$all_params)), ~ median(.x, na.rm = TRUE))) %>%
  dplyr::select(-Impact_Region) %>%
  summarise(across(everything(), var, na.rm = TRUE)) %>%
  pivot_longer(everything(), names_to = "Parameter", values_to = "Variance") %>%
  arrange(desc(Variance))

# Get top 20 most varying parameters
Fig3$top20_params <- Fig3$param_variance$Parameter[1:20]
cat("\nTop 20 most varying parameters (Close vs Far):\n")
print(Fig3$top20_params)

# Step 3: Calculate mean values for top 20 parameters by Impact Region
Fig3$summary_stats <- Fig3$df_clust %>%
  group_by(Impact_Region) %>%
  summarise(across(all_of(Fig3$top20_params), ~ median(.x, na.rm = TRUE)))

# Step 4: Reshape for heatmap
Fig3$heatmap_data <- reshape2::melt(Fig3$summary_stats, id.vars = "Impact_Region")
colnames(Fig3$heatmap_data) <- c("Impact_Region", "Parameter", "Mean_Value")

# Step 5: Calculate z-scores to show relative changes
Fig3$heatmap_data <- Fig3$heatmap_data %>%
  group_by(Parameter) %>%
  mutate(
    Z_Score = scale(Mean_Value)[,1],
    # For two groups, Z_Score is simply (value - mean)/sd
    # Positive means higher in Far, negative means higher in Close
    Direction = ifelse(Z_Score > 0, "Higher in Far", "Higher in Close")
  ) %>%
  ungroup()

# Step 6: Create clean parameter names for better readability
Fig3$heatmap_data$Parameter_Clean <- gsub("_", " ", Fig3$heatmap_data$Parameter)
Fig3$heatmap_data$Parameter_Clean <- gsub("cell", "(Cell)", Fig3$heatmap_data$Parameter_Clean)
Fig3$heatmap_data$Parameter_Clean <- gsub("soma", "(Soma)", Fig3$heatmap_data$Parameter_Clean)
Fig3$heatmap_data$Parameter_Clean <- gsub("ratio", "Ratio", Fig3$heatmap_data$Parameter_Clean)

# Reorder parameters by Z_Score in Far region
Fig3$parameter_order <- Fig3$heatmap_data %>%
  filter(Impact_Region == "Far") %>%
  arrange(Z_Score) %>%
  pull(Parameter_Clean)

Fig3$heatmap_data$Parameter_Clean <- factor(Fig3$heatmap_data$Parameter_Clean, 
                                            levels = Fig3$parameter_order)

# ============================================
# PLOT 1: Heatmap with ACTUAL VALUES
# ============================================

Fig3$heatmap_actual <- ggplot(Fig3$heatmap_data, 
                              aes(x = Impact_Region, 
                                  y = Parameter_Clean, 
                                  fill = Mean_Value)) +
  geom_tile(color = "white", linewidth = 0.5) +
  geom_text(aes(label = round(Mean_Value, 2)), size = 3, fontface = "bold") +
  scale_fill_gradientn(
    colors = c("#E66F74", "white", "#A4D38F"),
    name = "Mean Value"
  ) +
  theme_classic() +
  labs(
    title = "Top 20 Parameters: Close vs Far (Actual Values)",
    x = "Impact Region",
    y = "Parameter"
  ) +
  theme(
    plot.title = element_text(size = 14, hjust = 0.5, face = "bold"),
    axis.title.x = element_text(size = 12, face = "bold"),
    axis.title.y = element_text(size = 12, face = "bold"),
    axis.text.x = element_text(size = 12, face = "bold"),
    axis.text.y = element_text(size = 10, face = "bold"),
    legend.title = element_text(size = 10, face = "bold"),
    legend.text = element_text(size = 9),
    legend.position = "right"
  )

print(Fig3$heatmap_actual)

# ============================================
# PLOT 2: Heatmap with Z-SCORES (Scaled Values)
# ============================================

Fig3$heatmap_scaled <- ggplot(Fig3$heatmap_data, 
                              aes(x = Impact_Region, 
                                  y = Parameter_Clean, 
                                  fill = Z_Score)) +
  geom_tile(color = "white", linewidth = 0.5) +
  geom_text(aes(label = round(Z_Score, 2)), size = 3, fontface = "bold") +
  scale_fill_gradient2(
    low = "#E66F74",      # Red for higher in Close
    mid = "white",        # White for similar
    high = "#A4D38F",     # Green for higher in Far
    midpoint = 0,
    name = "Z-Score"
  ) +
  theme_classic() +
  labs(
    title = "Top 20 Parameters: Close vs Far (Z-Score)",
    x = "Impact Region",
    y = "Parameter"
  ) +
  theme(
    plot.title = element_text(size = 14, hjust = 0.5, face = "bold"),
    axis.title.x = element_text(size = 12, face = "bold"),
    axis.title.y = element_text(size = 12, face = "bold"),
    axis.text.x = element_text(size = 12, face = "bold"),
    axis.text.y = element_text(size = 10, face = "bold"),
    legend.title = element_text(size = 10, face = "bold"),
    legend.text = element_text(size = 9),
    legend.position = "right"
  )

print(Fig3$heatmap_scaled)

# ============================================
# PLOT 3: Dot plot showing percent change
# ============================================

# Calculate percent change from Close to Far
Fig3$percent_change <- Fig3$heatmap_data %>%
  group_by(Parameter) %>%
  summarise(
    Close_Mean = Mean_Value[Impact_Region == "Close"],
    Far_Mean = Mean_Value[Impact_Region == "Far"],
    Percent_Change = ((Far_Mean - Close_Mean) / Close_Mean) * 100,
    Z_Score_Far = Z_Score[Impact_Region == "Far"],
    Parameter_Clean = first(Parameter_Clean),
    .groups = "drop"
  ) %>%
  mutate(
    Direction = ifelse(Percent_Change > 0, "Increase in Far", "Decrease in Far"),
    Abs_Change = abs(Percent_Change)
  ) %>%
  arrange(desc(Abs_Change))

Fig3$dot_plot <- ggplot(Fig3$percent_change, 
                        aes(x = reorder(Parameter_Clean, Percent_Change), 
                            y = Percent_Change, 
                            fill = Direction)) +
  geom_bar(stat = "identity", width = 0.7) +
  geom_text(aes(label = paste0(round(Percent_Change, 1), "%")), 
            hjust = ifelse(Fig3$percent_change$Percent_Change > 0, -0.1, 1.1),
            size = 3) +
  scale_fill_manual(values = c("Increase in Far" = "#A4D38F", 
                               "Decrease in Far" = "#E66F74")) +
  coord_flip() +
  theme_classic() +
  labs(
    title = "Percent Change: Close → Far",
    x = "", y = "Percent Change (%)"
  ) +
  theme(
    plot.title = element_text(size = 14, hjust = 0.5, face = "bold"),
    axis.text.y = element_text(size = 10, face = "bold"),
    axis.text.x = element_text(size = 10, face = "bold"),
    legend.position = "bottom",
    legend.title = element_blank()
  )

print(Fig3$dot_plot)



#===========================================
# COMBINE PLOTS
# ============================================

# Combine actual and scaled heatmaps
Fig3$combined_heatmaps <- Fig3$heatmap_actual + Fig3$heatmap_scaled +
  plot_annotation(
    title = "Top 20 Parameters: Close vs Far Regions",
    theme = theme(plot.title = element_text(size = 16, face = "bold", hjust = 0.5))
  )

print(Fig3$combined_heatmaps)

# Full figure with all plots
Fig3$full_figure <- (Fig3$heatmap_actual | Fig3$heatmap_scaled) /
  (Fig3$dot_plot | Fig3$volcano_plot) +
  plot_annotation(
    title = "Figure 3: Parameter Changes: Close vs Far Regions",
    theme = theme(plot.title = element_text(size = 18, face = "bold", hjust = 0.5))
  )

print(Fig3$full_figure)

# ============================================
# SUMMARY STATISTICS
# ============================================

Fig3$summary <- list(
  total_parameters = ncol(Fig3$all_params),
  top20_list = Fig3$top20_params,
  parameters_increasing = Fig3$percent_change %>%
    filter(Percent_Change > 0) %>%
    pull(Parameter_Clean),
  parameters_decreasing = Fig3$percent_change %>%
    filter(Percent_Change < 0) %>%
    pull(Parameter_Clean),
  significant_parameters = Fig3$volcano_data %>%
    filter(p_value < 0.05) %>%
    pull(Parameter_Clean),
  max_increase = Fig3$percent_change %>%
    slice_max(Percent_Change, n = 1) %>%
    dplyr::select(Parameter_Clean, Percent_Change),
  max_decrease = Fig3$percent_change %>%
    slice_min(Percent_Change, n = 1) %>%
    dplyr::select(Parameter_Clean, Percent_Change)
)

cat("\n=== FIG3 SUMMARY (CLOSE VS FAR) ===\n")
cat("Parameters increasing in Far region:\n")
print(Fig3$summary$parameters_increasing)
cat("\nParameters decreasing in Far region:\n")
print(Fig3$summary$parameters_decreasing)
cat("\nSignificant parameters (p < 0.05):\n")
print(Fig3$summary$significant_parameters)