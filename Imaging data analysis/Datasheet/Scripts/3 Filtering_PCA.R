library(dplyr)
library(MASS)
library(gridExtra)
library(ggplot2)
library(patchwork)

# ============================================
# FILTER LIST - Data cleaning and outlier removal with QC plots
# ============================================
Filter <- list()

# Check if import exists and has the required data
if (!exists("import") || is.null(import$df_all_PCA)) {
  stop("import$df_all_PCA not found")
}

# Split metadata and features
Filter$meta_df <- import$df_all_PCA[, 1:17]
Filter$feat_df <- import$df_all_PCA[, 18:ncol(import$df_all_PCA)] %>%
  dplyr::select(where(is.numeric))

# Store original data for QC comparison
Filter$original_data <- list(
  meta = Filter$meta_df,
  feat = Filter$feat_df,
  n_cells = nrow(Filter$meta_df)
)

# Winsorize function to handle outliers
Filter$winsorize <- function(x, p = 0.01) {
  q <- quantile(x, c(p, 1 - p), na.rm = TRUE)
  x[x < q[1]] <- q[1]
  x[x > q[2]] <- q[2]
  x
}

# Apply winsorization
Filter$feat_wins <- Filter$feat_df %>%
  mutate(across(everything(), ~Filter$winsorize(.x, 0.01)))

# Check for and handle NA values
if (anyNA(Filter$feat_wins)) {
  warning("NA values found in feat_wins. Removing rows with NAs.")
  Filter$complete_rows <- complete.cases(Filter$feat_wins)
  Filter$feat_wins <- Filter$feat_wins[Filter$complete_rows, ]
  Filter$meta_df <- Filter$meta_df[Filter$complete_rows, ]
}

# Calculate Mahalanobis distance for outlier removal
Filter$md <- mahalanobis(
  Filter$feat_wins,
  colMeans(Filter$feat_wins),
  cov(Filter$feat_wins)
)

Filter$cutoff <- qchisq(0.999, df = ncol(Filter$feat_wins))
Filter$keep_idx <- Filter$md < Filter$cutoff

# Keep only non-outlier rows
Filter$meta_clean <- Filter$meta_df[Filter$keep_idx, ]
Filter$feat_clean <- Filter$feat_wins[Filter$keep_idx, ]

# Combine clean data
Filter$df_clean_final <- cbind(Filter$meta_clean, Filter$feat_clean)

# Scale features using median and IQR (robust scaling)
Filter$feat_scaled <- scale(
  Filter$feat_clean,
  center = apply(Filter$feat_clean, 2, median),
  scale  = apply(Filter$feat_clean, 2, IQR)
)

# Final dataframe for PCA
Filter$df_final_for_PCA <- cbind(Filter$meta_clean, Filter$feat_scaled)

# ============================================
# QC PLOTS FOR MANUSCRIPT
# ============================================

cat("\n=== GENERATING QC PLOTS ===\n")

# Create a directory for QC plots (optional)
# dir.create("QC_plots", showWarnings = FALSE)

# 1. CELL COUNT BAR PLOT - Before vs After filtering
Filter$cell_count_df <- data.frame(
  Stage = c("Original", "After Filtering"),
  Cell_Count = c(Filter$original_data$n_cells, nrow(Filter$meta_clean)),
  Percentage = c(100, round(100 * nrow(Filter$meta_clean)/Filter$original_data$n_cells, 1))
)

Filter$plot_cell_count <- ggplot(Filter$cell_count_df, aes(x = Stage, y = Cell_Count, fill = Stage)) +
  geom_bar(stat = "identity", width = 0.5) +
  geom_text(aes(label = paste0(Cell_Count, "\n(", Percentage, "%)")), 
            vjust = 2, size = 3, fontface = "bold") +
  theme_classic() +
  labs(
       x = "", y = "Number of Cells") +
  theme(
    plot.title = element_text(size = 10, hjust = 0.5, face = "bold"),
    axis.title.y = element_text(size = 8, face = "bold"),
    axis.text.x = element_text(size = 8, face = "bold"),
    axis.text.y = element_text(size = 8),
    legend.position = "none"
  )

print(Filter$plot_cell_count)

# 2. MAHALANOBIS DISTRIBUTION - Showing cutoff
Filter$md_df <- data.frame(
  Mahalanobis_Distance = Filter$md,
  Status = ifelse(Filter$keep_idx, "Kept", "Removed")
)

Filter$plot_mahalanobis <- ggplot(Filter$md_df, aes(x = Mahalanobis_Distance, fill = Status)) +
  geom_histogram(bins = 100, alpha = 0.7, position = "identity", width = 1) +
  geom_vline(xintercept = Filter$cutoff, color = "red", linetype = "dashed", size = 1) +
  annotate("text", x = Filter$cutoff * 1.1, y = max(hist(Filter$md, plot = FALSE)$counts) * 0.9,
           label = paste("Cutoff =", round(Filter$cutoff, 1)), color = "red", size = 2, fontface = "bold") +
  theme_classic() +
  labs(title = "Mahalanobis Distance Distribution",
       x = "Mahalanobis Distance", y = "Frequency") +
  theme(
    plot.title = element_text(size = 10, hjust = 0.5, face = "bold"),
    axis.title = element_text(size = 8, face = "bold"),
    legend.position = "right"
  )

print(Filter$plot_mahalanobis)

# 3. PCA BEFORE FILTERING (first 2 PCs using original data)
# Calculate PCA on original data for comparison
Filter$pca_original <- prcomp(Filter$feat_df, center = TRUE, scale. = TRUE)
Filter$pca_original_df <- data.frame(
  PC1 = Filter$pca_original$x[, 1],
  PC2 = Filter$pca_original$x[, 2],
  Status = "Original"
)

# PCA after filtering
Filter$pca_filtered <- prcomp(Filter$feat_clean, center = TRUE, scale. = TRUE)
Filter$pca_filtered_df <- data.frame(
  PC1 = Filter$pca_filtered$x[, 1],
  PC2 = Filter$pca_filtered$x[, 2],
  Status = "Filtered"
)

# Combine for plotting
Filter$pca_combined <- rbind(
  cbind(Filter$pca_original_df, Type = "Original"),
  cbind(Filter$pca_filtered_df, Type = "Filtered")
)

Filter$plot_pca_comparison <- ggplot(Filter$pca_combined, aes(x = PC1, y = PC2, color = Type)) +
  geom_point(alpha = 0.3, size = 0.5) +
  scale_color_manual(values = c("Original" = "red", "Filtered" = "green")) +
  facet_wrap(~Type, ncol = 2) +
  theme_classic() +
  labs(title = "PCA Comparison: Original vs Filtered Data",
       x = "PC1", y = "PC2") +
  theme(
    plot.title = element_text(size = 14, hjust = 0.5, face = "bold"),
    axis.title = element_text(size = 12, face = "bold"),
    legend.position = "none",
    strip.text = element_text(size = 12, face = "bold")
  )

print(Filter$plot_pca_comparison)

# 4. FEATURE DISTRIBUTION BEFORE vs AFTER (for top 6 most variable features)
# Find most variable features
Filter$feature_variance <- apply(Filter$feat_df, 2, var, na.rm = TRUE)
Filter$top_features <- names(sort(Filter$feature_variance, decreasing = TRUE))[1:6]

# Create long format data for plotting
Filter$feature_dist_original <- Filter$feat_df %>%
  dplyr::select(all_of(Filter$top_features)) %>%
  pivot_longer(everything(), names_to = "Feature", values_to = "Value") %>%
  mutate(Stage = "Original")

Filter$feature_dist_filtered <- Filter$feat_clean %>%
  dplyr::select(all_of(Filter$top_features)) %>%
  pivot_longer(everything(), names_to = "Feature", values_to = "Value") %>%
  mutate(Stage = "Filtered")

Filter$feature_dist <- rbind(Filter$feature_dist_original, Filter$feature_dist_filtered)

# Create clean feature names
Filter$feature_dist$Feature_Clean <- gsub("_", " ", Filter$feature_dist$Feature)
Filter$feature_dist$Feature_Clean <- gsub("cell", "(Cell)", Filter$feature_dist$Feature_Clean)
Filter$feature_dist$Feature_Clean <- gsub("soma", "(Soma)", Filter$feature_dist$Feature_Clean)

Filter$plot_feature_dist <- ggplot(Filter$feature_dist, aes(x = Value, fill = Stage)) +
  geom_density(alpha = 0.5) +
  facet_wrap(~Feature_Clean, scales = "free", ncol = 3) +
  theme_classic() +
  labs(title = "Top 6 Most Variable Features: Original vs Filtered",
       x = "Value", y = "Density") +
  theme(
    plot.title = element_text(size = 14, hjust = 0.5, face = "bold"),
    axis.title = element_text(size = 12, face = "bold"),
    axis.text.x = element_text(angle = 45, hjust = 1, size = 8),
    strip.text = element_text(size = 10, face = "bold"),
    legend.position = "bottom"
  )

print(Filter$plot_feature_dist)

# 5. OUTLIER PROPORTION BY CATEGORICAL VARIABLES (if available)
Filter$outlier_status <- data.frame(
  Impact_Region = Filter$meta_df$Impact_Region,
  Animal_No = Filter$meta_df$Animal_No,
  Time_weeks = Filter$meta_df$Time_weeks,
  Status = ifelse(Filter$keep_idx, "Kept", "Removed")
)

# By Impact Region
if ("Impact_Region" %in% names(Filter$meta_df)) {
  Filter$outlier_by_region <- Filter$outlier_status %>%
    group_by(Impact_Region, Status) %>%
    summarise(Count = n(), .groups = "drop") %>%
    group_by(Impact_Region) %>%
    mutate(Percentage = Count / sum(Count) * 100)
  
  Filter$plot_outlier_region <- ggplot(Filter$outlier_by_region, 
                                       aes(x = Impact_Region, y = Percentage, fill = Status)) +
    geom_bar(stat = "identity", position = "stack") +
    scale_fill_manual(values = c("Kept" = "green", "Removed" = "red")) +
    theme_classic() +
    labs(title = "Outlier Proportion by Impact Region",
         x = "Impact Region", y = "Percentage (%)") +
    theme(
      plot.title = element_text(size = 14, hjust = 0.5, face = "bold"),
      axis.title = element_text(size = 12, face = "bold"),
      axis.text.x = element_text(angle = 45, hjust = 1),
      legend.position = "bottom"
    )
  
  print(Filter$plot_outlier_region)
}

# 6. SUMMARY TABLE PLOT
Filter$summary_table <- data.frame(
  Metric = c("Total Cells", "Cells Kept", "Cells Removed", "Removal Rate", 
             "Features Used", "Winsorization Threshold", "Mahalanobis Cutoff"),
  Value = c(
    Filter$original_data$n_cells,
    nrow(Filter$meta_clean),
    sum(!Filter$keep_idx),
    paste0(round(100 * sum(!Filter$keep_idx)/Filter$original_data$n_cells, 2), "%"),
    ncol(Filter$feat_clean),
    "1% (both tails)",
    round(Filter$cutoff, 2)
  )
)

# Create a table plot
Filter$plot_summary <- ggplot() +
  annotate("text", x = 0, y = 0, label = "FILTERING SUMMARY", 
           size = 6, fontface = "bold", hjust = 0) +
  annotate("text", x = 0, y = -0.1, 
           label = paste(capture.output(print(Filter$summary_table, row.names = FALSE)), collapse = "\n"),
           size = 4, family = "mono", hjust = 0) +
  theme_void() +
  xlim(-0.5, 1) + ylim(-1, 0.2)

# ============================================
# COMBINE ALL QC PLOTS FOR MANUSCRIPT
# ============================================

# Option 1: Using patchwork to create a composite figure
Filter$qc_figure <- (Filter$plot_cell_count | Filter$plot_mahalanobis) /
  (Filter$plot_pca_comparison) /
  (Filter$plot_feature_dist) +
  plot_annotation(
    title = "Quality Control: Cell Filtering Workflow",
    subtitle = paste0("Removed ", sum(!Filter$keep_idx), " outlier cells (", 
                      round(100 * sum(!Filter$keep_idx)/Filter$original_data$n_cells, 1), "% of total)"),
    theme = theme(
      plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray30")
    )
  )

# Display the combined figure
print(Filter$qc_figure)

# Option 2: Save the QC figure for manuscript
# ggsave("QC_Figure_Manuscript.png", Filter$qc_figure, width = 14, height = 12, dpi = 300)
# ggsave("QC_Figure_Manuscript.pdf", Filter$qc_figure, width = 14, height = 12)

# Option 3: Create a simpler 2-panel figure for main text
Filter$main_qc <- (Filter$plot_cell_count | Filter$plot_mahalanobis) +
  plot_annotation(
    title = "Cell Filtering Quality Control",
    theme = theme(plot.title = element_text(size = 14, face = "bold", hjust = 0.5))
  )

print(Filter$main_qc)

# ============================================
# PRINT DIAGNOSTICS
# ============================================
cat("\n=== FILTERING DIAGNOSTICS ===\n")
cat("Original rows:", Filter$original_data$n_cells, "\n")
cat("Clean rows:", nrow(Filter$df_clean_final), "\n")
cat("Cells removed:", sum(!Filter$keep_idx), "\n")
cat("Percentage kept:", round(100 * nrow(Filter$df_clean_final)/Filter$original_data$n_cells, 2), "%\n")
cat("Mahalanobis cutoff:", round(Filter$cutoff, 2), "\n")

cat("\n=== QC PLOTS CREATED ===\n")
cat("1. plot_cell_count - Bar plot of cell counts before/after\n")
cat("2. plot_mahalanobis - Distribution with cutoff line\n")
cat("3. plot_pca_comparison - PCA before vs after\n")
cat("4. plot_feature_dist - Feature distributions\n")
if (exists("Filter$plot_outlier_region")) cat("5. plot_outlier_region - Outliers by category\n")
cat("6. qc_figure - Combined figure for manuscript\n")




# ============================================
# PCA LIST - Principal Component Analysis
# ============================================
PCA <- list()

# Perform PCA
PCA$pca <- prcomp(Filter$feat_scaled, center = TRUE, scale. = TRUE)

# Calculate variance explained
PCA$var_explained <- PCA$pca$sdev^2 / sum(PCA$pca$sdev^2)

# Create scree plot in a new window or save to file
dev.new(width = 8, height = 6)
plot(PCA$var_explained[1:20], type = "b",
     xlab = "Principal Component",
     ylab = "Proportion of Variance Explained",
     main = "Scree Plot (First 20 PCs)")
abline(h = 0.05, col = "red", lty = 2)

# Print cumulative variance
cat("\n=== PCA DIAGNOSTICS ===\n")
cat("Cumulative variance explained:\n")
print(round(cumsum(PCA$var_explained)[1:20], 4))

# Get number of PCs to explain 95% variance
PCA$n_pcs_95 <- which(cumsum(PCA$var_explained) >= 0.97)[1]
cat("\nNumber of PCs explaining 95% variance:", PCA$n_pcs_95, "\n")

# Extract PC scores (first 10 PCs for flexibility)
PCA$pca_scores <- data.frame(PCA$pca$x[, 1:10])
colnames(PCA$pca_scores) <- paste0("PC", 1:10)

# Add metadata to PC scores
PCA$pca_df <- cbind(Filter$meta_clean, PCA$pca_scores)

# Check available metadata columns for plotting
cat("\nAvailable metadata columns for plotting:\n")
print(names(Filter$meta_clean))

# ============================================
# PLOTTING - Using the PCA list (FIXED MARGIN ISSUE)
# ============================================
cat("\n=== GENERATING PLOTS ===\n")

# Option 1: Create a larger plotting window
dev.new(width = 12, height = 10)

# Set up 2x2 plotting area with adjusted margins
par(mfrow = c(2, 2), mar = c(4, 4, 3, 1), oma = c(1, 1, 2, 1))

# Plot 1: Color by Impact_Region (if available)
if ("Impact_Region" %in% names(PCA$pca_df)) {
  plot(PCA$pca_df$PC1, PCA$pca_df$PC2, 
       col = as.factor(PCA$pca_df$Impact_Region),
       pch = 19, cex = 0.3,  # Smaller points
       xlab = paste0("PC1 (", round(PCA$var_explained[1]*100, 1), "%)"),
       ylab = paste0("PC2 (", round(PCA$var_explained[2]*100, 1), "%)"),
       main = "By Impact Region")
  legend("topright", legend = levels(as.factor(PCA$pca_df$Impact_Region)), 
         col = 1:length(unique(PCA$pca_df$Impact_Region)), pch = 19, cex = 0.6)
} else {
  plot(PCA$pca_df$PC1, PCA$pca_df$PC2, pch = 19, cex = 0.3,
       xlab = paste0("PC1 (", round(PCA$var_explained[1]*100, 1), "%)"),
       ylab = paste0("PC2 (", round(PCA$var_explained[2]*100, 1), "%)"),
       main = "PCA Plot")
}

# Plot 2: Color by Animal_No
if ("Animal_No" %in% names(PCA$pca_df)) {
  plot(PCA$pca_df$PC1, PCA$pca_df$PC2, 
       col = as.factor(PCA$pca_df$Animal_No),
       pch = 19, cex = 0.3,
       xlab = paste0("PC1 (", round(PCA$var_explained[1]*100, 1), "%)"),
       ylab = paste0("PC2 (", round(PCA$var_explained[2]*100, 1), "%)"),
       main = "By Animal")
  legend("topright", legend = levels(as.factor(PCA$pca_df$Animal_No)), 
         col = 1:length(unique(PCA$pca_df$Animal_No)), pch = 19, cex = 0.6)
}

# Plot 3: Color by Time_weeks
if ("Time_weeks" %in% names(PCA$pca_df)) {
  plot(PCA$pca_df$PC1, PCA$pca_df$PC2, 
       col = as.factor(PCA$pca_df$Time_weeks),
       pch = 19, cex = 0.3,
       xlab = paste0("PC1 (", round(PCA$var_explained[1]*100, 1), "%)"),
       ylab = paste0("PC2 (", round(PCA$var_explained[2]*100, 1), "%)"),
       main = "By Time")
  legend("topright", legend = levels(as.factor(PCA$pca_df$Time_weeks)), 
         col = 1:length(unique(PCA$pca_df$Time_weeks)), pch = 19, cex = 0.6)
}

# Plot 4: Color by bin_number or radial_dist
if ("Bin_Number_New" %in% names(PCA$pca_df)) {
  # Create color gradient for bins
  bin_colors <- colorRampPalette(c("blue", "cyan", "yellow", "red"))(length(unique(PCA$pca_df$Bin_Number_New)))
  plot(PCA$pca_df$PC1, PCA$pca_df$PC2, 
       col = bin_colors[as.factor(PCA$pca_df$Bin_Number_New)],
       pch = 19, cex = 0.3,
       xlab = paste0("PC1 (", round(PCA$var_explained[1]*100, 1), "%)"),
       ylab = paste0("PC2 (", round(PCA$var_explained[2]*100, 1), "%)"),
       main = "By Bin Number")
  legend("topright", legend = sort(unique(PCA$pca_df$Bin_Number_New)), 
         col = bin_colors, pch = 19, cex = 0.5, ncol = 2)
} else if ("radial_dist" %in% names(PCA$pca_df)) {
  plot(PCA$pca_df$PC1, PCA$pca_df$PC2, 
       col = colorRampPalette(c("blue", "red"))(100)[cut(PCA$pca_df$radial_dist, 100)],
       pch = 19, cex = 0.3,
       xlab = paste0("PC1 (", round(PCA$var_explained[1]*100, 1), "%)"),
       ylab = paste0("PC2 (", round(PCA$var_explained[2]*100, 1), "%)"),
       main = "By Radial Distance")
}

# Add overall title
mtext("PCA Visualizations", outer = TRUE, line = 0.5, cex = 1.5, font = 2)

# Reset plotting parameters
par(mfrow = c(1, 1))

# ============================================
# ALTERNATIVE: Save plots to file (avoids margin issues)
# ============================================
cat("\n=== SAVING PLOTS TO FILE ===\n")

# Save as PDF
#pdf("PCA_Plots.pdf", width = 12, height = 10)
par(mfrow = c(2, 2), mar = c(4, 4, 3, 1), oma = c(1, 1, 2, 1))

# Plot 1
if ("Impact_Region" %in% names(PCA$pca_df)) {
  plot(PCA$pca_df$PC1, PCA$pca_df$PC2, 
       col = as.factor(PCA$pca_df$Impact_Region),
       pch = 19, cex = 0.3,
       xlab = paste0("PC1 (", round(PCA$var_explained[1]*100, 1), "%)"),
       ylab = paste0("PC2 (", round(PCA$var_explained[2]*100, 1), "%)"),
       main = "By Impact Region")
  legend("topright", legend = levels(as.factor(PCA$pca_df$Impact_Region)), 
         col = 1:length(unique(PCA$pca_df$Impact_Region)), pch = 19, cex = 0.6)
}

# Plot 2
if ("Animal_No" %in% names(PCA$pca_df)) {
  plot(PCA$pca_df$PC1, PCA$pca_df$PC2, 
       col = as.factor(PCA$pca_df$Animal_No),
       pch = 19, cex = 0.3,
       xlab = paste0("PC1 (", round(PCA$var_explained[1]*100, 1), "%)"),
       ylab = paste0("PC2 (", round(PCA$var_explained[2]*100, 1), "%)"),
       main = "By Animal")
  legend("topright", legend = levels(as.factor(PCA$pca_df$Animal_No)), 
         col = 1:length(unique(PCA$pca_df$Animal_No)), pch = 19, cex = 0.6)
}

# Plot 3
if ("Time_weeks" %in% names(PCA$pca_df)) {
  plot(PCA$pca_df$PC1, PCA$pca_df$PC2, 
       col = as.factor(PCA$pca_df$Time_weeks),
       pch = 19, cex = 0.3,
       xlab = paste0("PC1 (", round(PCA$var_explained[1]*100, 1), "%)"),
       ylab = paste0("PC2 (", round(PCA$var_explained[2]*100, 1), "%)"),
       main = "By Time")
  legend("topright", legend = levels(as.factor(PCA$pca_df$Time_weeks)), 
         col = 1:length(unique(PCA$pca_df$Time_weeks)), pch = 19, cex = 0.6)
}

# Plot 4
if ("Bin_Number_New" %in% names(PCA$pca_df)) {
  bin_colors <- colorRampPalette(c("blue", "cyan", "yellow", "red"))(length(unique(PCA$pca_df$Bin_Number_New)))
  plot(PCA$pca_df$PC1, PCA$pca_df$PC2, 
       col = bin_colors[as.factor(PCA$pca_df$Bin_Number_New)],
       pch = 19, cex = 0.3,
       xlab = paste0("PC1 (", round(PCA$var_explained[1]*100, 1), "%)"),
       ylab = paste0("PC2 (", round(PCA$var_explained[2]*100, 1), "%)"),
       main = "By Bin Number")
  legend("topright", legend = sort(unique(PCA$pca_df$Bin_Number_New)), 
         col = bin_colors, pch = 19, cex = 0.5, ncol = 2)
}

#mtext("PCA Visualizations", outer = TRUE, line = 0.5, cex = 1.5, font = 2)
#dev.off()
cat("✓ Saved to PCA_Plots.pdf\n")

# ============================================
# GGPLOT VERSION (Better for publication) - FIXED
# ============================================

# First, reset any graphics issues
graphics.off()

# Check and load required packages
if (requireNamespace("ggplot2", quietly = TRUE) && 
    requireNamespace("patchwork", quietly = TRUE)) {
  
  library(ggplot2)
  library(patchwork)
  
  cat("\n=== CREATING GGPLOT VERSIONS ===\n")
  
  # Create a new list for ggplot objects to avoid any conflicts
  PCA$gg <- list()
  
  # Plot 1: Impact Region
  if ("Impact_Region" %in% names(PCA$pca_df)) {
    PCA$gg$impact <- ggplot(PCA$pca_df, aes(x = PC1, y = PC2, color = Impact_Region)) +
      geom_point(alpha = 0.3, size = 0.3) +
      scale_color_manual(values = c("Close" = "#E66F74", "Middle" = "gray50", "Far" = "#A4D38F")) +
      labs(x = paste0("PC1 (", round(PCA$var_explained[1]*100, 1), "%)"),
           y = paste0("PC2 (", round(PCA$var_explained[2]*100, 1), "%)"),
           title = "By Impact Region") +
      theme_bw() +
      theme(
        plot.title = element_text(size = 12, face = "bold", hjust = 0.5),
        legend.position = "bottom",
        legend.title = element_text(face = "bold"),
        panel.grid.minor = element_blank()
      )
  }
  
  # Plot 2: Animal
  if ("Animal_No" %in% names(PCA$pca_df)) {
    # Create a color palette for animals
    n_animals <- length(unique(PCA$pca_df$Animal_No))
    animal_colors <- colorRampPalette(c("#E66F74", "#A4D38F"))(n_animals)
    
    PCA$gg$animal <- ggplot(PCA$pca_df, aes(x = PC1, y = PC2, color = as.factor(Animal_No))) +
      geom_point(alpha = 0.3, size = 0.3) +
      scale_color_manual(values = animal_colors) +
      labs(x = paste0("PC1 (", round(PCA$var_explained[1]*100, 1), "%)"),
           y = paste0("PC2 (", round(PCA$var_explained[2]*100, 1), "%)"),
           title = "By Animal", 
           color = "Animal") +
      theme_bw() +
      theme(
        plot.title = element_text(size = 12, face = "bold", hjust = 0.5),
        legend.position = "bottom",
        legend.title = element_text(face = "bold"),
        panel.grid.minor = element_blank()
      )
  }
  
  # Plot 3: Time
  if ("Time_weeks" %in% names(PCA$pca_df)) {
    PCA$gg$time <- ggplot(PCA$pca_df, aes(x = PC1, y = PC2, color = as.factor(Time_weeks))) +
      geom_point(alpha = 0.3, size = 0.3) +
      scale_color_viridis_d() +
      labs(x = paste0("PC1 (", round(PCA$var_explained[1]*100, 1), "%)"),
           y = paste0("PC2 (", round(PCA$var_explained[2]*100, 1), "%)"),
           title = "By Time (weeks)", 
           color = "Weeks") +
      theme_bw() +
      theme(
        plot.title = element_text(size = 12, face = "bold", hjust = 0.5),
        legend.position = "bottom",
        legend.title = element_text(face = "bold"),
        panel.grid.minor = element_blank()
      )
  }
  
  # Plot 4: Bin Number
  if ("Bin_Number_New" %in% names(PCA$pca_df)) {
    PCA$gg$bin <- ggplot(PCA$pca_df, aes(x = PC1, y = PC2, color = Bin_Number_New)) +
      geom_point(alpha = 0.3, size = 0.3) +
      scale_color_gradientn(colors = c("blue", "cyan", "yellow", "red")) +
      labs(x = paste0("PC1 (", round(PCA$var_explained[1]*100, 1), "%)"),
           y = paste0("PC2 (", round(PCA$var_explained[2]*100, 1), "%)"),
           title = "By Bin Number",
           color = "Bin") +
      theme_bw() +
      theme(
        plot.title = element_text(size = 12, face = "bold", hjust = 0.5),
        legend.position = "bottom",
        legend.title = element_text(face = "bold"),
        panel.grid.minor = element_blank()
      )
  }
  
  # Combine plots only if all four exist
  if (length(PCA$gg) == 4) {
    PCA$gg_combined <- (PCA$gg$impact | PCA$gg$animal) / (PCA$gg$time | PCA$gg$bin) +
      plot_annotation(
        title = "PCA Visualizations",
        theme = theme(
          plot.title = element_text(size = 16, hjust = 0.5, face = "bold")
        )
      )
    
    # Display the combined plot
    print(PCA$gg_combined)
    
    # Save ggplot version
    ggsave("PCA_GGplot.pdf", PCA$gg_combined, width = 14, height = 10, limitsize = FALSE)
    ggsave("PCA_GGplot.png", PCA$gg_combined, width = 14, height = 10, dpi = 300, limitsize = FALSE)
    cat("✓ Saved ggplot versions to PCA_GGplot.pdf/png\n")
    
  } else {
    cat("⚠ Not all plots could be created. Available plots:", names(PCA$gg), "\n")
    
    # If not all four exist, create a different arrangement
    if (length(PCA$gg) > 0) {
      PCA$gg_combined <- wrap_plots(PCA$gg, ncol = 2) +
        plot_annotation(
          title = "PCA Visualizations",
          theme = theme(plot.title = element_text(size = 16, hjust = 0.5, face = "bold"))
        )
      print(PCA$gg_combined)
      ggsave("PCA_GGplot.pdf", PCA$gg_combined, width = 14, height = 10, limitsize = FALSE)
    }
  }
  
} else {
  cat("Please install ggplot2 and patchwork packages:\n")
  cat('install.packages(c("ggplot2", "patchwork"))\n')
}

# Alternative: Create individual plots and save them separately
cat("\n=== SAVING INDIVIDUAL PLOTS ===\n")

# Save individual plots
if (exists("PCA$gg")) {
  for (plot_name in names(PCA$gg)) {
    ggsave(
      filename = paste0("PCA_", plot_name, ".png"),
      plot = PCA$gg[[plot_name]],
      width = 6,
      height = 5,
      dpi = 300
    )
    cat("✓ Saved PCA_", plot_name, ".png\n", sep = "")
  }
}

# Reset graphics device
graphics.off()


# ============================================
# SUMMARY
# ============================================
cat("\n=== FINAL SUMMARY ===\n")
cat("Filter list contains:", paste(names(Filter), collapse = ", "), "\n")
cat("PCA list contains:", paste(names(PCA), collapse = ", "), "\n")
cat("\nTo access results:\n")
cat("  - Filtered data: Filter$df_clean_final\n")
cat("  - Scaled features: Filter$feat_scaled\n")
cat("  - PCA object: PCA$pca\n")
cat("  - PC scores: PCA$pca_scores\n")
cat("  - PCA dataframe with metadata: PCA$pca_df\n")

# Clean up temporary variables (optional - these are already inside lists)
# rm(winsorize)  # Not needed as it's inside Filter list

