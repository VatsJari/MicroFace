# ============================================================================
# Morphology Enrichment Heatmap per Cluster — A4 layout, no bold
# ============================================================================
# Requires: ClusterAnalysis$final_df_full (from the cluster analysis script)
# Produces: MorphHeatmap$*  (stats, heatmap, dotplot, violin panel, A4 figure)
# ============================================================================

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(ggplot2)
  library(tibble); library(patchwork); library(scales)
})

if (!exists("ClusterAnalysis") || is.null(ClusterAnalysis$final_df_full)) {
  stop("ClusterAnalysis$final_df_full not found. ",
       "Run the cluster analysis script first.")
}

MorphHeatmap <- list()

# ============================================================================
# USER-TUNABLE PARAMETERS
# ============================================================================
HEATMAP_PARAMS <- list(
  top_n_features        = 25,     # heatmap row cap (keep ≤ ~25 for A4)
  top_n_violin          = 8,      # features shown in the violin panel
  violin_ncol           = 4,      # 4 cols × 2 rows for 8 features
  min_cells_per_cluster = 5,
  use_kruskal_filter    = TRUE,
  kruskal_alpha         = 0.05,
  order_clusters        = TRUE,
  order_features        = TRUE,
  sig_test              = TRUE,
  padj_method           = "BH",
  z_cap                 = 2.5,
  max_na_frac           = 0.20,
  a4_width              = 8.27,   # inches (A4 portrait)
  a4_height             = 11.69
)
MorphHeatmap$params <- HEATMAP_PARAMS

# ============================================================================
# UNIFORM THEME — no bold, A4-friendly sizes
# ============================================================================
theme_morph <- function(base_size = 9) {
  theme_bw(base_size = base_size) +
    theme(
      plot.title       = element_text(size = base_size + 2, hjust = 0.5,
                                      margin = margin(b = 3)),
      plot.subtitle    = element_text(size = base_size - 1, hjust = 0.5,
                                      colour = "gray30",
                                      margin = margin(b = 6)),
      axis.title       = element_text(size = base_size),
      axis.text        = element_text(size = base_size - 1),
      axis.text.x      = element_text(margin = margin(t = 2)),
      axis.text.y      = element_text(margin = margin(r = 2)),
      legend.title     = element_text(size = base_size - 1),
      legend.text      = element_text(size = base_size - 2),
      legend.key.size  = unit(0.9, "lines"),
      strip.text       = element_text(size = base_size - 1),
      strip.background = element_rect(fill = "grey92", colour = NA),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(colour = "grey92", linewidth = 0.25),
      plot.margin      = margin(6, 8, 6, 6)
    )
}
MorphHeatmap$theme <- theme_morph

# ============================================================================
# 1. DATA + FEATURE DETECTION
# ============================================================================
cat("\n=== MORPH ENRICHMENT HEATMAP ===\n")

df <- ClusterAnalysis$final_df_full
df$Cluster <- droplevels(factor(df$Cluster))
if (nlevels(df$Cluster) < 2) stop("Need ≥2 clusters.")

non_feature_regex <- c(
  "^Cell_ID$", "^Cluster$", "^UMAP[0-9]*$", "^PC[0-9]+$",
  "^FileName_Original_Iba1_cell$", "^ImageNumber_cell$",
  "^Parent_Soma_Merged_cell$", "^Center_X_soma$", "^Center_Y_soma$"
)
is_non_feature <- Reduce(`|`, lapply(non_feature_regex, grepl, x = names(df)))

candidate_feats <- names(df)[!is_non_feature]
candidate_feats <- candidate_feats[vapply(df[candidate_feats],
                                          is.numeric, logical(1))]
candidate_feats <- candidate_feats[
  vapply(candidate_feats, function(f) {
    v <- df[[f]]
    if (all(is.na(v))) return(FALSE)
    s <- sd(v, na.rm = TRUE)
    if (is.na(s) || s == 0) return(FALSE)
    mean(is.na(v)) <= HEATMAP_PARAMS$max_na_frac
  }, logical(1))
]
if (length(candidate_feats) == 0) stop("No usable morphology features.")

MorphHeatmap$features_used <- candidate_feats
MorphHeatmap$cluster_sizes <- df %>% count(Cluster, name = "n_cells")

cat("Clusters:", nlevels(df$Cluster), " | cells:", nrow(df), "\n")
cat("Candidate features:", length(candidate_feats), "\n")

# short display labels (originals kept in tables)
feature_display <- function(x, width = 28) {
  y <- gsub("_", " ", x)
  ifelse(nchar(y) > width, paste0(substr(y, 1, width - 1), "\u2026"), y)
}
MorphHeatmap$display_labels <- setNames(feature_display(candidate_feats),
                                        candidate_feats)

# ============================================================================
# 2. LONG FORMAT + PER-CLUSTER STATISTICS
# ============================================================================
long_df <- df %>%
  dplyr::select(Cluster, all_of(candidate_feats)) %>%
  tidyr::pivot_longer(-Cluster, names_to = "Feature", values_to = "Value")

global_stats <- long_df %>%
  group_by(Feature) %>%
  summarise(g_mean   = mean(Value,   na.rm = TRUE),
            g_sd     = sd(Value,     na.rm = TRUE),
            g_median = median(Value, na.rm = TRUE),
            .groups  = "drop")

cluster_stats <- long_df %>%
  group_by(Feature, Cluster) %>%
  summarise(n_cells = sum(!is.na(Value)),
            mean    = mean(Value,   na.rm = TRUE),
            median  = median(Value, na.rm = TRUE),
            sd      = sd(Value,     na.rm = TRUE),
            .groups = "drop") %>%
  left_join(global_stats, by = "Feature") %>%
  group_by(Feature) %>%
  mutate(z      = as.numeric(scale(mean)),
         log2FC = ifelse(mean > 0 & g_mean > 0,
                         log2(mean / g_mean), NA_real_)) %>%
  ungroup() %>%
  mutate(z = ifelse(is.na(z) | is.nan(z), 0, z))

# ============================================================================
# 3. FEATURE-LEVEL KRUSKAL-WALLIS
# ============================================================================
MorphHeatmap$feature_tests <- data.frame(
  Feature = candidate_feats,
  KW_p = vapply(candidate_feats, function(f) {
    v <- df[[f]]; g <- df$Cluster
    ok <- is.finite(v)
    if (length(unique(g[ok])) < 2) return(NA_real_)
    tryCatch(kruskal.test(v[ok], g[ok])$p.value,
             error = function(e) NA_real_)
  }, numeric(1)),
  stringsAsFactors = FALSE
)
MorphHeatmap$feature_tests$KW_padj <-
  p.adjust(MorphHeatmap$feature_tests$KW_p, method = HEATMAP_PARAMS$padj_method)

feat_keep <- MorphHeatmap$feature_tests$Feature
if (HEATMAP_PARAMS$use_kruskal_filter) {
  sig_feats <- MorphHeatmap$feature_tests %>%
    filter(!is.na(KW_padj), KW_padj <= HEATMAP_PARAMS$kruskal_alpha) %>%
    pull(Feature)
  if (length(sig_feats) >= 3) {
    feat_keep <- sig_feats
    cat("Kruskal filter kept:", length(feat_keep), "\n")
  } else {
    message("Too few features after Kruskal filter — keeping all.")
  }
}

# ============================================================================
# 4. ONE-VS-REST WILCOXON
# ============================================================================
MorphHeatmap$sig <- NULL
if (HEATMAP_PARAMS$sig_test) {
  cat("\n=== ONE-VS-REST WILCOXON ===\n")
  clust_levels <- levels(df$Cluster)
  sig_list <- vector("list", length(feat_keep) * length(clust_levels))
  k <- 0L
  for (f in feat_keep) {
    v <- df[[f]]; g <- df$Cluster
    for (cl in clust_levels) {
      k <- k + 1L
      in_vals  <- v[g == cl];  in_vals  <- in_vals[is.finite(in_vals)]
      out_vals <- v[g != cl];  out_vals <- out_vals[is.finite(out_vals)]
      if (length(in_vals)  < HEATMAP_PARAMS$min_cells_per_cluster ||
          length(out_vals) < HEATMAP_PARAMS$min_cells_per_cluster) {
        sig_list[[k]] <- data.frame(Feature = f, Cluster = cl,
                                    p_val = NA_real_, diff = NA_real_,
                                    stringsAsFactors = FALSE)
        next
      }
      wt <- tryCatch(
        suppressWarnings(wilcox.test(in_vals, out_vals, exact = FALSE)),
        error = function(e) NULL)
      sig_list[[k]] <- data.frame(
        Feature = f, Cluster = cl,
        p_val = if (is.null(wt)) NA_real_ else wt$p.value,
        diff  = median(in_vals) - median(out_vals),
        stringsAsFactors = FALSE)
    }
  }
  MorphHeatmap$sig <- bind_rows(sig_list) %>%
    group_by(Feature) %>%
    mutate(padj = p.adjust(p_val, method = HEATMAP_PARAMS$padj_method)) %>%
    ungroup() %>%
    mutate(
      star = cut(padj, breaks = c(-Inf, 1e-4, 1e-3, 1e-2, 0.05, Inf),
                 labels = c("****", "***", "**", "*", "")),
      star = as.character(star),
      star = ifelse(is.na(star), "", star))
  cat("Sig feature × cluster (padj<0.05):",
      sum(MorphHeatmap$sig$padj < 0.05, na.rm = TRUE), "/",
      nrow(MorphHeatmap$sig), "\n")
}

# ============================================================================
# 5. SELECT FEATURES FOR HEATMAP
# ============================================================================
z_mat_all <- cluster_stats %>%
  filter(Feature %in% feat_keep) %>%
  mutate(Cluster = as.character(Cluster)) %>%
  dplyr::select(Feature, Cluster, z) %>%
  tidyr::pivot_wider(names_from = Cluster, values_from = z) %>%
  tibble::column_to_rownames("Feature") %>%
  as.matrix()
z_mat_all[is.na(z_mat_all)] <- 0

feat_score <- apply(abs(z_mat_all), 1, max, na.rm = TRUE)

if (!is.null(HEATMAP_PARAMS$top_n_features) &&
    nrow(z_mat_all) > HEATMAP_PARAMS$top_n_features) {
  top_feats <- names(sort(feat_score, decreasing = TRUE))[
    1:HEATMAP_PARAMS$top_n_features]
} else {
  top_feats <- rownames(z_mat_all)
}
z_mat <- z_mat_all[top_feats, , drop = FALSE]
cat("Features in heatmap:", nrow(z_mat), "\n")

# ============================================================================
# 6. HIERARCHICAL ORDERING
# ============================================================================
if (HEATMAP_PARAMS$order_clusters && ncol(z_mat) > 2) {
  clust_order <- colnames(z_mat)[hclust(dist(t(z_mat)))$order]
} else {
  clust_order <- colnames(z_mat)
}
if (HEATMAP_PARAMS$order_features && nrow(z_mat) > 2) {
  feat_order <- rownames(z_mat)[hclust(dist(z_mat))$order]
} else {
  feat_order <- rownames(z_mat)
}

# ============================================================================
# 7. HEATMAP LONG TABLE
# ============================================================================
heatmap_long <- z_mat %>%
  as.data.frame() %>%
  tibble::rownames_to_column("Feature") %>%
  tidyr::pivot_longer(-Feature, names_to = "Cluster", values_to = "z")

if (!is.null(MorphHeatmap$sig)) {
  heatmap_long <- heatmap_long %>%
    left_join(MorphHeatmap$sig %>%
                dplyr::select(Feature, Cluster, padj, star),
              by = c("Feature", "Cluster"))
} else {
  heatmap_long$padj <- NA_real_
  heatmap_long$star <- ""
}

heatmap_long$Feature_label <- factor(
  MorphHeatmap$display_labels[heatmap_long$Feature],
  levels = rev(MorphHeatmap$display_labels[feat_order]))

heatmap_long <- heatmap_long %>%
  left_join(MorphHeatmap$cluster_sizes %>%
              mutate(Cluster = as.character(Cluster)),
            by = "Cluster") %>%
  mutate(Cluster = factor(Cluster, levels = clust_order))

z_lim <- min(HEATMAP_PARAMS$z_cap, max(abs(heatmap_long$z), na.rm = TRUE))

clust_labels <- setNames(
  paste0("C", clust_order, "\n(n=",
         MorphHeatmap$cluster_sizes$n_cells[
           match(clust_order,
                 as.character(MorphHeatmap$cluster_sizes$Cluster))],
         ")"),
  clust_order)

# ============================================================================
# 8. HEATMAP
# ============================================================================
MorphHeatmap$plot_heatmap <-
  ggplot(heatmap_long, aes(x = Cluster, y = Feature_label, fill = z)) +
  geom_tile(colour = "white", linewidth = 0.3) +
  geom_text(aes(label = star,
                colour = ifelse(abs(z) > z_lim * 0.55, "white", "black")),
            size = 2.4, vjust = 0.75, show.legend = FALSE) +
  scale_colour_identity() +
  scale_fill_gradient2(
    low = "#2166AC", mid = "white", high = "#B2182B", midpoint = 0,
    limits = c(-z_lim, z_lim), oob = scales::squish,
    name = "Enrichment\n(z-score)") +
  scale_x_discrete(labels = clust_labels, expand = c(0, 0)) +
  scale_y_discrete(expand = c(0, 0)) +
  labs(
    title = paste0("Morphology enrichment by cluster (k = ",
                   ClusterAnalysis$optimal_k, ")"),
    subtitle = paste0("Row z-score of cluster mean; * padj < 0.05 | ",
                      nrow(z_mat), " features | ", nrow(df), " cells"),
    x = "Cluster", y = NULL) +
  theme_morph(base_size = 9) +
  theme(
    axis.text.y     = element_text(size = 7),
    axis.text.x     = element_text(size = 8),
    panel.grid      = element_blank(),
    legend.position = "right")

print(MorphHeatmap$plot_heatmap)

# ============================================================================
# 9. DOTPLOT
# ============================================================================
MorphHeatmap$dot_df <- long_df %>%
  filter(Feature %in% top_feats) %>%
  left_join(global_stats %>% dplyr::select(Feature, g_median),
            by = "Feature") %>%
  group_by(Feature, Cluster) %>%
  summarise(frac_high = mean(Value > g_median, na.rm = TRUE),
            .groups = "drop") %>%
  left_join(cluster_stats %>% dplyr::select(Feature, Cluster, z),
            by = c("Feature", "Cluster")) %>%
  mutate(z = ifelse(is.na(z), 0, z))

MorphHeatmap$dot_df$Feature_label <- factor(
  MorphHeatmap$display_labels[MorphHeatmap$dot_df$Feature],
  levels = rev(MorphHeatmap$display_labels[feat_order]))
MorphHeatmap$dot_df$Cluster <- factor(MorphHeatmap$dot_df$Cluster,
                                      levels = clust_order)

MorphHeatmap$plot_dotplot <-
  ggplot(MorphHeatmap$dot_df,
         aes(x = Cluster, y = Feature_label,
             size = frac_high, colour = z)) +
  geom_point() +
  scale_colour_gradient2(
    low = "#2166AC", mid = "white", high = "#B2182B", midpoint = 0,
    limits = c(-z_lim, z_lim), oob = scales::squish, name = "z") +
  scale_size_continuous(range = c(0, 4.5), limits = c(0, 1),
                        name = "Frac >\nmedian") +
  scale_x_discrete(labels = clust_labels) +
  labs(
    title = "Morphology enrichment — dot plot",
    subtitle = "Size = fraction of cells above global median; colour = row z-score",
    x = "Cluster", y = NULL) +
  theme_morph(base_size = 9) +
  theme(
    axis.text.y     = element_text(size = 7),
    axis.text.x     = element_text(size = 8),
    legend.position = "right",
    legend.box      = "vertical")

print(MorphHeatmap$plot_dotplot)

# ============================================================================
# 10. VIOLIN PANEL
# ============================================================================
top_plot_feats <- names(sort(feat_score, decreasing = TRUE))[
  1:min(HEATMAP_PARAMS$top_n_violin, length(feat_score))]

viol_df <- df %>%
  dplyr::select(Cluster, all_of(top_plot_feats)) %>%
  tidyr::pivot_longer(-Cluster, names_to = "Feature", values_to = "Value") %>%
  mutate(Feature_label = factor(
    MorphHeatmap$display_labels[Feature],
    levels = MorphHeatmap$display_labels[top_plot_feats]))

clust_fill <- if (!is.null(ClusterAnalysis$morpho_colours)) {
  ClusterAnalysis$morpho_colours[levels(df$Cluster)]
} else {
  setNames(scales::hue_pal()(nlevels(df$Cluster)), levels(df$Cluster))
}

MorphHeatmap$plot_violins <-
  ggplot(viol_df, aes(x = Cluster, y = Value, fill = Cluster)) +
  geom_violin(scale = "width", trim = TRUE, alpha = 0.7,
              linewidth = 0.2, colour = "gray40") +
  geom_boxplot(width = 0.14, outlier.size = 0.15,
               fill = "white", linewidth = 0.2) +
  scale_fill_manual(values = clust_fill) +
  facet_wrap(~ Feature_label, scales = "free_y",
             ncol = HEATMAP_PARAMS$violin_ncol) +
  labs(title = "Top morphology features per cluster",
       x = "Cluster", y = "Value") +
  theme_morph(base_size = 8) +
  theme(
    strip.text       = element_text(size = 7),
    strip.background = element_rect(fill = "grey92", colour = NA),
    legend.position  = "none",
    panel.spacing    = unit(0.4, "lines"))

print(MorphHeatmap$plot_violins)

# ============================================================================
# 11. COMBINED A4 FIGURE (heights scale with feature count)
# ============================================================================
n_rows <- nrow(z_mat)

heat_h <- dplyr::case_when(
  n_rows <= 10 ~ 3.0,
  n_rows <= 20 ~ 3.8,
  n_rows <= 25 ~ 4.2,
  n_rows <= 30 ~ 4.6,
  TRUE         ~ 5.2)
dot_h <- dplyr::case_when(
  n_rows <= 10 ~ 2.2,
  n_rows <= 20 ~ 2.7,
  n_rows <= 25 ~ 3.0,
  n_rows <= 30 ~ 3.4,
  TRUE         ~ 3.8)
viol_h <- dplyr::case_when(
  HEATMAP_PARAMS$top_n_violin <= 4 ~ 2.0,
  HEATMAP_PARAMS$top_n_violin <= 8 ~ 3.0,
  TRUE                             ~ 3.8)

MorphHeatmap$figure <-
  (MorphHeatmap$plot_heatmap /
     MorphHeatmap$plot_dotplot /
     MorphHeatmap$plot_violins) +
  patchwork::plot_layout(heights = c(heat_h, dot_h, viol_h)) +
  patchwork::plot_annotation(
    title = "Morphology enrichment per cluster",
    theme = theme(
      plot.title = element_text(size = 12, hjust = 0.5,
                                margin = margin(b = 6))))

print(MorphHeatmap$figure)

# ============================================================================
# 12. SUMMARY TABLES
# ============================================================================
MorphHeatmap$enrichment_table <- cluster_stats %>%
  filter(Feature %in% feat_order) %>%
  left_join(
    if (!is.null(MorphHeatmap$sig))
      MorphHeatmap$sig %>% dplyr::select(Feature, Cluster, p_val, padj, star)
    else tibble(Feature = character(), Cluster = character(),
                p_val = numeric(), padj = numeric(), star = character()),
    by = c("Feature", "Cluster")) %>%
  mutate(Cluster       = factor(Cluster, levels = clust_order),
         Feature_label = MorphHeatmap$display_labels[Feature]) %>%
  arrange(Feature, Cluster) %>%
  dplyr::select(Feature, Feature_label, Cluster, n_cells,
                mean, median, sd, g_mean, z, log2FC, p_val, padj, star)

MorphHeatmap$top_features_per_cluster <- MorphHeatmap$enrichment_table %>%
  group_by(Cluster) %>%
  arrange(desc(z), .by_group = TRUE) %>%
  slice_head(n = 10) %>%
  ungroup()

cat("\n=== TOP ENRICHED FEATURES PER CLUSTER ===\n")
print(as.data.frame(
  MorphHeatmap$top_features_per_cluster %>%
    dplyr::select(Cluster, Feature, mean, z, log2FC, star) %>%
    filter(z > 0)))

# ============================================================================
# 13. A4 EXPORTS
# ============================================================================
ggsave("MorphEnrichment_A4.png", MorphHeatmap$figure,
       width  = HEATMAP_PARAMS$a4_width,
       height = HEATMAP_PARAMS$a4_height,
       units  = "in", dpi = 300, limitsize = FALSE)

ggsave("MorphEnrichment_A4.pdf", MorphHeatmap$figure,
       width  = HEATMAP_PARAMS$a4_width,
       height = HEATMAP_PARAMS$a4_height,
       units  = "in", limitsize = FALSE)

# Individual plots at A4-compatible sizes
ggsave("MorphEnrichment_Heatmap_A4.png", MorphHeatmap$plot_heatmap,
       width = 8.27, height = 8.0, units = "in", dpi = 300,
       limitsize = FALSE)
ggsave("MorphEnrichment_DotPlot_A4.png", MorphHeatmap$plot_dotplot,
       width = 8.27, height = 8.0, units = "in", dpi = 300,
       limitsize = FALSE)
ggsave("MorphEnrichment_Violins_A4.png", MorphHeatmap$plot_violins,
       width = 8.27, height = 6.0, units = "in", dpi = 300,
       limitsize = FALSE)

write.csv(MorphHeatmap$enrichment_table,
          "MorphEnrichment_perCluster.csv", row.names = FALSE)
write.csv(MorphHeatmap$feature_tests,
          "MorphEnrichment_featureKW.csv", row.names = FALSE)

cat("\n=== DONE ===\n")