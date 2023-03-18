
PCA <- list()

##### PCA PLOT FOR CLUSTERED CELLS ALL #####

PCA$df_pca <- import$df_all_reordered[, colnames(import$df_all_reordered)[c(35:82, 5, 6, 25, 29:32)]]

# CHECK NUMBER OF OPTIMAL CLUSTER
PCA$check_number_of_cluster <- prcomp(PCA$df_pca[,1:48], scale = TRUE)
df <- scale(PCA$df_pca[,1:48])


fviz_eig(PCA$check_number_of_cluster, addlabels = TRUE, xlab = "Number of Cluster (K)", ylim = c(0, 50))+
  theme_bw()+ 
  theme(
    plot.title = element_text(size=24, hjust = 0.5, face="bold"),
    axis.title.x = element_text(size=22, face="bold"),
    axis.title.y = element_text(size=22, face="bold"),
    axis.text.x = element_text(size = 17, face="bold"),
    axis.text.y  = element_text(size = 17, face="bold"),
    legend.text = element_text(size = 16,  face="bold"),
    legend.title = element_text(size = 18,  face="bold"),
    legend.key.size = unit(1.5, "lines"),
    legend.position = "bottom",
    strip.text = element_text(size = 18, face = "bold"))


# FIND KMEANS BASED ON OPTIMAL NUMBER OF CLUSTER
PCA$kmeans_all <- kmeans(PCA$df_pca[,1:48], centers = 4, nstart = 25)
PCA$kmeans_all

PCA$df_pca$Cluster <- PCA$kmeans_all$cluster

## PCA starts here

PCA$pca_rec <- recipe(~., data = PCA$df_pca) %>%
  update_role( Time_weeks, Bin_Number_New,  Center_X_cell, Center_Y_cell, 
               Cluster, Condition_cell, ImageNumber_cell, Electrode_Thickness, new_role = "id") %>%
  step_normalize(all_predictors()) %>%
  step_pca(all_predictors())

PCA$pca_prep <- prep(PCA$pca_rec)

PCA$pca_prep


PCA$tidied_pca <- tidy(PCA$pca_prep, 2)

PCA$tidied_pca %>%
  filter(component %in% paste0("PC", 1:2)) %>%
  mutate(component = fct_inorder(component)) %>%
  ggplot(aes(value, terms, fill = terms)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~component, nrow = 1) +
  labs(y = NULL)


PCA$tidied_pca %>%
  filter(component %in% paste0("PC", 1:2)) %>%
  group_by(component) %>%
  top_n(15, abs(value)) %>%
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




juice(PCA$pca_prep) %>%
  ggplot(aes(PC1, PC2, label = NA)) +
  geom_point(aes(color = as.factor(Cluster)), alpha = 0.7, size = 2) +
  geom_text(check_overlap = TRUE, hjust = "inward", family = "IBMPlexSans") +
  labs(color = NULL)+
  scale_color_viridis_d()+
  theme_classic()+
  ggtitle("Major morpho-families of microglia")+
  theme(
    plot.title = element_text(size=24, hjust = 0.5, face="bold"),
    axis.title.x = element_text(size=22, face="bold"),
    axis.title.y = element_text(size=22, face="bold"),
    axis.text.x = element_text(size = 17, face="bold"),
    axis.text.y  = element_text(size = 17, face="bold"),
    legend.text = element_text(size = 16,  face="bold"),
    legend.title = element_text(size = 18,  face="bold"),
    legend.key.size = unit(1.5, "lines"),
    legend.position = "bottom",
    strip.text = element_text(size = 18, face = "bold"))



##### VARIABLES IN CLUSTER #####

ggplot(df_all_reordered_raw, aes(x = Time_weeks, y = RI, group = Time_weeks))+
  geom_boxplot(outlier.shape = NA,aes(middle = mean(Non_Trunk_Branch)))+
  facet_grid(~Cluster)+
  ggtitle("Number of cell in bin number above 10") +
  xlab("Time Points") + ylab("Number of Cells")+
  ggpubr::stat_compare_means(ref.group = "00")


ggplot(df_all_reordered_raw[which(df_all_reordered_raw$Cluster == 4),], aes(x = Time_weeks))+
  geom_bar()+
  facet_grid(~Impact_Region)+
  ggtitle("Number of cell in bin number below 5") +
  xlab("Image Number") + ylab("Number of Cells")

ggplot(df_all_reordered_raw, aes(x = Time_weeks, y = RI, fill= Cluster ))+
  geom_stream()+
  #facet_grid(~Cluster)+
  ggtitle("Number of cell in bin number above 10") +
  xlab("Time Points") + ylab("Number of Cells")



##### RECLUSTERING THE 4 CLUSTERS TO GET A BETTER CLASSIFICATION #####

##### CLUSTER NUMBER 1 #####

# 1-4

PCA$Clust1 <- subset(PCA$df_pca, Cluster == 1)


# CHECK NUMBER OF OPTIMAL CLUSTER
PCA$check_number_of_cluster_1 <- prcomp(PCA$Clust1[,1:48], scale = TRUE)
fviz_eig(PCA$check_number_of_cluster_1)


# KMEANS 
PCA$kmeans_clust1 <- kmeans(PCA$Clust1[,1:48], centers = 4, nstart = 25)
PCA$kmeans_clust1

PCA$Clust1$Cluster_1 <- PCA$kmeans_clust1$cluster

PCA$pca_rec_1 <- recipe(~., data = PCA$Clust1) %>%
  update_role(  Cluster_1, Time_weeks, Bin_Number_New,  Center_X_cell, Center_Y_cell, 
                Cluster, Condition_cell, ImageNumber_cell, Electrode_Thickness, new_role = "id") %>%
  step_normalize(all_predictors()) %>%
  step_pca(all_predictors())

PCA$pca_prep_1 <- prep(PCA$pca_rec_1)

PCA$pca_prep_1


PCA$tidied_pca_1 <- tidy(PCA$pca_prep_1, 2)

PCA$tidied_pca_1 %>%
  filter(component %in% paste0("PC", 1:4)) %>%
  mutate(component = fct_inorder(component)) %>%
  ggplot(aes(value, terms, fill = terms)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~component, nrow = 1) +
  labs(y = NULL)

PCA$tidied_pca_1 %>%
  filter(component %in% paste0("PC", 1:4)) %>%
  group_by(component) %>%
  top_n(15, abs(value)) %>%
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

juice(PCA$pca_prep_1) %>%
  ggplot(aes(PC1, PC2, label = NA)) +
  geom_point(aes(color = as.factor(Cluster_1)), alpha = 0.7, size = 1) +
  geom_text(check_overlap = TRUE, hjust = "inward", family = "IBMPlexSans") +
  labs(color = NULL)+
  scale_color_brewer(palette = "RdBu")+
  theme_classic()+
  ggtitle("Reclustered - Cluster1")+
  theme(
    plot.title = element_text(size=24, hjust = 0.5, face="bold"),
    axis.title.x = element_text(size=22, face="bold"),
    axis.title.y = element_text(size=22, face="bold"),
    axis.text.x = element_text(size = 17, face="bold"),
    axis.text.y  = element_text(size = 17, face="bold"),
    legend.text = element_text(size = 16,  face="bold"),
    legend.title = element_text(size = 18,  face="bold"),
    legend.key.size = unit(1.5, "lines"),
    legend.position = "bottom",
    strip.text = element_text(size = 18, face = "bold"))
  


  #UMAP FOR CLUSTER NUMBER 1

umap_rec <- recipe(~., data = df_all_reordered_raw_clust1) %>%
  update_role(Time_weeks, Impact_Region,  Cluster, Cluster_1, new_role = "id") %>%
  step_normalize(all_predictors()) %>%
  step_umap(all_predictors())

umap_prep <- prep(umap_rec)

umap_prep

juice(umap_prep) %>%
  ggplot(aes(UMAP1, UMAP2, label = NA )) +
  geom_point(aes(color = as.factor(Cluster_1)), alpha = 0.7, size = 2) +
  geom_text(check_overlap = TRUE, hjust = "inward", family = "IBMPlexSans") +
  labs(color = NULL)




##### CLUSTER NUMBER 2 #####

# 2-3

PCA$Clust2 <- subset(PCA$df_pca, Cluster == 2)


# CHECK NUMBER OF OPTIMAL CLUSTER
PCA$check_number_of_cluster_2 <- prcomp(PCA$Clust2[,1:48], scale = TRUE)
fviz_eig(PCA$check_number_of_cluster_2)


# KMEANS 
PCA$kmeans_clust2 <- kmeans(PCA$Clust2[,1:48], centers = 3, nstart = 25)
PCA$kmeans_clust2

PCA$Clust2$Cluster_2 <- PCA$kmeans_clust2$cluster

PCA$pca_rec_2 <- recipe(~., data = PCA$Clust2) %>%
  update_role(  Cluster_2, Time_weeks, Bin_Number_New,  Center_X_cell, Center_Y_cell, 
                Cluster, Condition_cell, ImageNumber_cell, Electrode_Thickness, new_role = "id") %>%
  step_normalize(all_predictors()) %>%
  step_pca(all_predictors())

PCA$pca_prep_2 <- prep(PCA$pca_rec_2)

PCA$pca_prep_2


PCA$tidied_pca_2 <- tidy(PCA$pca_prep_2, 2)

PCA$tidied_pca_2 %>%
  filter(component %in% paste0("PC", 1:4)) %>%
  mutate(component = fct_inorder(component)) %>%
  ggplot(aes(value, terms, fill = terms)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~component, nrow = 1) +
  labs(y = NULL)

PCA$tidied_pca_2 %>%
  filter(component %in% paste0("PC", 1:4)) %>%
  group_by(component) %>%
  top_n(15, abs(value)) %>%
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

juice(PCA$pca_prep_2) %>%
  ggplot(aes(PC1, PC2, label = NA)) +
  geom_point(aes(color = as.factor(Cluster_2)), alpha = 0.7, size = 1) +
  geom_text(check_overlap = TRUE, hjust = "inward", family = "IBMPlexSans") +
  labs(color = NULL)+
  scale_color_brewer(palette = "Set1")+
  theme_classic()+
  ggtitle("Reclustered - Cluster2")+
  theme(
    plot.title = element_text(size=24, hjust = 0.5, face="bold"),
    axis.title.x = element_text(size=22, face="bold"),
    axis.title.y = element_text(size=22, face="bold"),
    axis.text.x = element_text(size = 17, face="bold"),
    axis.text.y  = element_text(size = 17, face="bold"),
    legend.text = element_text(size = 16,  face="bold"),
    legend.title = element_text(size = 18,  face="bold"),
    legend.key.size = unit(1.5, "lines"),
    legend.position = "bottom",
    strip.text = element_text(size = 18, face = "bold"))
  


#UMAP FOR CLUSTER NUMBER 2

umap_rec <- recipe(~., data = PCA$Clust2) %>%
  update_role(Time_weeks, Impact_Region,  Cluster, Cluster_2, new_role = "id") %>%
  step_normalize(all_predictors()) %>%
  step_umap(all_predictors())

umap_prep <- prep(umap_rec)

umap_prep

juice(umap_prep) %>%
  ggplot(aes(UMAP1, UMAP2, label = NA )) +
  geom_point(aes(color = as.factor(Cluster_1)), alpha = 0.7, size = 2) +
  geom_text(check_overlap = TRUE, hjust = "inward", family = "IBMPlexSans") +
  labs(color = NULL)




##### CLUSTER NUMBER 3 #####

# 3-4

PCA$Clust3 <- subset(PCA$df_pca, Cluster == 3)


# CHECK NUMBER OF OPTIMAL CLUSTER
PCA$check_number_of_cluster_3 <- prcomp(PCA$Clust3[,1:48], scale = TRUE)
fviz_eig(PCA$check_number_of_cluster_3)


# KMEANS 
PCA$kmeans_clust3 <- kmeans(PCA$Clust3[,1:48], centers = 4, nstart = 25)
PCA$kmeans_clust3

PCA$Clust3$Cluster_3 <- PCA$kmeans_clust3$cluster

PCA$pca_rec_3 <- recipe(~., data = PCA$Clust3) %>%
  update_role(  Cluster_3, Time_weeks, Bin_Number_New,  Center_X_cell, Center_Y_cell, 
                Cluster, Condition_cell, ImageNumber_cell, Electrode_Thickness, new_role = "id") %>%
  step_normalize(all_predictors()) %>%
  step_pca(all_predictors())

PCA$pca_prep_3 <- prep(PCA$pca_rec_3)

PCA$pca_prep_3


PCA$tidied_pca_3 <- tidy(PCA$pca_prep_3, 2)

PCA$tidied_pca_3 %>%
  filter(component %in% paste0("PC", 1:4)) %>%
  mutate(component = fct_inorder(component)) %>%
  ggplot(aes(value, terms, fill = terms)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~component, nrow = 1) +
  labs(y = NULL)

PCA$tidied_pca_3 %>%
  filter(component %in% paste0("PC", 1:4)) %>%
  group_by(component) %>%
  top_n(15, abs(value)) %>%
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

juice(PCA$pca_prep_3) %>%
  ggplot(aes(PC1, PC2, label = NA)) +
  geom_point(aes(color = as.factor(Cluster_3)), alpha = 0.7, size = 1) +
  geom_text(check_overlap = TRUE, hjust = "inward", family = "IBMPlexSans") +
  labs(color = NULL)+
  scale_color_brewer(palette = "Spectral")+
  theme_classic()+
  ggtitle("Reclustered - Cluster3")+
  theme(
    plot.title = element_text(size=24, hjust = 0.5, face="bold"),
    axis.title.x = element_text(size=22, face="bold"),
    axis.title.y = element_text(size=22, face="bold"),
    axis.text.x = element_text(size = 17, face="bold"),
    axis.text.y  = element_text(size = 17, face="bold"),
    legend.text = element_text(size = 16,  face="bold"),
    legend.title = element_text(size = 18,  face="bold"),
    legend.key.size = unit(1.5, "lines"),
    legend.position = "bottom",
    strip.text = element_text(size = 18, face = "bold"))

#UMAP FOR CLUSTER NUMBER 2

umap_rec <- recipe(~., data = PCA$Clust2) %>%
  update_role(Time_weeks, Impact_Region,  Cluster, Cluster_2, new_role = "id") %>%
  step_normalize(all_predictors()) %>%
  step_umap(all_predictors())

umap_prep <- prep(umap_rec)

umap_prep

juice(umap_prep) %>%
  ggplot(aes(UMAP1, UMAP2, label = NA )) +
  geom_point(aes(color = as.factor(Cluster_1)), alpha = 0.7, size = 2) +
  geom_text(check_overlap = TRUE, hjust = "inward", family = "IBMPlexSans") +
  labs(color = NULL)




##### CLUSTER NUMBER 4 #####

# 4-3

PCA$Clust4 <- subset(PCA$df_pca, Cluster == 4)


# CHECK NUMBER OF OPTIMAL CLUSTER
PCA$check_number_of_cluster_4 <- prcomp(PCA$Clust4[,1:48], scale = TRUE)
fviz_eig(PCA$check_number_of_cluster_4)


# KMEANS 
PCA$kmeans_clust4 <- kmeans(PCA$Clust4[,1:48], centers = 3, nstart = 25)
PCA$kmeans_clust4

PCA$Clust4$Cluster_4 <- PCA$kmeans_clust4$cluster

PCA$pca_rec_4 <- recipe(~., data = PCA$Clust4) %>%
  update_role(  Cluster_4, Time_weeks, Bin_Number_New,  Center_X_cell, Center_Y_cell, 
                Cluster, Condition_cell, ImageNumber_cell, Electrode_Thickness, new_role = "id") %>%
  step_normalize(all_predictors()) %>%
  step_pca(all_predictors())

PCA$pca_prep_4 <- prep(PCA$pca_rec_4)

PCA$pca_prep_4


PCA$tidied_pca_4 <- tidy(PCA$pca_prep_4, 2)

PCA$tidied_pca_4 %>%
  filter(component %in% paste0("PC", 1:4)) %>%
  mutate(component = fct_inorder(component)) %>%
  ggplot(aes(value, terms, fill = terms)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~component, nrow = 1) +
  labs(y = NULL)

PCA$tidied_pca_4 %>%
  filter(component %in% paste0("PC", 1:4)) %>%
  group_by(component) %>%
  top_n(15, abs(value)) %>%
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

juice(PCA$pca_prep_4) %>%
  ggplot(aes(PC1, PC2, label = NA)) +
  geom_point(aes(color = as.factor(Cluster_4)), alpha = 0.7, size = 1) +
  geom_text(check_overlap = TRUE, hjust = "inward", family = "IBMPlexSans") +
  labs(color = NULL)+
  theme_classic()+
  ggtitle("Reclustered - Cluster4")+
  theme(
    plot.title = element_text(size=24, hjust = 0.5, face="bold"),
    axis.title.x = element_text(size=22, face="bold"),
    axis.title.y = element_text(size=22, face="bold"),
    axis.text.x = element_text(size = 17, face="bold"),
    axis.text.y  = element_text(size = 17, face="bold"),
    legend.text = element_text(size = 16,  face="bold"),
    legend.title = element_text(size = 18,  face="bold"),
    legend.key.size = unit(1.5, "lines"),
    legend.position = "bottom",
    strip.text = element_text(size = 18, face = "bold"))

#UMAP FOR CLUSTER NUMBER 4

umap_rec <- recipe(~., data = PCA$Clust4) %>%
  update_role(Time_weeks, Impact_Region,  Cluster, Cluster_4, new_role = "id") %>%
  step_normalize(all_predictors()) %>%
  step_umap(all_predictors())

umap_prep <- prep(umap_rec)

umap_prep

juice(umap_prep) %>%
  ggplot(aes(UMAP1, UMAP2, label = NA )) +
  geom_point(aes(color = as.factor(Cluster_1)), alpha = 0.7, size = 2) +
  geom_text(check_overlap = TRUE, hjust = "inward", family = "IBMPlexSans") +
  labs(color = NULL)




##### HEATMAPS FOR MORPHO OCCURANCE #####
Morpho <- list()

Morpho$df_clust1 <- PCA$Clust1
Morpho$df_clust2 <- PCA$Clust2
Morpho$df_clust3 <- PCA$Clust3
Morpho$df_clust4 <- PCA$Clust4

names(Morpho$df_clust2)[names(Morpho$df_clust2) == 'Cluster_2'] <- 'Cluster_1'
names(Morpho$df_clust3)[names(Morpho$df_clust3) == 'Cluster_3'] <- 'Cluster_1'
names(Morpho$df_clust4)[names(Morpho$df_clust4) == 'Cluster_4'] <- 'Cluster_1'


Morpho$df_clust_all <- bind_rows(Morpho$df_clust1, Morpho$df_clust2, Morpho$df_clust3, Morpho$df_clust4)     # create a merged dataframe from 4 cluster dataframes

Morpho$df_clust_all$Morpho <- case_when(Morpho$df_clust_all$Cluster == 1 & Morpho$df_clust_all$Cluster_1 == 1 ~ "M01",
                                        Morpho$df_clust_all$Cluster == 1 & Morpho$df_clust_all$Cluster_1 == 2 ~ "M02",
                                        Morpho$df_clust_all$Cluster == 1 & Morpho$df_clust_all$Cluster_1 == 3 ~ "M03",
                                        Morpho$ df_clust_all$Cluster == 1 & Morpho$df_clust_all$Cluster_1 == 4 ~ "M04",
                                        Morpho$df_clust_all$Cluster == 2 & Morpho$df_clust_all$Cluster_1 == 1 ~ "M05",
                                        Morpho$df_clust_all$Cluster == 2 & Morpho$df_clust_all$Cluster_1 == 2 ~ "M06",
                                        Morpho$df_clust_all$Cluster == 2 & Morpho$df_clust_all$Cluster_1 == 3 ~ "M07",
                                        Morpho$df_clust_all$Cluster == 3 & Morpho$df_clust_all$Cluster_1 == 1 ~ "M08",
                                        Morpho$df_clust_all$Cluster == 3 & Morpho$df_clust_all$Cluster_1 == 2 ~ "M09",
                                        Morpho$df_clust_all$Cluster == 3 & Morpho$df_clust_all$Cluster_1 == 3 ~ "M10",
                                        Morpho$ df_clust_all$Cluster == 3 & Morpho$df_clust_all$Cluster_1 == 4 ~ "M11", 
                                        Morpho$df_clust_all$Cluster == 4 & Morpho$df_clust_all$Cluster_1 == 1 ~ "M12",
                                        Morpho$df_clust_all$Cluster == 4 & Morpho$df_clust_all$Cluster_1 == 2 ~ "M13",
                                        Morpho$ df_clust_all$Cluster == 4 & Morpho$df_clust_all$Cluster_1 == 3 ~ "M14"
                                 )



##### SAVE THE DF_CLUST_ALL FILE FOR FINDING THE RELATED MORPHOLOGY #####
write.csv(df_clust_all,"D:/Brain Injury project/4 Datasheet/df_clust_all.csv", row.names = FALSE)





# Get the counts for each unique value in the 'Morpho' column
pie_counts <- table(Morpho$df_clust_all$Morpho)


# Create a pie chart
ggplot(data = data.frame(pie_counts), aes(x = 2, y = pie_counts, fill = names(pie_counts))) +
  geom_bar(stat = "identity", color = "white") +
  coord_polar(theta = "y", start = 0) +
  labs(title = "Counts of Morpho") +
  theme_void() +
  geom_text(aes(label = names(pie_counts)), color = "white")+
  scale_fill_viridis_d()+
  xlim(0.5, 2.5)




#####
ggplot(df_clust_all, aes(x=Morpho, y = Bin_Number_New))


ggplot(df_clust_all, aes(x = Bin_Number_New, y = RI, group = Bin_Number_New))+
  geom_boxplot(outlier.shape = NA,aes(middle = mean(RI)))+
  facet_grid(~Morpho)+
  ggtitle("Number of cell in bin number above 10") +
  xlab("Time Points") + ylab("Number of Cells")
 # ggpubr::stat_compare_means(ref.group = "00")


ggplot(df_clust_all[which(df_clust_all$Cluster == 4),], aes(x = Time_weeks))+
  geom_bar()+
  facet_grid(~Impact_Region)+
  ggtitle("Number of cell in bin number below 5") +
  xlab("Image Number") + ylab("Number of Cells")

ggplot(df_clust_all, aes(x = Time_weeks, y = RI, fill= Cluster ))+
  geom_stream()+
  #facet_grid(~Cluster)+
  ggtitle("Number of cell in bin number above 10") +
  xlab("Time Points") + ylab("Number of Cells")


