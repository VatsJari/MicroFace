# ============================================
# CLUSTER ANALYSIS LIST - Sampling, Clustering, UMAP
# ============================================

# Load required libraries
library(dplyr)
library(ClusterR)
library(factoextra)
library(umap)
library(ggplot2)
library(RColorBrewer)
library(cluster)
library(patchwork)

# Create the main list
ClusterAnalysis <- list()

# Set seed for reproducibility
set.seed(123)

# ============================================
# 1. SAMPLING FUNCTIONS
# ============================================

# Stratified sampling function
ClusterAnalysis$sampling_strategy <- function(meta_data, feature_data, sample_size = 30000) {
  
  # Check for NA values in stratification variables
  if (any(is.na(meta_data$Impact_Region)) | any(is.na(meta_data$Animal_No)) | any(is.na(meta_data$Time_weeks))) {
    warning("NA values found in metadata. Removing rows with NAs.")
    complete_cases <- complete.cases(meta_data[, c("Impact_Region", "Animal_No", "Time_weeks")])
    meta_data <- meta_data[complete_cases, ]
    feature_data <- feature_data[complete_cases, ]
  }
  
  # Create stratification variables
  strata <- interaction(
    meta_data$Impact_Region,
    meta_data$Animal_No,
    meta_data$Time_weeks,
    drop = TRUE,
    sep = "_"
  )
  
  # Check if we have any strata
  if (length(strata) == 0) {
    stop("No valid strata found")
  }
  
  # Calculate proportional allocation
  strata_counts <- table(strata)
  strata_props <- strata_counts / sum(strata_counts)
  
  # Calculate samples per stratum (minimum 1 per stratum)
  samples_per_stratum <- pmax(1, floor(sample_size * strata_props))
  
  # Adjust if total exceeds sample_size
  current_total <- sum(samples_per_stratum)
  if (current_total > sample_size) {
    # Randomly reduce from largest strata
    excess <- current_total - sample_size
    strata_names <- names(samples_per_stratum)
    for (i in 1:excess) {
      # Find stratum with most samples (that has >1)
      valid_strata <- which(samples_per_stratum > 1)
      if (length(valid_strata) == 0) break
      reduce_idx <- valid_strata[which.max(samples_per_stratum[valid_strata])]
      samples_per_stratum[reduce_idx] <- samples_per_stratum[reduce_idx] - 1
    }
  } else if (current_total < sample_size) {
    # Add remaining to largest strata
    remaining <- sample_size - current_total
    strata_names <- names(samples_per_stratum)
    for (i in 1:remaining) {
      add_idx <- which.max(samples_per_stratum)
      samples_per_stratum[add_idx] <- samples_per_stratum[add_idx] + 1
    }
  }
  
  # Perform stratified sampling
  sampled_indices <- c()
  strata_levels <- levels(strata)
  
  for (i in seq_along(strata_levels)) {
    stratum_level <- strata_levels[i]
    stratum_indices <- which(strata == stratum_level)
    n_to_sample <- samples_per_stratum[i]
    
    if (n_to_sample > 0 && length(stratum_indices) > 0) {
      n_to_sample <- min(n_to_sample, length(stratum_indices))
      sampled_indices <- c(sampled_indices, 
                           sample(stratum_indices, n_to_sample, replace = FALSE))
    }
  }
  
  # If we couldn't get enough samples, add random ones
  if (length(sampled_indices) < sample_size) {
    remaining_needed <- sample_size - length(sampled_indices)
    remaining_indices <- setdiff(1:nrow(meta_data), sampled_indices)
    if (length(remaining_indices) > 0) {
      additional <- sample(remaining_indices, min(remaining_needed, length(remaining_indices)))
      sampled_indices <- c(sampled_indices, additional)
    }
  }
  
  return(sampled_indices)
}

# Simple random sampling
ClusterAnalysis$random_sampling <- function(meta_data, sample_size = 30000) {
  set.seed(123)
  sampled_indices <- sample(1:nrow(meta_data), min(sample_size, nrow(meta_data)), replace = FALSE)
  return(sampled_indices)
}

# Systematic sampling
ClusterAnalysis$systematic_sampling <- function(meta_data, sample_size = 30000) {
  n <- nrow(meta_data)
  interval <- floor(n / sample_size)
  start <- sample(1:interval, 1)
  sampled_indices <- seq(start, n, by = interval)
  # Adjust if we got too many
  if (length(sampled_indices) > sample_size) {
    sampled_indices <- sampled_indices[1:sample_size]
  }
  return(sampled_indices)
}

# Function to assign clusters to new data
ClusterAnalysis$assign_clusters <- function(new_data, centroids) {
  # Handle case when new_data is a vector (single row)
  if (is.null(dim(new_data))) {
    new_data <- matrix(new_data, nrow = 1)
  }
  
  distances <- matrix(0, nrow = nrow(new_data), ncol = nrow(centroids))
  for (i in 1:nrow(centroids)) {
    # Calculate Euclidean distance to centroid i
    centroid_matrix <- matrix(rep(centroids[i, ], each = nrow(new_data)), 
                              nrow = nrow(new_data))
    distances[, i] <- rowSums((new_data - centroid_matrix)^2)
  }
  return(apply(distances, 1, which.min))
}

# ============================================
# 2. EXECUTE SAMPLING
# ============================================

cat("\n=== TRYING DIFFERENT SAMPLING METHODS ===\n")

# Method 1: Try stratified sampling first
cat("\nTrying stratified sampling...\n")
ClusterAnalysis$sampled_idx <- tryCatch({
  ClusterAnalysis$sampling_strategy(Filter$meta_clean, Filter$feat_clean, sample_size = 30000)
}, error = function(e) {
  cat("Stratified sampling failed:", e$message, "\n")
  return(NULL)
})

# If stratified sampling fails, try systematic sampling
if (is.null(ClusterAnalysis$sampled_idx) || length(ClusterAnalysis$sampled_idx) < 1000) {
  cat("\nTrying systematic sampling...\n")
  ClusterAnalysis$sampled_idx <- ClusterAnalysis$systematic_sampling(Filter$meta_clean, sample_size = 30000)
}

# If systematic sampling fails, use random sampling
if (is.null(ClusterAnalysis$sampled_idx) || length(ClusterAnalysis$sampled_idx) < 1000) {
  cat("\nTrying random sampling...\n")
  ClusterAnalysis$sampled_idx <- ClusterAnalysis$random_sampling(Filter$meta_clean, sample_size = 30000)
}

# Final check
if (is.null(ClusterAnalysis$sampled_idx) || length(ClusterAnalysis$sampled_idx) == 0) {
  stop("All sampling methods failed!")
}

# Create sampled datasets
ClusterAnalysis$meta_sampled <- Filter$meta_clean[ClusterAnalysis$sampled_idx, ]
ClusterAnalysis$feat_sampled <- Filter$feat_clean[ClusterAnalysis$sampled_idx, ]
ClusterAnalysis$pca_scores_sampled <- PCA$pca$x[ClusterAnalysis$sampled_idx, 1:PCA$n_pcs_95]

cat("\nSuccessfully sampled", length(ClusterAnalysis$sampled_idx), "cells from", nrow(Filter$meta_clean), "total\n")

# ============================================
# 3. SAMPLING REPRESENTATION CHECK
# ============================================

cat("\n=== SAMPLING REPRESENTATION CHECK ===\n")

# Impact Region distribution
if ("Impact_Region" %in% names(Filter$meta_clean)) {
  cat("\nDistribution by Impact Region:\n")
  ClusterAnalysis$original_impact <- table(Filter$meta_clean$Impact_Region)
  ClusterAnalysis$sampled_impact <- table(ClusterAnalysis$meta_sampled$Impact_Region)
  ClusterAnalysis$impact_comparison <- data.frame(
    Original = ClusterAnalysis$original_impact,
    Sampled = ClusterAnalysis$sampled_impact[names(ClusterAnalysis$original_impact)],
    Prop_Original = round(prop.table(ClusterAnalysis$original_impact), 3),
    Prop_Sampled = round(prop.table(ClusterAnalysis$sampled_impact)[names(ClusterAnalysis$original_impact)], 3)
  )
  print(ClusterAnalysis$impact_comparison)
}

# Animal distribution
if ("Animal_No" %in% names(Filter$meta_clean)) {
  cat("\nDistribution by Animal:\n")
  ClusterAnalysis$original_animal <- table(Filter$meta_clean$Animal_No)
  ClusterAnalysis$sampled_animal <- table(ClusterAnalysis$meta_sampled$Animal_No)
  ClusterAnalysis$animal_comparison <- data.frame(
    Original = ClusterAnalysis$original_animal,
    Sampled = ClusterAnalysis$sampled_animal[names(ClusterAnalysis$original_animal)]
  )
  print(ClusterAnalysis$animal_comparison)
}

# Time distribution
if ("Time_weeks" %in% names(Filter$meta_clean)) {
  cat("\nDistribution by Time:\n")
  ClusterAnalysis$original_time <- table(Filter$meta_clean$Time_weeks)
  ClusterAnalysis$sampled_time <- table(ClusterAnalysis$meta_sampled$Time_weeks)
  ClusterAnalysis$time_comparison <- data.frame(
    Original = ClusterAnalysis$original_time,
    Sampled = ClusterAnalysis$sampled_time[names(ClusterAnalysis$original_time)]
  )
  print(ClusterAnalysis$time_comparison)
}

# Electrode Thickness distribution
if ("Electrode_Thickness" %in% names(Filter$meta_clean)) {
  cat("\nDistribution by thickness:\n")
  ClusterAnalysis$original_thickness <- table(Filter$meta_clean$Electrode_Thickness)
  ClusterAnalysis$sampled_thickness <- table(ClusterAnalysis$meta_sampled$Electrode_Thickness)
  ClusterAnalysis$thickness_comparison <- data.frame(
    Original = ClusterAnalysis$original_thickness,
    Sampled = ClusterAnalysis$sampled_thickness[names(ClusterAnalysis$original_thickness)]
  )
  print(ClusterAnalysis$thickness_comparison)
}

# ============================================
# 4. DETERMINE OPTIMAL K
# ============================================
'
cat("\n=== RUNNING CLUSTERING ON SAMPLED DATA ===\n")

# Elbow method (1-15 clusters)
ClusterAnalysis$wss <- numeric(15)
for (k in 1:15) {
  set.seed(123)
  km <- kmeans(ClusterAnalysis$pca_scores_sampled, centers = k, nstart = 25, iter.max = 100)
  ClusterAnalysis$wss[k] <- km$tot.withinss
}

# Plot elbow
dev.new(width = 8, height = 6)
plot(1:15, ClusterAnalysis$wss, type = "b", 
     xlab = "Number of Clusters (k)", 
     ylab = "Total Within-Cluster SS",
     main = "Elbow Method (Sampled Data)")
ClusterAnalysis$elbow_plot <- recordPlot()

# Silhouette method (k from 2 to 15)
ClusterAnalysis$sil_width <- numeric(14)
for (k in 2:15) {
  set.seed(123)
  km <- kmeans(ClusterAnalysis$pca_scores_sampled, centers = k, nstart = 25, iter.max = 100)
  sil <- silhouette(km$cluster, dist(ClusterAnalysis$pca_scores_sampled))
  ClusterAnalysis$sil_width[k-1] <- mean(sil[, 3])
}

# Plot silhouette
plot(2:15, ClusterAnalysis$sil_width, type = "b",
     xlab = "Number of Clusters (k)",
     ylab = "Average Silhouette Width",
     main = "Silhouette Method (Sampled Data)")
ClusterAnalysis$silhouette_plot <- recordPlot()

ClusterAnalysis$optimal_k_sil <- which.max(ClusterAnalysis$sil_width) + 1
cat("\nOptimal k from silhouette:", ClusterAnalysis$optimal_k_sil, "\n")
'
# ============================================
# 5. RUN FINAL CLUSTERING
# ============================================

# Set optimal k (can be adjusted manually)
ClusterAnalysis$optimal_k <- 13  # or use ClusterAnalysis$optimal_k_sil

set.seed(123)
ClusterAnalysis$final_kmeans <- kmeans(
  ClusterAnalysis$pca_scores_sampled, 
  centers = ClusterAnalysis$optimal_k, 
  nstart = 50, 
  iter.max = 100
)

# Assign clusters to sampled data
ClusterAnalysis$meta_sampled$Cluster <- factor(ClusterAnalysis$final_kmeans$cluster)

# Get centroids
ClusterAnalysis$centroids <- ClusterAnalysis$final_kmeans$centers

# ============================================
# 6. PREDICT CLUSTERS FOR FULL DATASET
# ============================================

cat("\nAssigning clusters to full dataset...\n")

# Assign clusters to full dataset
ClusterAnalysis$full_clusters <- ClusterAnalysis$assign_clusters(
  PCA$pca$x[, 1:PCA$n_pcs_95], 
  ClusterAnalysis$centroids
)
Filter$meta_clean$Cluster <- factor(ClusterAnalysis$full_clusters)

# ============================================
# 7. UMAP ON SAMPLED DATA
# ============================================

cat("\nRunning UMAP on sampled data...\n")

set.seed(42)

# Run UMAP on sampled PC scores
ClusterAnalysis$umap_sampled <- umap(
  ClusterAnalysis$pca_scores_sampled, 
  n_neighbors = 50,
  min_dist = 0.3,
  n_components = 2,
  spread = 6
)

# Add UMAP coordinates to sampled data
ClusterAnalysis$meta_sampled$UMAP1 <- ClusterAnalysis$umap_sampled$layout[, 1]
ClusterAnalysis$meta_sampled$UMAP2 <- ClusterAnalysis$umap_sampled$layout[, 2]

# ============================================
# 8. VISUALIZATIONS
# ============================================

cat("\n=== CREATING VISUALIZATIONS ===\n")

# Create color palette for clusters
ClusterAnalysis$morpho_colours <- colorRampPalette(brewer.pal(12, "Paired"))(ClusterAnalysis$optimal_k)

# 1. UMAP plot with base R
dev.new(width = 10, height = 8)
plot(ClusterAnalysis$meta_sampled$UMAP1, ClusterAnalysis$meta_sampled$UMAP2, 
     col = ClusterAnalysis$meta_sampled$Cluster,
     pch = 19, cex = 0.5,
     xlab = "UMAP1", ylab = "UMAP2",
     main = paste("UMAP -", ClusterAnalysis$optimal_k, "Clusters (Sampled", nrow(ClusterAnalysis$meta_sampled), "cells)"))
legend("topright", legend = levels(ClusterAnalysis$meta_sampled$Cluster), 
       col = 1:ClusterAnalysis$optimal_k, pch = 19, title = "Cluster")

# 2. UMAP with ggplot
ClusterAnalysis$gg_umap <- ggplot(ClusterAnalysis$meta_sampled, aes(UMAP1, UMAP2, color = Cluster)) +
  geom_point(size = 0.5, alpha = 0.7) +
  scale_color_manual(values = ClusterAnalysis$morpho_colours) +
  theme_classic() +
  labs(title = paste("UMAP -", ClusterAnalysis$optimal_k, "Clusters"),
       x = "UMAP1", y = "UMAP2") +
  theme(
    plot.title = element_text(size = 14, hjust = 0.5, face = "bold"),
    legend.position = "right"
  )

print(ClusterAnalysis$gg_umap)

# 3. UMAP faceted by thickness and time
if ("Electrode_Thickness" %in% names(ClusterAnalysis$meta_sampled) && 
    "Time_weeks" %in% names(ClusterAnalysis$meta_sampled)) {
  
  ClusterAnalysis$gg_umap_facet <- ggplot(ClusterAnalysis$meta_sampled, aes(UMAP1, UMAP2, color = Cluster)) +
    geom_point(size = 0.1, alpha = 0.5) +
    scale_color_manual(values = ClusterAnalysis$morpho_colours) +
    theme_classic() +
    facet_grid(Electrode_Thickness ~ Time_weeks) +
    labs(title = "UMAP by Thickness and Time") +
    theme(
      plot.title = element_text(size = 14, hjust = 0.5, face = "bold"),
      strip.text = element_text(size = 10, face = "bold"),
      legend.position = "bottom"
    )
  
  print(ClusterAnalysis$gg_umap_facet)
}

# 4. UMAP colored by Impact Region
if ("Impact_Region" %in% names(ClusterAnalysis$meta_sampled)) {
  ClusterAnalysis$gg_umap_region <- ggplot(ClusterAnalysis$meta_sampled, aes(UMAP1, UMAP2, color = Impact_Region)) +
    geom_point(size = 0.5, alpha = 0.7) +
    scale_color_manual(values = c("Close" = "#E66F74", "Middle" = "gray50", "Far" = "#A4D38F")) +
    theme_classic() +
    labs(title = "UMAP by Impact Region",
         x = "UMAP1", y = "UMAP2") +
    theme(
      plot.title = element_text(size = 14, hjust = 0.5, face = "bold"),
      legend.position = "bottom"
    )
  
  print(ClusterAnalysis$gg_umap_region)
}

# ============================================
# 9. CLUSTER SIZES AND DISTRIBUTIONS
# ============================================

cat("\n=== CLUSTER SIZES ===\n")
cat("Sampled data:\n")
ClusterAnalysis$cluster_sizes_sampled <- table(ClusterAnalysis$meta_sampled$Cluster)
print(ClusterAnalysis$cluster_sizes_sampled)

cat("\nFull dataset:\n")
ClusterAnalysis$cluster_sizes_full <- table(Filter$meta_clean$Cluster)
print(ClusterAnalysis$cluster_sizes_full)

cat("\nPercentages (full dataset):\n")
ClusterAnalysis$cluster_percentages <- round(100 * prop.table(ClusterAnalysis$cluster_sizes_full), 2)
print(ClusterAnalysis$cluster_percentages)

# Distribution plots
dev.new(width = 12, height = 10)
par(mfrow = c(2, 2))

if ("Impact_Region" %in% names(ClusterAnalysis$meta_sampled)) {
  ClusterAnalysis$cluster_impact <- table(ClusterAnalysis$meta_sampled$Cluster, 
                                          ClusterAnalysis$meta_sampled$Impact_Region)
  barplot(ClusterAnalysis$cluster_impact, beside = TRUE, 
          col = ClusterAnalysis$morpho_colours,
          legend = rownames(ClusterAnalysis$cluster_impact),
          main = "Impact Region by Cluster",
          xlab = "Impact Region", ylab = "Count")
}

if ("Animal_No" %in% names(ClusterAnalysis$meta_sampled)) {
  ClusterAnalysis$cluster_animal <- table(ClusterAnalysis$meta_sampled$Cluster, 
                                          ClusterAnalysis$meta_sampled$Animal_No)
  barplot(ClusterAnalysis$cluster_animal, beside = TRUE,
          col = ClusterAnalysis$morpho_colours,
          legend = rownames(ClusterAnalysis$cluster_animal),
          main = "Animal by Cluster",
          xlab = "Animal", ylab = "Count")
}

par(mfrow = c(1, 1))
ClusterAnalysis$distribution_plots <- recordPlot()

# ============================================
# 10. CREATE FINAL DATAFRAMES
# ============================================

# For sampled data (with UMAP)
ClusterAnalysis$final_df_sampled <- data.frame(
  Cell_ID = rownames(ClusterAnalysis$meta_sampled),
  UMAP1 = ClusterAnalysis$meta_sampled$UMAP1,
  UMAP2 = ClusterAnalysis$meta_sampled$UMAP2,
  PC1 = ClusterAnalysis$pca_scores_sampled[, 1],
  PC2 = ClusterAnalysis$pca_scores_sampled[, 2],
  PC3 = ClusterAnalysis$pca_scores_sampled[, 3],
  ClusterAnalysis$meta_sampled,
  ClusterAnalysis$feat_sampled
)

# For full dataset (without UMAP coordinates)
ClusterAnalysis$final_df_full <- data.frame(
  Cell_ID = rownames(Filter$meta_clean),
  Filter$meta_clean,
  PC1 = PCA$pca$x[, 1],
  PC2 = PCA$pca$x[, 2],
  PC3 = PCA$pca$x[, 3],
  Filter$feat_clean
)

# ============================================
# 11. SUMMARY STATISTICS
# ============================================

ClusterAnalysis$summary <- list(
  sampling_method = ifelse(!is.null(ClusterAnalysis$sampled_idx) && 
                             length(ClusterAnalysis$sampled_idx) > 0, "Success", "Failed"),
  sampled_cells = length(ClusterAnalysis$sampled_idx),
  total_cells = nrow(Filter$meta_clean),
  percentage_sampled = round(100 * length(ClusterAnalysis$sampled_idx) / nrow(Filter$meta_clean), 2),
  optimal_k = ClusterAnalysis$optimal_k,
  optimal_k_silhouette = ClusterAnalysis$optimal_k_sil,
  n_clusters = length(unique(ClusterAnalysis$meta_sampled$Cluster)),
  umap_params = list(
    n_neighbors = 50,
    min_dist = 0.3,
    spread = 6
  )
)

cat("\n=== ANALYSIS COMPLETE ===\n")
cat("Total cells processed:", nrow(Filter$meta_clean), "\n")
cat("Number of clusters:", ClusterAnalysis$optimal_k, "\n")
cat("Sampled cells:", length(ClusterAnalysis$sampled_idx), "\n")
cat("Percentage sampled:", ClusterAnalysis$summary$percentage_sampled, "%\n")

# ============================================
# 12. SAVE RESULTS (Optional)
# ============================================

# Save plots
# ggsave("UMAP_Clusters.png", ClusterAnalysis$gg_umap, width = 10, height = 8, dpi = 300)
# ggsave("UMAP_by_Region.png", ClusterAnalysis$gg_umap_region, width = 10, height = 8, dpi = 300)

# Save dataframes
# write.csv(ClusterAnalysis$final_df_sampled, "final_results_sampled.csv", row.names = FALSE)
# write.csv(ClusterAnalysis$final_df_full, "final_results_full.csv", row.names = FALSE)

cat("\n=== CLUSTER ANALYSIS COMPLETE ===\n")
cat("All results stored in 'ClusterAnalysis' list\n")
cat("Access results with ClusterAnalysis$object_name\n")

