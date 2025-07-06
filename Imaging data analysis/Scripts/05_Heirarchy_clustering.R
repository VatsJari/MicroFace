# ===================================================
# HIERARCHICAL CLUSTERING ANALYSIS PIPELINE
# ===================================================

# Initialize list to store all objects
H_clust <- list()

# -------------------------------
# 1. DATA PREPARATION
# -------------------------------
# Import and filter data
H_clust$df_clust <- import$df_all_reordered[, c(31, 32, 26, 35:82)] %>%
  filter(Bin_Number_New <= 16) %>%
  dplyr::select(-42)  # Remove column 42

# Scale the data (columns 4-50)
H_clust$scale <- scale(H_clust$df_clust[, c(4:47,49,50)])
H_clust$scaled_df <- cbind(H_clust$df_clust[, 1:3], H_clust$scale)

# -------------------------------
# 2. HIERARCHICAL CLUSTERING
# -------------------------------
# Cluster columns (features)
H_clust$cluster_cols <- hclust(dist(t(H_clust$scaled_df[, 4:49])))

# Custom sorting function for dendrogram
H_clust$sort_hclust <- function(...) as.hclust(dendsort(as.dendrogram(...)))

# Plot unsorted dendrogram
plot(H_clust$cluster_cols, 
     main = "Feature Clustering (Unsorted)", 
     xlab = "", sub = "")

# Sort and plot dendrogram
H_clust$cluster_cols <- H_clust$sort_hclust(H_clust$cluster_cols)
plot(H_clust$cluster_cols, 
     main = "Feature Clustering (Sorted)", 
     xlab = "", sub = "")

# Enhanced dendrogram visualization
H_clust$global_dendrogram <- fviz_dend(
  H_clust$cluster_cols, 
  cex = 0.6, 
  k = 4,
  rect = TRUE,
  k_colors = "uchicago",
  rect_border = "uchicago",
  rect_fill = TRUE,
  horiz = TRUE
) +
  theme(
    plot.title = element_text(size = 12, hjust = 0.5, face = "bold"),
    axis.title = element_text(size = 12, face = "bold"),
    axis.text = element_text(size = 8, face = "bold"),
    legend.text = element_text(size = 8, face = "bold"),
    legend.title = element_text(size = 8, face = "bold"),
    legend.key.size = unit(1.5, "lines"),
    legend.position = "bottom",
    strip.text = element_text(size = 8, face = "bold")
  )

# -------------------------------
# 3. IMPORTANCE ANALYSIS
# -------------------------------
# Calculate feature importance by time point
H_clust$importance <- aggregate(
  H_clust$scaled_df[, c(4, 6:49)],
  by = list(Weeks = H_clust$scaled_df$Time_weeks),
  FUN = sd
)

# Reshape data for visualization
H_clust$importance_melted <- melt(
  H_clust$importance,
  id.vars = "Weeks",
  variable.name = "Parameter",
  value.name = "Importance"
)

# Get top 15 most important features per time point
H_clust$top_features <- H_clust$importance_melted %>%
  group_by(Weeks) %>%
  slice_max(Importance, n = 15) %>%
  ungroup() %>%
  mutate(Importance_range = ifelse(Importance > 0, "Positive", "Negative"))

ggplot(H_clust$top_features, aes(y = Weeks, x = Parameter, fill = Importance ,color = Importance, size = abs(Importance))) + 
  geom_point_s(shape = 21, alpha = 20) +
  labs(title = "", fill = "Deviation", size = "Score") +
  theme_minimal()+
  scale_fill_gradient(high = "red",low = "blue")+
  scale_color_gradient(high = "red",low = "blue")+
  theme(
    plot.title = element_text(size = 12, hjust = 0.5, face = "bold"),
    axis.title.x = element_text(size = 10, face = "bold"),
    axis.title.y = element_text(size = 10, face = "bold"),
    axis.text.x = element_text(size = 7, face = "bold", angle = 45, hjust=1),
    axis.text.y = element_text(size = 9, face = "bold"),
    legend.text = element_text(size = 10, face = "bold"),
    legend.title = element_text(size = 10, face = "bold"),
    legend.key.size = unit(1.5, "lines"),
    legend.position = "right",
    strip.text = element_text(size = 10, face = "bold")
  ) +
  xlab("") +  # Remove x-axis label
  ylab("") 


  #------------------------
  # 4. TIME POINT COMPARISONS
  # -------------------------------
  # Compare feature importance across time points
  H_clust$sum_imp <- H_clust$top_features %>%
    group_by(Weeks) %>%
    summarize(total_importance = sd(Importance))
  
  # Plot importance trend
 ggplot(H_clust$sum_imp, aes(x = Weeks, y = total_importance)) +
    geom_col(aes(fill = factor(Weeks))) +
    geom_smooth(method = "lm", se = FALSE, color = "black") +
    scale_fill_manual(values = company_colors) +
    labs(
      x = "Time Points (Weeks)",
      y = "Average Feature Importance"
    ) +
    theme_bw()
  

  # Save results
  saveRDS(H_clust, "results/hierarchical_clustering_results.rds")