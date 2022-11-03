



##### PCA #####

pca_rec <- recipe(~., data = df_all_reordered_raw) %>%
  update_role(Electrode_Thickness, Bin_Number_New, Time_weeks, Branch_Ratio,  new_role = "id") %>%
  step_normalize(all_predictors()) %>%
  step_pca(all_predictors())

pca_prep <- prep(pca_rec)

pca_prep


tidied_pca <- tidy(pca_prep, 2)

tidied_pca %>%
  filter(component %in% paste0("PC", 1:7)) %>%
  mutate(component = fct_inorder(component)) %>%
  ggplot(aes(value, terms, fill = terms)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~component, nrow = 1) +
  labs(y = NULL)


tidied_pca %>%
  filter(component %in% paste0("PC", 1:5)) %>%
  group_by(component) %>%
  top_n(10, abs(value)) %>%
  ungroup() %>%
  mutate(terms = reorder_within(terms, abs(value), component)) %>%
  ggplot(aes(abs(value), terms, fill = value > 0)) +
  geom_col() +
  facet_wrap(~component, scales = "free_y") +
  scale_y_reordered() +
  labs(
    x = "Absolute value of contribution",
    y = NULL, fill = "Positive?"
  )




juice(pca_prep) %>%
  ggplot(aes(PC1, PC2, label = Time_weeks)) +
  geom_point(aes(color = Bin_Number_New), alpha = 0.7, size = 2) +
  geom_text(check_overlap = TRUE, hjust = "inward", family = "IBMPlexSans") +
  labs(color = NULL)





##### UMAP #####


umap_rec <- recipe(~., data = df_all_reordered_raw) %>%
  update_role(Electrode_Thickness, Bin_Number_New, Time_weeks, Branch_Ratio, new_role = "id") %>%
  step_normalize(all_predictors()) %>%
  step_umap(all_predictors())

umap_prep <- prep(umap_rec)

umap_prep

juice(umap_prep) %>%
  ggplot(aes(UMAP1, UMAP2, label = Time_weeks )) +
  geom_point(aes(color = Bin_Number_New), alpha = 0.7, size = 2) +
  geom_text(check_overlap = TRUE, hjust = "inward", family = "IBMPlexSans") +
  labs(color = NULL)






##### PCA version 2 #####

df_all_reordered_clust <- df_all_reordered[, colnames(df_all_reordered)[c(30:77)]]

scale_data_raw <- scale(df_all_reordered_clust[1:10000,])

df_all_reordered_pca <- prcomp(scale_data_raw, center = TRUE)
summary(df_all_reordered_pca)
 
ggbiplot(df_all_reordered_pca)
