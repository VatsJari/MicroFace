# ============================================================================
# Cluster Analysis Script (no sampling, default k = 6, manual override)
# ============================================================================
# Uses the FULL filtered dataset from previous scripts.
# Pipeline:
#   1. Elbow method → WSS curve + labelled k values (plot)
#   2. Pick k: default = 6, or user override after inspecting the elbow plot
#   3. Final k-means
#   4. UMAP
#   5. Final dataframe + summary
#   6. Optional cluster removal
#   7. Faceted XY plots by ImageNumber
# ============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(RColorBrewer)
  library(ggrepel)
  library(uwot)
  library(patchwork)
})

# ============================================================================
# SANITY CHECKS
# ============================================================================
if (!exists("Filter") || is.null(Filter$meta_clean) ||
    is.null(Filter$feat_clean)) {
  stop("Filter$meta_clean / Filter$feat_clean not found. ",
       "Run the filtering + PCA script first.")
}
if (!exists("PCA") || is.null(PCA$pca)) {
  stop("PCA$pca not found. Run the filtering + PCA script first.")
}
if (is.null(PCA$n_pcs_97) || is.na(PCA$n_pcs_97)) {
  PCA$n_pcs_97 <- which(cumsum(PCA$var_explained) >= 0.97)[1]
  if (is.na(PCA$n_pcs_97)) PCA$n_pcs_97 <- ncol(PCA$pca$x)
  cat("PCA$n_pcs_97 recomputed:", PCA$n_pcs_97, "\n")
}

# ============================================================================
# PRESERVE USER OVERRIDE ACROSS RERUNS
# ============================================================================
# Because rerunning the script recreates `ClusterAnalysis`, we lift any
# override the user set previously out into the working environment first,
# then restore it below. This way, after inspecting the elbow plot, the
# user can do:
#     ClusterAnalysis$optimal_k_override <- 8
# and simply rerun the rest of the script from Step 3.
.user_override_prev <- if (exists("ClusterAnalysis") &&
                           !is.null(ClusterAnalysis$optimal_k_override)) {
  ClusterAnalysis$optimal_k_override
} else NULL

ClusterAnalysis <- list()
if (!is.null(.user_override_prev)) {
  ClusterAnalysis$optimal_k_override <- .user_override_prev
}

set.seed(123)

# --- 1. Whole dataset ------------------------------------------------------
ClusterAnalysis$meta_all       <- Filter$meta_clean
ClusterAnalysis$feat_all       <- Filter$feat_clean
ClusterAnalysis$pca_scores_all <- PCA$pca$x[, 1:PCA$n_pcs_97, drop = FALSE]

cat("\n=== INPUT ===\n")
cat("Total cells:", nrow(ClusterAnalysis$meta_all), "\n")
cat("PCs used:   ", ncol(ClusterAnalysis$pca_scores_all), "\n")


# ============================================================================
# 2. ELBOW METHOD — WSS CURVE + LABELLED k VALUES
# ============================================================================
cat("\n=== ELBOW METHOD ===\n")

if (is.null(ClusterAnalysis$k_range)) {
  max_k <- min(15, floor(nrow(ClusterAnalysis$pca_scores_all) / 2))
  ClusterAnalysis$k_range <- 2:max_k
}

# --- 2a. WSS for every k ---------------------------------------------------
ClusterAnalysis$wss <- numeric(length(ClusterAnalysis$k_range))
for (i in seq_along(ClusterAnalysis$k_range)) {
  k <- ClusterAnalysis$k_range[i]
  set.seed(123)
  km <- kmeans(ClusterAnalysis$pca_scores_all,
               centers = k, nstart = 10, iter.max = 100)
  ClusterAnalysis$wss[i] <- km$tot.withinss
  cat("k =", k, " | WSS =", round(km$tot.withinss, 1), "\n")
}

# --- 2b. Reference knee (Kneedle) — informational only --------------------
x  <- ClusterAnalysis$k_range
y  <- ClusterAnalysis$wss
xN <- (x - min(x)) / (max(x) - min(x))
yN <- (y - min(y)) / (max(y) - min(y))
dist_to_chord <- xN + yN - 1
ClusterAnalysis$knee_idx       <- which.max(dist_to_chord)
ClusterAnalysis$optimal_k_knee <- x[ClusterAnalysis$knee_idx]
cat("Reference knee at k =", ClusterAnalysis$optimal_k_knee,
    "(informational only)\n")

# --- 2c. Default vs. override ---------------------------------------------
ClusterAnalysis$default_k <- 6

if (!is.null(ClusterAnalysis$optimal_k_override)) {
  ClusterAnalysis$optimal_k        <- ClusterAnalysis$optimal_k_override
  ClusterAnalysis$optimal_k_source <- "user override"
} else {
  ClusterAnalysis$optimal_k        <- ClusterAnalysis$default_k
  ClusterAnalysis$optimal_k_source <- "default (6)"
}

cat("\nSelected k =", ClusterAnalysis$optimal_k,
    " [", ClusterAnalysis$optimal_k_source, "]\n")

# --- 2d. Elbow plot: every k labelled, chosen k highlighted ---------------
# Each k is marked with:
#   - a point on the curve
#   - its k value printed above/next to the point
#   - the selected k drawn larger + a dashed vline
# The Kneedle knee is shown as a light-red reference vline (optional).
ClusterAnalysis$elbow_df <- data.frame(
  k       = x,
  WSS     = y,
  IsKnee  = seq_along(x) == ClusterAnalysis$knee_idx,
  IsChosen = x == ClusterAnalysis$optimal_k
)

ClusterAnalysis$plot_elbow <-
  ggplot(ClusterAnalysis$elbow_df, aes(x = k, y = WSS)) +
  # WSS curve
  geom_line(color = "steelblue", linewidth = 0.9) +
  # All k points (same size), so every k is visible
  geom_point(color = "steelblue", size = 2.5) +
  # Chosen k highlighted
  geom_point(data = subset(ClusterAnalysis$elbow_df, IsChosen),
             color = "darkgreen", size = 4.5, shape = 21,
             fill = "lightgreen", stroke = 1.2) +
  # Knee reference vline (informational)
  geom_vline(xintercept = ClusterAnalysis$optimal_k_knee,
             linetype = "dotted", color = "red", alpha = 0.6) +
  # Chosen k vline (solid)
  geom_vline(xintercept = ClusterAnalysis$optimal_k,
             linetype = "dashed", color = "darkgreen", alpha = 0.8) +
  # Label every k value above its point
  geom_text(aes(label = k),
            vjust = -1.2, size = 3.2, fontface = "bold") +
  # Annotations
  annotate("text",
           x = ClusterAnalysis$optimal_k,
           y = max(y) * 0.97,
           label = paste0("Chosen k = ", ClusterAnalysis$optimal_k,
                          "\n(", ClusterAnalysis$optimal_k_source, ")"),
           color = "darkgreen", fontface = "bold", hjust = -0.05, size = 3.2) +
  annotate("text",
           x = ClusterAnalysis$optimal_k_knee,
           y = max(y) * 0.85,
           label = paste0("Knee ref = ", ClusterAnalysis$optimal_k_knee),
           color = "red", fontface = "italic", hjust = -0.05, size = 3) +
  scale_x_continuous(breaks = x) +
  labs(title = "Elbow Method — pick k from the plot",
       subtitle = paste0("Default k = 6. Set ClusterAnalysis$optimal_k_override ",
                         "and rerun to change."),
       x = "Number of clusters (k)",
       y = "Total within-cluster SS") +
  theme_bw(base_size = 11) +
  theme(
    plot.title       = element_text(size = 12, face = "bold", hjust = 0.5),
    plot.subtitle    = element_text(size = 9, hjust = 0.5, color = "gray30"),
    panel.grid.minor = element_blank()
  )

print(ClusterAnalysis$plot_elbow)

cat("\n--------------------------------------------------------------\n")
cat("If you want a different k, run:\n")
cat("  ClusterAnalysis$optimal_k_override <- <your_k>\n")
cat("then rerun the script from Step 2d/3 onward.\n")
cat("Current k =", ClusterAnalysis$optimal_k, "\n")
cat("--------------------------------------------------------------\n")


# ============================================================================
# 3. FINAL K-MEANS ON ALL CELLS
# ============================================================================
cat("\n=== FINAL K-MEANS (full dataset) ===\n")
cat("Using k =", ClusterAnalysis$optimal_k,
    "(", ClusterAnalysis$optimal_k_source, ")\n")

set.seed(123)
ClusterAnalysis$final_kmeans <- kmeans(
  ClusterAnalysis$pca_scores_all,
  centers  = ClusterAnalysis$optimal_k,
  nstart   = 50,
  iter.max = 100
)

ClusterAnalysis$meta_all$Cluster <-
  factor(ClusterAnalysis$final_kmeans$cluster)

ClusterAnalysis$centroids <- ClusterAnalysis$final_kmeans$centers


# ============================================================================
# 4. UMAP ON ALL CELLS
# ============================================================================
cat("\n=== UMAP (full dataset) ===\n")

set.seed(42)
ClusterAnalysis$umap_all <- umap(
  ClusterAnalysis$pca_scores_all,
  min_dist = 0.7
)

ClusterAnalysis$meta_all$UMAP1 <- ClusterAnalysis$umap_all[, 1]
ClusterAnalysis$meta_all$UMAP2 <- ClusterAnalysis$umap_all[, 2]


# ============================================================================
# 5. UMAP VISUALIZATION
# ============================================================================
cat("\n=== CREATING UMAP PLOT ===\n")

ClusterAnalysis$morpho_colours <-
  colorRampPalette(brewer.pal(12, "Paired"))(ClusterAnalysis$optimal_k)
names(ClusterAnalysis$morpho_colours) <-
  levels(factor(ClusterAnalysis$meta_all$Cluster))

centroids_umap <- ClusterAnalysis$meta_all %>%
  group_by(Cluster) %>%
  summarise(UMAP1 = mean(UMAP1, na.rm = TRUE),
            UMAP2 = mean(UMAP2, na.rm = TRUE),
            .groups = "drop") %>%
  mutate(Cluster = factor(Cluster,
                          levels = levels(factor(ClusterAnalysis$meta_all$Cluster))))

centroids_umap$text_color <-
  ClusterAnalysis$morpho_colours[as.numeric(centroids_umap$Cluster)]

ClusterAnalysis$umap_cluster <-
  ggplot(ClusterAnalysis$meta_all,
         aes(x = UMAP1, y = UMAP2, color = Cluster)) +
  geom_point(size = 0.1, alpha = 0.7, shape = ".") +
  scale_color_manual(values = ClusterAnalysis$morpho_colours) +
  theme_classic() +
  labs(title = paste0("UMAP by Cluster (k = ", ClusterAnalysis$optimal_k,
                      ", n = ", nrow(ClusterAnalysis$meta_all), ")"),
       x = "UMAP1", y = "UMAP2") +
  theme(legend.position = "none") +
  ggrepel::geom_label_repel(
    data = centroids_umap,
    aes(x = UMAP1, y = UMAP2, label = Cluster),
    fill = "white", color = centroids_umap$text_color,
    fontface = "bold", size = 4,
    box.padding = 0.5, point.padding = 0.2,
    show.legend = FALSE
  )

print(ClusterAnalysis$umap_cluster)


# ============================================================================
# 6. FINAL DATAFRAME
# ============================================================================

ClusterAnalysis$final_df_full <- data.frame(
  Cell_ID = rownames(ClusterAnalysis$meta_all),
  UMAP1   = ClusterAnalysis$meta_all$UMAP1,
  UMAP2   = ClusterAnalysis$meta_all$UMAP2,
  PC1     = ClusterAnalysis$pca_scores_all[, 1],
  PC2     = ClusterAnalysis$pca_scores_all[, 2],
  PC3     = ClusterAnalysis$pca_scores_all[, 3],
  ClusterAnalysis$meta_all,
  ClusterAnalysis$feat_all
)


# ============================================================================
# 7. SUMMARY STATISTICS
# ============================================================================
ClusterAnalysis$summary <- list(
  total_cells      = nrow(ClusterAnalysis$meta_all),
  k_range          = ClusterAnalysis$k_range,
  default_k        = ClusterAnalysis$default_k,
  optimal_k        = ClusterAnalysis$optimal_k,
  optimal_k_source = ClusterAnalysis$optimal_k_source,
  optimal_k_knee   = ClusterAnalysis$optimal_k_knee,
  n_clusters       = length(unique(ClusterAnalysis$meta_all$Cluster)),
  umap_params      = list(n_neighbors = "default", min_dist = 0.7)
)

cat("\n=== ANALYSIS COMPLETE ===\n")
cat("Total cells:", ClusterAnalysis$summary$total_cells, "\n")
cat("Clusters (k):", ClusterAnalysis$optimal_k,
    " [", ClusterAnalysis$optimal_k_source, "]\n")


# ============================================================================
# 8. OPTIONAL: REMOVE FALSE-POSITIVE CLUSTERS
# ============================================================================
# Inspect the UMAP and set:
#   ClusterAnalysis$remove_cluster_override <- c(<id1>, <id2>)
ClusterAnalysis$remove_cluster <-
  if (!is.null(ClusterAnalysis$remove_cluster_override)) {
    ClusterAnalysis$remove_cluster_override
  } else {
    integer(0)
  }

cat("\nClusters flagged for removal:",
    if (length(ClusterAnalysis$remove_cluster) == 0) "none"
    else paste(ClusterAnalysis$remove_cluster, collapse = ", "), "\n")

if (length(ClusterAnalysis$remove_cluster) > 0) {
  ClusterAnalysis$final_df_full <-
    ClusterAnalysis$final_df_full %>%
    filter(!Cluster %in% ClusterAnalysis$remove_cluster)
  ClusterAnalysis$meta_all <-
    ClusterAnalysis$meta_all %>%
    filter(!Cluster %in% ClusterAnalysis$remove_cluster)
}

cat("Final cells after removal:", nrow(ClusterAnalysis$final_df_full), "\n")


# ============================================================================
# 9. FACETED SPATIAL PLOTS BY IMAGENUMBER
# ============================================================================
cat("\n=== FACETED SPATIAL PLOTS BY IMAGE ===\n")

needed <- c("Center_X_soma", "Center_Y_soma", "ImageNumber_cell", "Cluster")
if (!all(needed %in% colnames(ClusterAnalysis$final_df_full))) {
  cat("Skipping faceted plots — missing columns:",
      paste(setdiff(needed, colnames(ClusterAnalysis$final_df_full)),
            collapse = ", "), "\n")
} else {
  
  present_clusters <- levels(droplevels(ClusterAnalysis$final_df_full$Cluster))
  palette_for_plot <- ClusterAnalysis$morpho_colours
  if (!all(present_clusters %in% names(palette_for_plot))) {
    palette_for_plot <-
      setNames(
        colorRampPalette(brewer.pal(12, "Paired"))(length(present_clusters)),
        present_clusters
      )
  }
  
  # --- 9a. One facet per image -------------------------------------------
  ClusterAnalysis$plot_xy_by_image <-
    ggplot(ClusterAnalysis$final_df_full,
           aes(x = Center_X_soma, y = Center_Y_soma, color = Cluster)) +
    geom_point(size = 0.4, alpha = 0.7) +
    scale_color_manual(values = palette_for_plot) +
    facet_wrap(~ ImageNumber_cell, scales = "free", ncol = 4) +
    labs(title = paste0("Cluster distribution by image (k = ",
                        ClusterAnalysis$optimal_k, ")"),
         x = "Center X (soma)", y = "Center Y (soma)") +
    theme_bw(base_size = 8) +
    theme(
      plot.title       = element_text(size = 12, face = "bold", hjust = 0.5),
      strip.text       = element_text(size = 7, face = "bold"),
      strip.background = element_rect(fill = "grey92", color = NA),
      legend.position  = "right",
      panel.grid.minor = element_blank()
    )
  
  print(ClusterAnalysis$plot_xy_by_image)
  
  # --- 9b. Per-image cluster composition heatmap -------------------------
  ClusterAnalysis$cluster_composition_by_image <-
    ClusterAnalysis$final_df_full %>%
    count(ImageNumber_cell, Cluster) %>%
    complete(ImageNumber_cell, Cluster, fill = list(n = 0)) %>%
    group_by(ImageNumber_cell) %>%
    mutate(prop = n / sum(n)) %>%
    ungroup()
  
  ClusterAnalysis$plot_cluster_composition_heatmap <-
    ggplot(ClusterAnalysis$cluster_composition_by_image,
           aes(x = Cluster, y = factor(ImageNumber_cell), fill = prop)) +
    geom_tile(color = "white", linewidth = 0.2) +
    scale_fill_gradientn(colors = c("white", "#FFD6A5", "#F4A261", "#E76F51"),
                         limits = c(0, 1), name = "Proportion") +
    labs(title = "Cluster composition per image",
         x = "Cluster", y = "ImageNumber") +
    theme_minimal(base_size = 8) +
    theme(
      plot.title  = element_text(size = 11, face = "bold", hjust = 0.5),
      axis.text.y = element_text(size = 6),
      panel.grid  = element_blank()
    )
  
  print(ClusterAnalysis$plot_cluster_composition_heatmap)
}

# ============================================================================
# 9c. UMAP OVERLAYS — key morphology features
# ============================================================================
cat("\n=== UMAP FEATURE OVERLAYS ===\n")

# The features we want to colour the UMAP (and later, the spatial plots) by.
# Branch_Ends is your "Endpoints" count from the skeleton analysis.
overlay_feats <- c("RI", "Trunk_Branch", "Branch_Ends", "Area_soma")
overlay_feats <- intersect(overlay_feats, colnames(ClusterAnalysis$final_df_full))

if (length(overlay_feats) == 0) {
  cat("None of RI / Trunk_Branch / Branch_Ends found in final_df_full — skipping.\n")
} else {
  cat("Overlaying:", paste(overlay_feats, collapse = ", "), "\n")
  
  ClusterAnalysis$umap_overlays <- list()
  
  for (feat in overlay_feats) {
    p <- ggplot(ClusterAnalysis$final_df_full,
                aes(x = UMAP1, y = UMAP2, color = .data[[feat]])) +
      geom_point(size = 0.2, alpha = 0.7, shape = ".") +
      scale_color_viridis_c(option = "plasma", name = feat) +
      theme_classic() +
      labs(title = paste0("UMAP — ", feat),
           x = "UMAP1", y = "UMAP2") +
      theme(
        plot.title    = element_text(size = 12, face = "bold", hjust = 0.5),
        legend.position = "right"
      )
    ClusterAnalysis$umap_overlays[[feat]] <- p
    print(p)
  }
  
  # Combined panel (2 columns so 3 features = 2 + 1)
  ClusterAnalysis$umap_feature_panel <-
    patchwork::wrap_plots(ClusterAnalysis$umap_overlays, ncol = 2) +
    patchwork::plot_annotation(
      title = "UMAP overlays — key morphology features",
      theme = theme(plot.title = element_text(size = 14, face = "bold",
                                              hjust = 0.5))
    )
  print(ClusterAnalysis$umap_feature_panel)
}


# ============================================================================
# 9d. SPATIAL PLOTS BY IMAGE — coloured by morphology features
# ============================================================================
cat("\n=== SPATIAL FEATURE OVERLAYS BY IMAGE ===\n")

if (length(overlay_feats) == 0) {
  cat("No features to overlay — skipping.\n")
} else if (!all(c("Center_X_soma", "Center_Y_soma", "ImageNumber_cell") %in%
                colnames(ClusterAnalysis$final_df_full))) {
  cat("Skipping spatial feature overlays — missing coordinate columns.\n")
} else {
  
  ClusterAnalysis$spatial_overlays <- list()
  
  for (feat in overlay_feats) {
    p <- ggplot(ClusterAnalysis$final_df_full,
                aes(x = Center_X_soma, y = Center_Y_soma, color = .data[[feat]])) +
      geom_point(size = 0.4, alpha = 0.7) +
      scale_color_viridis_c(option = "plasma", name = feat) +
      facet_wrap(~ ImageNumber_cell, scales = "free", ncol = 4) +
      labs(title = paste0("Spatial — ", feat, " by image (k = ",
                          ClusterAnalysis$optimal_k, ")"),
           x = "Center X (soma)", y = "Center Y (soma)") +
      theme_bw(base_size = 8) +
      theme(
        plot.title       = element_text(size = 12, face = "bold", hjust = 0.5),
        strip.text       = element_text(size = 7, face = "bold"),
        strip.background = element_rect(fill = "grey92", color = NA),
        legend.position  = "right",
        panel.grid.minor = element_blank()
      )
    ClusterAnalysis$spatial_overlays[[feat]] <- p
    print(p)
  }
}


# ============================================================================
# 10. OPTIONAL SAVES
# ============================================================================
# ggsave("Elbow.png",
#        ClusterAnalysis$plot_elbow,
#        width = 8, height = 5, dpi = 300)
# ggsave("UMAP_Clusters.png",
#        ClusterAnalysis$umap_cluster,
#        width = 10, height = 8, dpi = 300)
# ggsave("XY_by_image.pdf",
#        ClusterAnalysis$plot_xy_by_image,
#        width = 18, height = 14, limitsize = FALSE)
# write.csv(ClusterAnalysis$final_df_full,
#           "final_results_full.csv", row.names = FALSE)

cat("\n=== CLUSTER ANALYSIS COMPLETE ===\n")
cat("Key objects in ClusterAnalysis:\n")
cat("  Elbow:        plot_elbow, wss, optimal_k, optimal_k_knee\n")
cat("  Clustering:   final_kmeans, centroids, meta_all\n")
cat("  UMAP:         umap_all, umap_cluster\n")
cat("  Spatial:      plot_xy_by_image, plot_cluster_composition_heatmap\n")
cat("  Table:        final_df_full\n")
cat("  Summary:      summary\n")