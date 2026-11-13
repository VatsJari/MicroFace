# ============================================================================
# Filtering (extreme-outlier-only) + PCA Script
# ============================================================================
# Assumes `import$df_all_PCA` exists from the import script with:
#   - identifier columns at the front
#   - all remaining columns = morphology metrics (numeric)
# ============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(patchwork)
})

if (!exists("import") || is.null(import$df_all_PCA)) {
  stop("import$df_all_PCA not found. Please run the data import script first.")
}


# ============================================================================
# USER-TUNABLE FILTERING PARAMETERS
# ============================================================================
# Only truly extreme outliers are removed.
#
# chi_sq_quantile : theoretical chi-square quantile used as the Mahalanobis
#                   cutoff. 0.9999 means "top 0.01%" under chi-square.
# max_remove_pct  : hard cap on the fraction of cells that may be removed,
#                   regardless of the chi-square cutoff. Protects against
#                   heavy-tailed distributions. 0.005 = 0.5%.
# winsor_p        : winsorization tail (per side). Does NOT remove cells.
FILTER_PARAMS <- list(
  chi_sq_quantile = 0.9999,
  max_remove_pct  = 0.005,
  winsor_p        = 0.01
)


# ============================================================================
# FILTER LIST
# ============================================================================
Filter <- list()
Filter$params <- FILTER_PARAMS

# --- 1. Detect identifier columns ------------------------------------------
Filter$possible_id_cols <- c(
  "FileName_Original_Iba1_cell",
  "ImageNumber_cell",
  "Parent_Soma_Merged_cell",
  "Center_X_soma",
  "Center_Y_soma"
)
Filter$id_cols <- intersect(Filter$possible_id_cols,
                            colnames(import$df_all_PCA))
if (length(Filter$id_cols) == 0) {
  stop("No identifier columns found in df_all_PCA.")
}

# --- 2. Split meta / features ----------------------------------------------
Filter$meta_df <- import$df_all_PCA[, Filter$id_cols, drop = FALSE]
Filter$feat_df <- import$df_all_PCA %>%
  dplyr::select(-all_of(Filter$id_cols)) %>%
  dplyr::select(where(is.numeric))

cat("\n=== SPLIT ===\n")
cat("Identifier cols:", ncol(Filter$meta_df), "->",
    paste(Filter$id_cols, collapse = ", "), "\n")
cat("Feature cols:   ", ncol(Filter$feat_df), "\n")

# --- 3. Drop zero-variance / zero-IQR features -----------------------------
bad_var <- apply(Filter$feat_df, 2, var, na.rm = TRUE) == 0
bad_iqr <- apply(Filter$feat_df, 2, IQR, na.rm = TRUE) == 0
bad_cols <- names(which(bad_var | bad_iqr))

if (length(bad_cols) > 0) {
  message("Dropping ", length(bad_cols),
          " zero-variance / zero-IQR feature(s):")
  print(bad_cols)
  Filter$feat_df <- Filter$feat_df[
    , setdiff(colnames(Filter$feat_df), bad_cols), drop = FALSE]
}
if (ncol(Filter$feat_df) == 0) {
  stop("No usable numeric feature columns remain after variance filter.")
}

Filter$original_data <- list(
  meta    = Filter$meta_df,
  feat    = Filter$feat_df,
  n_cells = nrow(Filter$meta_df)
)

# --- 4. Winsorize (1% per tail) --------------------------------------------
Filter$winsorize <- function(x, p = Filter$params$winsor_p) {
  q <- quantile(x, c(p, 1 - p), na.rm = TRUE)
  x[x < q[1]] <- q[1]
  x[x > q[2]] <- q[2]
  x
}

Filter$feat_wins <- Filter$feat_df %>%
  mutate(across(everything(), ~Filter$winsorize(.x)))

if (anyNA(Filter$feat_wins)) {
  warning("NA values found in feat_wins. Removing those rows.")
  Filter$complete_rows <- complete.cases(Filter$feat_wins)
  Filter$feat_wins <- Filter$feat_wins[Filter$complete_rows, ]
  Filter$meta_df   <- Filter$meta_df[Filter$complete_rows, ]
}

# --- 5. Mahalanobis distances ----------------------------------------------
Filter$md <- mahalanobis(
  Filter$feat_wins,
  colMeans(Filter$feat_wins),
  cov(Filter$feat_wins)
)

# --- 6. EXTREME-ONLY cutoff ------------------------------------------------
# (a) theoretical chi-square cutoff at the chosen quantile
Filter$cutoff_chisq <- qchisq(Filter$params$chi_sq_quantile,
                              df = ncol(Filter$feat_wins))

# (b) empirical cutoff so we never remove more than max_remove_pct
Filter$cutoff_empirical <- quantile(Filter$md,
                                    1 - Filter$params$max_remove_pct,
                                    na.rm = TRUE)

# (c) effective cutoff = the stricter (smaller) of the two
Filter$cutoff <- min(Filter$cutoff_chisq, Filter$cutoff_empirical)
Filter$keep_idx <- Filter$md < Filter$cutoff

# Report which cap bound
Filter$cutoff_source <-
  if (Filter$cutoff == Filter$cutoff_chisq) "chi-square" else "max_remove_pct cap"

cat("\n=== EXTREME-OUTLIER CUTOFF ===\n")
cat("Chi-square cutoff (q =", Filter$params$chi_sq_quantile, "):",
    round(Filter$cutoff_chisq, 2), "\n")
cat("Empirical cap cutoff (max remove =",
    Filter$params$max_remove_pct * 100, "%):",
    round(Filter$cutoff_empirical, 2), "\n")
cat("Effective cutoff:", round(Filter$cutoff, 2),
    " (bound by:", Filter$cutoff_source, ")\n")

# --- 7. Keep non-outliers --------------------------------------------------
Filter$meta_clean <- Filter$meta_df[Filter$keep_idx, , drop = FALSE]
Filter$feat_clean <- Filter$feat_wins[Filter$keep_idx, ]

Filter$df_clean_final <- cbind(Filter$meta_clean, Filter$feat_clean)

# Robust scaling for PCA
Filter$feat_scaled <- scale(
  Filter$feat_clean,
  center = apply(Filter$feat_clean, 2, median),
  scale  = apply(Filter$feat_clean, 2, IQR)
)


# ============================================================================
# QC PLOTS
# ============================================================================
cat("\n=== GENERATING QC PLOTS ===\n")

# 1. Cell-count bar ---------------------------------------------------------
Filter$cell_count_df <- data.frame(
  Stage      = c("Original", "After Filtering"),
  Cell_Count = c(Filter$original_data$n_cells, nrow(Filter$meta_clean)),
  Percentage = c(100, round(100 * nrow(Filter$meta_clean) /
                              Filter$original_data$n_cells, 2))
)

Filter$plot_cell_count <- ggplot(Filter$cell_count_df,
                                 aes(x = Stage, y = Cell_Count, fill = Stage)) +
  geom_bar(stat = "identity", width = 0.5) +
  geom_text(aes(label = paste0(Cell_Count, "\n(", Percentage, "%)")),
            vjust = 2, size = 3, fontface = "bold") +
  theme_classic() +
  labs(x = "", y = "Number of Cells") +
  theme(
    plot.title = element_text(size = 10, hjust = 0.5, face = "bold"),
    axis.title.y = element_text(size = 8, face = "bold"),
    axis.text.x  = element_text(size = 8, face = "bold"),
    axis.text.y  = element_text(size = 8),
    legend.position = "none"
  )
print(Filter$plot_cell_count)

# 2. Mahalanobis distribution ----------------------------------------------
Filter$md_df <- data.frame(
  Mahalanobis_Distance = Filter$md,
  Status = ifelse(Filter$keep_idx, "Kept", "Removed")
)

Filter$plot_mahalanobis <- ggplot(Filter$md_df,
                                  aes(x = Mahalanobis_Distance, fill = Status)) +
  geom_histogram(bins = 100, alpha = 0.7, position = "identity", width = 1) +
  geom_vline(xintercept = Filter$cutoff, color = "red",
             linetype = "dashed", size = 1) +
  annotate("text",
           x = Filter$cutoff * 1.1,
           y = max(hist(Filter$md, plot = FALSE)$counts) * 0.9,
           label = paste0("Cutoff = ", round(Filter$cutoff, 1),
                          "\n(", Filter$cutoff_source, ")"),
           color = "red", size = 2.5, fontface = "bold") +
  theme_classic() +
  labs(title = "Mahalanobis Distance — Extreme-Outlier Cutoff",
       x = "Mahalanobis Distance", y = "Frequency") +
  theme(
    plot.title = element_text(size = 10, hjust = 0.5, face = "bold"),
    axis.title = element_text(size = 8, face = "bold"),
    legend.position = "right"
  )
print(Filter$plot_mahalanobis)

# 3. PCA before vs after ----------------------------------------------------
Filter$pca_original <- prcomp(Filter$feat_df, center = TRUE, scale. = TRUE)
Filter$pca_original_df <- data.frame(
  PC1  = Filter$pca_original$x[, 1],
  PC2  = Filter$pca_original$x[, 2],
  Type = "Original"
)

Filter$pca_filtered <- prcomp(Filter$feat_clean, center = TRUE, scale. = TRUE)
Filter$pca_filtered_df <- data.frame(
  PC1  = Filter$pca_filtered$x[, 1],
  PC2  = Filter$pca_filtered$x[, 2],
  Type = "Filtered"
)

Filter$pca_combined <- rbind(Filter$pca_original_df, Filter$pca_filtered_df)

Filter$plot_pca_comparison <- ggplot(Filter$pca_combined,
                                     aes(x = PC1, y = PC2, color = Type)) +
  geom_point(alpha = 0.3, size = 0.5) +
  scale_color_manual(values = c("Original" = "red", "Filtered" = "green")) +
  facet_wrap(~Type, ncol = 2) +
  theme_classic() +
  labs(title = "PCA Comparison: Original vs Extreme-Filtered",
       x = "PC1", y = "PC2") +
  theme(
    plot.title = element_text(size = 14, hjust = 0.5, face = "bold"),
    axis.title = element_text(size = 12, face = "bold"),
    legend.position = "none",
    strip.text = element_text(size = 12, face = "bold")
  )
print(Filter$plot_pca_comparison)

# 4. Feature distributions (top 6 most variable) ---------------------------
Filter$feature_variance <- apply(Filter$feat_df, 2, var, na.rm = TRUE)
Filter$top_features <- names(sort(Filter$feature_variance,
                                  decreasing = TRUE))[1:min(6, ncol(Filter$feat_df))]

Filter$feature_dist_original <- Filter$feat_df %>%
  dplyr::select(all_of(Filter$top_features)) %>%
  tidyr::pivot_longer(everything(), names_to = "Feature", values_to = "Value") %>%
  mutate(Stage = "Original")

Filter$feature_dist_filtered <- Filter$feat_clean %>%
  dplyr::select(all_of(Filter$top_features)) %>%
  tidyr::pivot_longer(everything(), names_to = "Feature", values_to = "Value") %>%
  mutate(Stage = "Filtered")

Filter$feature_dist <- rbind(Filter$feature_dist_original,
                             Filter$feature_dist_filtered)

Filter$feature_dist$Feature_Clean <- gsub("_", " ", Filter$feature_dist$Feature)
Filter$feature_dist$Feature_Clean <- gsub("cell", "(Cell)", Filter$feature_dist$Feature_Clean)
Filter$feature_dist$Feature_Clean <- gsub("soma", "(Soma)", Filter$feature_dist$Feature_Clean)

Filter$plot_feature_dist <- ggplot(Filter$feature_dist,
                                   aes(x = Value, fill = Stage)) +
  geom_density(alpha = 0.5) +
  facet_wrap(~Feature_Clean, scales = "free", ncol = 3) +
  theme_classic() +
  labs(title = "Top 6 Most Variable Features: Original vs Extreme-Filtered",
       x = "Value", y = "Density") +
  theme(
    plot.title = element_text(size = 14, hjust = 0.5, face = "bold"),
    axis.title = element_text(size = 12, face = "bold"),
    axis.text.x = element_text(angle = 45, hjust = 1, size = 8),
    strip.text  = element_text(size = 10, face = "bold"),
    legend.position = "bottom"
  )
print(Filter$plot_feature_dist)

# 5. Summary table ----------------------------------------------------------
Filter$summary_table <- data.frame(
  Metric = c("Total Cells", "Cells Kept", "Cells Removed", "Removal Rate",
             "Features Used", "Winsorization Tail",
             "Chi-square Cutoff", "Effective Cutoff",
             "Cutoff Bound By"),
  Value = c(
    Filter$original_data$n_cells,
    nrow(Filter$meta_clean),
    sum(!Filter$keep_idx),
    paste0(round(100 * sum(!Filter$keep_idx) /
                   Filter$original_data$n_cells, 3), "%"),
    ncol(Filter$feat_clean),
    paste0(Filter$params$winsor_p * 100, "% (per tail)"),
    round(Filter$cutoff_chisq, 2),
    round(Filter$cutoff, 2),
    Filter$cutoff_source
  )
)
Filter$plot_summary <- gridExtra::tableGrob(Filter$summary_table, rows = NULL)
grid::grid.draw(Filter$plot_summary)

# 6. Combined QC figure -----------------------------------------------------
Filter$qc_figure <- (Filter$plot_cell_count | Filter$plot_mahalanobis) /
  (Filter$plot_pca_comparison) /
  (Filter$plot_feature_dist) +
  plot_annotation(
    title    = "Quality Control: Extreme-Outlier Filtering",
    subtitle = paste0("Removed ", sum(!Filter$keep_idx),
                      " extreme outlier(s) (",
                      round(100 * sum(!Filter$keep_idx) /
                              Filter$original_data$n_cells, 3),
                      "% of total)"),
    theme = theme(
      plot.title    = element_text(size = 16, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray30")
    )
  )
print(Filter$qc_figure)


# ============================================================================
# DIAGNOSTICS
# ============================================================================
cat("\n=== FILTERING DIAGNOSTICS ===\n")
cat("Original rows:  ", Filter$original_data$n_cells, "\n")
cat("Clean rows:     ", nrow(Filter$df_clean_final), "\n")
cat("Cells removed:  ", sum(!Filter$keep_idx), "\n")
cat("Percentage kept:", round(100 * nrow(Filter$df_clean_final) /
                                Filter$original_data$n_cells, 3), "%\n")
cat("Effective cutoff:", round(Filter$cutoff, 2),
    "(bound by", Filter$cutoff_source, ")\n")


# ============================================================================
# PCA LIST
# ============================================================================
PCA <- list()

# Drop any residual zero-variance columns after filtering
bad_var2 <- apply(Filter$feat_scaled, 2, var, na.rm = TRUE) == 0
if (any(bad_var2)) {
  message("Dropping ", sum(bad_var2),
          " zero-variance column(s) after filtering before PCA.")
  Filter$feat_scaled <- Filter$feat_scaled[, !bad_var2, drop = FALSE]
}
finite_ok <- apply(Filter$feat_scaled, 2, function(x) all(is.finite(x)))
if (any(!finite_ok)) {
  message("Dropping non-finite columns before PCA: ",
          paste(names(finite_ok)[!finite_ok], collapse = ", "))
  Filter$feat_scaled <- Filter$feat_scaled[, finite_ok, drop = FALSE]
}

PCA$pca           <- prcomp(Filter$feat_scaled, center = TRUE, scale. = FALSE)
PCA$var_explained <- PCA$pca$sdev^2 / sum(PCA$pca$sdev^2)

graphics::plot(PCA$var_explained[1:min(20, length(PCA$var_explained))],
               type = "b",
               xlab = "Principal Component",
               ylab = "Proportion of Variance Explained",
               main = "Scree Plot (First 20 PCs)")
graphics::abline(h = 0.05, col = "red", lty = 2)

cat("\n=== PCA DIAGNOSTICS ===\n")
cat("Features used in PCA:", ncol(Filter$feat_scaled), "\n")
print(round(cumsum(PCA$var_explained)[1:min(20, length(PCA$var_explained))], 4))

PCA$n_pcs_97 <- which(cumsum(PCA$var_explained) >= 0.97)[1]
cat("\nNumber of PCs explaining 97% variance:", PCA$n_pcs_97, "\n")

n_pcs_out <- min(10, ncol(PCA$pca$x))
PCA$pca_scores <- data.frame(PCA$pca$x[, 1:n_pcs_out])
colnames(PCA$pca_scores) <- paste0("PC", 1:n_pcs_out)

PCA$pca_df <- cbind(Filter$meta_clean, PCA$pca_scores)


# ============================================================================
# PCA VISUALIZATION — base R + ggplot
# ============================================================================
par(mfrow = c(1, 2), mar = c(4, 4, 3, 1))

plot(PCA$pca_df$PC1, PCA$pca_df$PC2,
     pch = 19, cex = 0.3, col = rgb(0, 0, 0, 0.35),
     xlab = paste0("PC1 (", round(PCA$var_explained[1] * 100, 1), "%)"),
     ylab = paste0("PC2 (", round(PCA$var_explained[2] * 100, 1), "%)"),
     main = "PCA — all cells")

if ("ImageNumber_cell" %in% names(PCA$pca_df)) {
  img_factor <- as.factor(PCA$pca_df$ImageNumber_cell)
  img_cols   <- rainbow(length(levels(img_factor)), alpha = 0.5)
  plot(PCA$pca_df$PC1, PCA$pca_df$PC2,
       pch = 19, cex = 0.3, col = img_cols[img_factor],
       xlab = paste0("PC1 (", round(PCA$var_explained[1] * 100, 1), "%)"),
       ylab = paste0("PC2 (", round(PCA$var_explained[2] * 100, 1), "%)"),
       main = "PCA — by ImageNumber")
}
par(mfrow = c(1, 1))

PCA$gg <- list()
PCA$gg$overall <- ggplot(PCA$pca_df, aes(x = PC1, y = PC2)) +
  geom_point(alpha = 0.3, size = 0.3, color = "black") +
  labs(x = paste0("PC1 (", round(PCA$var_explained[1] * 100, 1), "%)"),
       y = paste0("PC2 (", round(PCA$var_explained[2] * 100, 1), "%)"),
       title = "PCA — all cells") +
  theme_bw() +
  theme(plot.title = element_text(size = 12, face = "bold", hjust = 0.5),
        panel.grid.minor = element_blank())
print(PCA$gg$overall)

if ("ImageNumber_cell" %in% names(PCA$pca_df)) {
  PCA$gg$image <- ggplot(PCA$pca_df,
                         aes(x = PC1, y = PC2,
                             color = as.factor(ImageNumber_cell))) +
    geom_point(alpha = 0.3, size = 0.3) +
    labs(x = paste0("PC1 (", round(PCA$var_explained[1] * 100, 1), "%)"),
         y = paste0("PC2 (", round(PCA$var_explained[2] * 100, 1), "%)"),
         title = "PCA — by ImageNumber", color = "Image") +
    theme_bw() +
    theme(plot.title = element_text(size = 12, face = "bold", hjust = 0.5),
          legend.position = "bottom",
          legend.title    = element_text(face = "bold"),
          panel.grid.minor = element_blank())
  print(PCA$gg$image)
}

PCA$gg_combined <- patchwork::wrap_plots(PCA$gg, ncol = 2) +
  plot_annotation(
    title = "PCA Visualizations",
    theme = theme(plot.title = element_text(size = 16, hjust = 0.5,
                                            face = "bold"))
  )
print(PCA$gg_combined)


# ============================================================================
# FINAL SUMMARY
# ============================================================================
cat("\n=== FINAL SUMMARY ===\n")
cat("Filter list:", paste(names(Filter), collapse = ", "), "\n")
cat("PCA list:   ", paste(names(PCA),    collapse = ", "), "\n")

# ============================================================================
# End of script
# ============================================================================