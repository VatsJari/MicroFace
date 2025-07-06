# ===================================================
# PCA & UMAP ANALYSIS PIPELINE (SECOND ITERATION)
# ===================================================

# Initialize analysis container
PCA_git <- list()
set.seed(123)  # For reproducibility



# -------------------------------
# 1. DATA PREPARATION
# -------------------------------
# Select relevant columns (morphological features + metadata)
PCA_git$df_pca <- import$df_all_reordered[, c(35:82, 5, 6, 26, 29:32)]

# Filter to include only cells within 16 bins from injury center
PCA_git$df_pca <- PCA_git$df_pca[which(PCA_git$df_pca$Bin_Number_New <= 16), ]

# Subsample to 40% of data for computational efficiency
PCA_git$df_pca <- PCA_git$df_pca[sample(nrow(PCA_git$df_pca), nrow(PCA_git$df_pca) * 0.4), ]

# -------------------------------
# 2. PRINCIPAL COMPONENT ANALYSIS
# -------------------------------
# Perform PCA on morphological features (columns 1-48)
PCA_git$pca_result <- prcomp(PCA_git$df_pca[, c(1:45, 47,48)], scale = TRUE)

# Visualize explained variance by principal components
fviz_eig(PCA_git$pca_result, 
         addlabels = TRUE, 
         xlab = "Principal Components", 
         ylim = c(0, 50)) +
  theme_bw() + 
  theme(
    plot.title = element_text(size = 24, hjust = 0.5, face = "bold"),
    axis.title = element_text(size = 22, face = "bold"),
    axis.text = element_text(size = 17, face = "bold"),
    legend.text = element_text(size = 16, face = "bold"),
    legend.title = element_text(size = 18, face = "bold"),
    legend.key.size = unit(1.5, "lines"),
    legend.position = "bottom",
    strip.text = element_text(size = 18, face = "bold")
  )

# -------------------------------
# 3. K-MEANS CLUSTERING
# -------------------------------
# Cluster morphological features into 4 groups (biologically meaningful)
PCA_git$kmeans_result <- kmeans(PCA_git$df_pca[, c(1:45, 47,48)], 
                             centers = 4, 
                             nstart = 25)  # Multiple starts for stability

# Add cluster assignments to dataframe
PCA_git$df_pca$Cluster <- as.factor(PCA_git$kmeans_result$cluster)

# -------------------------------
# 4. TIDYMODELS PCA PIPELINE
# -------------------------------
# Create recipe for standardized PCA workflow
PCA_git$pca_rec <- recipe(~., data = PCA_git$df_pca) %>%
  # Specify metadata columns that shouldn't be used as predictors
  update_role( Time_weeks, Bin_Number_New,  Center_X_cell, Center_Y_cell, 
               Cluster, Condition_cell, ImageNumber_cell, Electrode_Thickness, Branch_Ratio, new_role = "id") %>%
  step_normalize(all_predictors()) %>%
  step_pca(all_predictors())

# Fit the recipe to the data
PCA_git$pca_prep <- prep(PCA_git$pca_rec)

PCA_git$pca_prep
# Extract PCA loadings (variable contributions)
PCA_git$tidied_pca <- tidy(PCA_git$pca_prep, 2)  # 2 refers to PCA step

# -------------------------------
# 5. PCA VISUALIZATION
# -------------------------------
# Plot top contributing features to PC1 and PC2
PCA_git$tidied_pca %>%
  filter(component %in% paste0("PC", 1:2)) %>%
  group_by(component) %>%
  top_n(15, abs(value)) %>%  # Top 15 features per PC
  ungroup() %>%
  mutate(terms = reorder_within(terms, abs(value), component)) %>%
  ggplot(aes(abs(value), terms, fill = value > 0)) +
  geom_col() +
  facet_wrap(~component, scales = "free_y") +
  scale_y_reordered() +
  labs(
    x = "Absolute value of contribution",
    y = NULL, 
    fill = "Positive Contribution?"
  ) +
  theme_minimal()

# Plot PCA scores colored by cluster
juice(PCA_git$pca_prep) %>%
  ggplot(aes(PC1, PC2)) +
  geom_point(aes(color = Cluster), 
             alpha = 0.7, 
             size = 2, 
             shape = 19) +  # Solid circles for better visibility
  scale_color_viridis_d() +  # Color-blind friendly palette
  xlim(c(-10, 40)) +        # Consistent axis limits
  labs(
    title = "Major Morpho-Families of Microglia",
    color = "Cluster"
  ) +
  theme_classic() +
  theme(
    plot.title = element_text(size = 12, hjust = 0.5, face = "bold"),
    axis.title = element_text(size = 12, face = "bold"),
    axis.text = element_text(size = 10, face = "bold"),
    legend.text = element_text(size = 10, face = "bold"),
    legend.title = element_text(size = 12, face = "bold"),
    legend.key.size = unit(1.5, "lines"),
    legend.position = "bottom"
  )

# -------------------------------
# 6. UMAP VISUALIZATION
# -------------------------------
# Create UMAP recipe for dimensionality reduction
PCA_git$umap_rec <- recipe(~., data = PCA_git$df_pca) %>%
  update_role(Time_weeks, Bin_Number_New, Center_X_cell, Center_Y_cell,
              Cluster, Condition_cell, ImageNumber_cell, Electrode_Thickness, Branch_Ratio,
              new_role = "id") %>%
  step_normalize(all_predictors()) %>%
  step_umap(all_predictors())

# Prepare UMAP transformation
PCA_git$umap_prep <- prep(PCA_git$umap_rec)

# Plot UMAP results
juice(PCA_git$umap_prep) %>%
  ggplot(aes(UMAP1, UMAP2)) +
  geom_point(aes(color = Cluster), 
             alpha = 1, 
             size = 0.1) +  # Smaller points for dense visualization
  scale_color_viridis_d() +
  labs(color = "Cluster") +
  theme_void() +            # Clean background for UMAP visualization
  theme(legend.position = "right")



# ===================================================
# RECLUSTERING ANALYSIS OF PRIMARY CLUSTERS
# ===================================================


# -------------------------------
# 1. CLUSTER 1 RECLUSTERING (4 SUBTYPES) ---> in manuscript Cluster-2
# -------------------------------

# Subset Cluster 1 cells
PCA_git$Clust1 <- subset(PCA_git$df_pca[, c(1:45, 47:56)], Cluster == 1)

# PCA to determine optimal subclusters
PCA_git$pca_clust1 <- prcomp(PCA_git$Clust1[, 1:47], scale = TRUE)
fviz_eig(PCA_git$pca_clust1, 
         main = "Variance Explained - Cluster 1 Subtypes",
         addlabels = TRUE)

# K-means clustering into 3 subtypes
PCA_git$kmeans_clust1 <- kmeans(PCA_git$Clust1[, 1:48], 
                                centers = 4, 
                                nstart = 25)
PCA_git$Clust1$Subcluster <- as.factor(PCA_git$kmeans_clust1$cluster)

# PCA visualization pipeline
PCA_git$pca_rec1 <- recipe(~., data = PCA_git$Clust1) %>%
  update_role(Subcluster, Time_weeks, Bin_Number_New, Center_X_cell, 
              Center_Y_cell, Cluster, Condition_cell, 
              ImageNumber_cell, Electrode_Thickness, 
              new_role = "id") %>%
  step_normalize(all_predictors()) %>%
  step_pca(all_predictors())

PCA_git$pca_prep1 <- prep(PCA_git$pca_rec1)

# Plot top contributing features
PCA_git$tidied_pca1 <- tidy(PCA_git$pca_prep1, 2) %>%
  filter(component %in% paste0("PC", 1:4)) %>%
  group_by(component) %>%
  top_n(15, abs(value)) %>%
  ungroup() %>%
  mutate(terms = reorder_within(terms, abs(value), component))

ggplot(PCA_git$tidied_pca1, aes(abs(value), terms, fill = value > 0)) +
  geom_col() +
  facet_wrap(~component, scales = "free_y") +
  scale_y_reordered() +
  labs(title = "Key Features - Cluster 1 Subtypes",
       x = "Absolute Contribution", y = NULL)

# Visualize subclusters in PCA space
juice(PCA_git$pca_prep1) %>%
  ggplot(aes(PC1, PC2)) +
  geom_point(aes(color = Subcluster), alpha = 0.7, size = 2) +
  scale_color_manual(values = c("#FF0000", "#00FF00" ,"#0000FF", "#FFFF00"))+
  ggtitle("Cluster 1 Subtypes") +
  theme_classic()

# UMAP visualization
umap_rec1 <- recipe(~., data = PCA_git$Clust1) %>%
  update_role(Subcluster, Time_weeks, Bin_Number_New, 
              Center_X_cell, Center_Y_cell, Cluster, 
              Condition_cell, ImageNumber_cell, 
              Electrode_Thickness, new_role = "id") %>%
  step_normalize(all_predictors()) %>%
  step_umap(all_predictors())

umap_prep1 <- prep(umap_rec1)
juice(umap_prep1) %>%
  ggplot(aes(UMAP1, UMAP2)) +
  geom_point(aes(color = Subcluster), alpha = 0.8, size = 1) +
  scale_color_manual(values = c("#FF0000", "#00FF00" ,"#0000FF", "#FFFF00"))+
  theme_void()

# -------------------------------
# 2. CLUSTER 2 RECLUSTERING (3 SUBTYPES). ---> manuscript Cluster 1
# -------------------------------

# Subset Cluster 2 cells
PCA_git$Clust2 <- subset(PCA_git$df_pca[, c(1:45, 47:56)], Cluster == 2)

# PCA to determine optimal subclusters
PCA_git$pca_clust2 <- prcomp(PCA_git$Clust2[, 1:47], scale = TRUE)
fviz_eig(PCA_git$pca_clust2, 
         main = "Variance Explained - Cluster 2 Subtypes",
         addlabels = TRUE)

# K-means clustering into 4 subtypes
PCA_git$kmeans_clust2 <- kmeans(PCA_git$Clust2[, 1:48], 
                                centers = 3, 
                                nstart = 25)
PCA_git$Clust2$Subcluster <- as.factor(PCA_git$kmeans_clust2$cluster)

# PCA visualization pipeline
PCA_git$pca_rec2 <- recipe(~., data = PCA_git$Clust2) %>%
  update_role(Subcluster, Time_weeks, Bin_Number_New, 
              Center_X_cell, Center_Y_cell, Cluster, 
              Condition_cell, ImageNumber_cell, 
              Electrode_Thickness, new_role = "id") %>%
  step_normalize(all_predictors()) %>%
  step_pca(all_predictors())

PCA_git$pca_prep2 <- prep(PCA_git$pca_rec2)

# Plot top contributing features
PCA_git$tidied_pca2 <- tidy(PCA_git$pca_prep2, 2) %>%
  filter(component %in% paste0("PC", 1:4)) %>%
  group_by(component) %>%
  top_n(15, abs(value)) %>%
  ungroup() %>%
  mutate(terms = reorder_within(terms, abs(value), component))

ggplot(PCA_git$tidied_pca2, aes(abs(value), terms, fill = value > 0)) +
  geom_col() +
  facet_wrap(~component, scales = "free_y") +
  scale_y_reordered() +
  labs(title = "Key Features - Cluster 2 Subtypes",
       x = "Absolute Contribution", y = NULL)

# Visualize subclusters in PCA space
juice(PCA_git$pca_prep2) %>%
  ggplot(aes(PC1, PC2)) +
  geom_point(aes(color = Subcluster), alpha = 0.7, size = 2) +
  scale_color_manual(values = c("#FF00FF", "#00FFFF" ,"#FF8000"))+
  ggtitle("Cluster 2 Subtypes") +
  theme_classic()

# UMAP visualization
umap_rec2 <- recipe(~., data = PCA_git$Clust2) %>%
  update_role(Subcluster, Time_weeks, Bin_Number_New, 
              Center_X_cell, Center_Y_cell, Cluster, 
              Condition_cell, ImageNumber_cell, 
              Electrode_Thickness, new_role = "id") %>%
  step_normalize(all_predictors()) %>%
  step_umap(all_predictors())

umap_prep2 <- prep(umap_rec2)
juice(umap_prep2) %>%
  ggplot(aes(UMAP1, UMAP2)) +
  geom_point(aes(color = Subcluster), alpha = 0.8, size = 1) +
  scale_color_manual(values = c("#FF00FF", "#00FFFF" ,"#FF8000"))+
  theme_void()



# -------------------------------
# 3. CLUSTER 3 RECLUSTERING (4 SUBTYPES). ---> manuscript Cluster 3
# -------------------------------

# Subset Cluster 2 cells
PCA_git$Clust3 <- subset(PCA_git$df_pca[, c(1:45, 47:56)], Cluster == 3)

# PCA to determine optimal subclusters
PCA_git$pca_clust3 <- prcomp(PCA_git$Clust3[, 1:47], scale = TRUE)
fviz_eig(PCA_git$pca_clust3, 
         main = "Variance Explained - Cluster 2 Subtypes",
         addlabels = TRUE)

# K-means clustering into 4 subtypes
PCA_git$kmeans_clust3 <- kmeans(PCA_git$Clust3[, 1:48], 
                                centers = 4, 
                                nstart = 25)
PCA_git$Clust3$Subcluster <- as.factor(PCA_git$kmeans_clust3$cluster)

# PCA visualization pipeline
PCA_git$pca_rec3 <- recipe(~., data = PCA_git$Clust3) %>%
  update_role(Subcluster, Time_weeks, Bin_Number_New, 
              Center_X_cell, Center_Y_cell, Cluster, 
              Condition_cell, ImageNumber_cell, 
              Electrode_Thickness, new_role = "id") %>%
  step_normalize(all_predictors()) %>%
  step_pca(all_predictors())

PCA_git$pca_prep3 <- prep(PCA_git$pca_rec3)

# Plot top contributing features
PCA_git$tidied_pca3 <- tidy(PCA_git$pca_prep3, 2) %>%
  filter(component %in% paste0("PC", 1:4)) %>%
  group_by(component) %>%
  top_n(15, abs(value)) %>%
  ungroup() %>%
  mutate(terms = reorder_within(terms, abs(value), component))

ggplot(PCA_git$tidied_pca3, aes(abs(value), terms, fill = value > 0)) +
  geom_col() +
  facet_wrap(~component, scales = "free_y") +
  scale_y_reordered() +
  labs(title = "Key Features - Cluster 2 Subtypes",
       x = "Absolute Contribution", y = NULL)

# Visualize subclusters in PCA space
juice(PCA_git$pca_prep3) %>%
  ggplot(aes(PC1, PC2)) +
  geom_point(aes(color = Subcluster), alpha = 0.7, size = 2) +
  scale_color_manual(values = c("#8000FF" ,"#00FF80", "#FF0080", "#0080FF"))+
  ggtitle("Cluster 2 Subtypes") +
  theme_classic()

# UMAP visualization
PCA_git$umap_rec3 <- recipe(~., data = PCA_git$Clust3) %>%
  update_role(Subcluster, Time_weeks, Bin_Number_New, 
              Center_X_cell, Center_Y_cell, Cluster, 
              Condition_cell, ImageNumber_cell, 
              Electrode_Thickness, new_role = "id") %>%
  step_normalize(all_predictors()) %>%
  step_umap(all_predictors())

PCA_git$umap_prep3 <- prep(PCA_git$umap_rec3)
juice(PCA_git$umap_prep3) %>%
  ggplot(aes(UMAP1, UMAP2)) +
  geom_point(aes(color = Subcluster), alpha = 0.8, size = 1) +
  scale_color_manual(values = c("#8000FF" ,"#00FF80", "#FF0080", "#0080FF"))+
  theme_void()



# -------------------------------
# 4. CLUSTER 4 RECLUSTERING (3 SUBTYPES). ---> manuscript Cluster 4
# -------------------------------

# Subset Cluster 2 cells
PCA_git$Clust4 <- subset(PCA_git$df_pca[, c(1:45, 47:56)], Cluster == 4)

# PCA to determine optimal subclusters
PCA_git$pca_clust4 <- prcomp(PCA_git$Clust4[, 1:47], scale = TRUE)
fviz_eig(PCA_git$pca_clust4, 
         main = "Variance Explained - Cluster 2 Subtypes",
         addlabels = TRUE)

# K-means clustering into 4 subtypes
PCA_git$kmeans_clust4 <- kmeans(PCA_git$Clust4[, 1:48], 
                                centers = 3, 
                                nstart = 25)
PCA_git$Clust4$Subcluster <- as.factor(PCA_git$kmeans_clust4$cluster)

# PCA visualization pipeline
PCA_git$pca_rec4 <- recipe(~., data = PCA_git$Clust4) %>%
  update_role(Subcluster, Time_weeks, Bin_Number_New, 
              Center_X_cell, Center_Y_cell, Cluster, 
              Condition_cell, ImageNumber_cell, 
              Electrode_Thickness, new_role = "id") %>%
  step_normalize(all_predictors()) %>%
  step_pca(all_predictors())

PCA_git$pca_prep4 <- prep(PCA_git$pca_rec4)

# Plot top contributing features
PCA_git$tidied_pca4 <- tidy(PCA_git$pca_prep4, 2) %>%
  filter(component %in% paste0("PC", 1:4)) %>%
  group_by(component) %>%
  top_n(15, abs(value)) %>%
  ungroup() %>%
  mutate(terms = reorder_within(terms, abs(value), component))

ggplot(PCA_git$tidied_pca4, aes(abs(value), terms, fill = value > 0)) +
  geom_col() +
  facet_wrap(~component, scales = "free_y") +
  scale_y_reordered() +
  labs(title = "Key Features - Cluster 2 Subtypes",
       x = "Absolute Contribution", y = NULL)

# Visualize subclusters in PCA space
juice(PCA_git$pca_prep4) %>%
  ggplot(aes(PC1, PC2)) +
  geom_point(aes(color = Subcluster), alpha = 0.7, size = 2) +
  scale_color_manual(values = c("#80FF00", "#800000","#008023"))
ggtitle("Cluster 2 Subtypes") +
  theme_classic()

# UMAP visualization
PCA_git$umap_rec4 <- recipe(~., data = PCA_git$Clust4) %>%
  update_role(Subcluster, Time_weeks, Bin_Number_New, 
              Center_X_cell, Center_Y_cell, Cluster, 
              Condition_cell, ImageNumber_cell, 
              Electrode_Thickness, new_role = "id") %>%
  step_normalize(all_predictors()) %>%
  step_umap(all_predictors())

PCA_git$umap_prep4 <- prep(PCA_git$umap_rec4)
juice(PCA_git$umap_prep4) %>%
  ggplot(aes(UMAP1, UMAP2)) +
  geom_point(aes(color = Subcluster), alpha = 0.8, size = 1) +
  scale_color_manual(values = c("#80FF00", "#800000","#008023"))+
theme_void()

# -------------------------------
# 5. SAVE RESULTS
# -------------------------------
saveRDS(PCA_git, "results/reclustering_analysis_results.rds")

