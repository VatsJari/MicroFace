# ------------------------------------------------------
# 1. PREPARE MORPHOTYPE FREQUENCY MATRIX
# ------------------------------------------------------

# Select relevant columns
Morpho_git$df_Morpho_count <- Morpho_git$df_clust_all[, c(51, 58)]

# Filter bins (only bins <= 16)
Morpho_git$df_Morpho_count <- Morpho_git$df_Morpho_count[which(Morpho_git$df_Morpho_count$Bin_Number_New <= 16), ]

# Exclude problematic combination
Morpho_git$df_Morpho_count <- Morpho_git$df_Morpho_count[!(
  Morpho_git$df_Morpho_count$Bin_Number_New <= 1 & Morpho_git$df_Morpho_count$Morpho == "M13"
), ]

# Count occurrences of Morpho types per bin
Morpho_git$df_Morpho_count.t <- table(Morpho_git$df_Morpho_count)

# Scale the table
Morpho_git$df_Morpho_count_scale.t <- scale(Morpho_git$df_Morpho_count.t)

# ------------------------------------------------------
# 2. DEFINE BREAKS FOR HEATMAP COLOR SCALE
# ------------------------------------------------------

Morpho_git$quantile_breaks <- function(xs, n) {
  breaks <- quantile(xs, probs = seq(0, 1, length.out = n))
  breaks[!duplicated(breaks)]
}

Morpho_git$mat_breaks <- Morpho_git$quantile_breaks(Morpho_git$df_Morpho_count_scale.t, n = 32)

# ------------------------------------------------------
# 3. BASIC HEATMAP
# ------------------------------------------------------

pheatmap(
  Morpho_git$df_Morpho_count_scale.t,
  color  = rev(inferno(length(Morpho_git$mat_breaks) - 1)),
  breaks = Morpho_git$mat_breaks,
  cutree_cols = 4,
  cutree_rows = 5,
  fontsize = 14,
  Rowv = NA,
  main = "Morpho-type Frequency Heatmap"
)

# ------------------------------------------------------
# 4. DENDROGRAM CLUSTERING
# ------------------------------------------------------

# Generate unsorted dendrogram
Morpho_git$morpho_hm_col <- hclust(dist(t(Morpho_git$df_Morpho_count_scale.t)))
plot(Morpho_git$morpho_hm_col, main = "Unsorted Dendrogram", xlab = "", sub = "")

# Sorting helper
Morpho_git$sort_hclust <- function(...) as.hclust(dendsort(as.dendrogram(...)))

# Apply sorting to columns and rows
Morpho_git$morpho_hm_col <- Morpho_git$sort_hclust(Morpho_git$morpho_hm_col)
Morpho_git$morpho_hm_row <- Morpho_git$sort_hclust(hclust(dist(Morpho_git$df_Morpho_count_scale.t)))

# Plot sorted dendrogram
plot(Morpho_git$morpho_hm_col, main = "Sorted Dendrogram", xlab = "", sub = "")


# ------------------------------------------------------
# 5. FINAL HEATMAP: INFERNO COLOR
# ------------------------------------------------------

pheatmap(
  Morpho_git$df_Morpho_count_scale.t,
  color = inferno(length(Morpho_git$mat_breaks) - 1),
  breaks = Morpho_git$mat_breaks,
  cutree_cols = 1,
  cutree_rows = 3,
  cluster_cols = Morpho_git$morpho_hm_col,
  cluster_rows = FALSE,
  fontsize_row = 12,
  fontsize_col = 12,
  angle_col = 45,
  fontsize = 1,
  Rowv = FALSE
)
