

x0 = 2764
y0 = 2196



##### SCATTER PLOT FOR ALL THE CONDITIONS USING 2 VARIABLE AND ALSO PLOTTING THE REGRESSION LINE & R VALUE #####
ggplot(df_all_reordered[which(df_all_reordered$ImageNumber_cell <= 5),], aes( log10(Cyto_Area) ,Aspect_Ratio_cell,  colour = Bin_Number_New))+
  geom_point()+
  geom_jitter()+
  geom_smooth(method = 'lm')+
  facet_grid(Electrode_Thickness~Time_weeks)+
  ggpubr :: stat_cor(method = "pearson")+
  theme(legend.position = "none")+
  scale_color_viridis(option = "D")+
  ggtitle("scatter plot for comparing 2 variable") 
  # xlab("Dose (mg)") + ylab("Teeth length")


##### COUNT PLOT FOR NUMBER OF CELLS IN VARIATION TO BIN NUMBER FOR ALL CONDITIONS #####

P <- ggplot(df_all_reordered[which(df_all_reordered$ImageNumber_cell <= 6 & df_all_reordered$Bin_Number_New <= 5  ),], aes(x = ImageNumber_cell))+
  geom_bar()+
  geom_boxplot()+
  facet_grid(~Time_weeks)+
  ggtitle("Number of cell in bin number below 5") +
  xlab("Image Number") + ylab("Number of Cells")

Q <- ggplot(df_all_reordered[which(df_all_reordered$ImageNumber_cell <= 6 & df_all_reordered$Bin_Number_New >= 10  ),], aes(x = ImageNumber_cell))+
  geom_bar()+
  facet_grid(~Time_weeks)+
  ggtitle("Number of cell in bin number above 10") +
  xlab("Image Number") + ylab("Number of Cells")




P+Q



my_comparisons <- list( c("0", "01"), c("01", "02"), c("0.5", "2") )

A <- ggpubr::ggboxplot(df_all_reordered[which(df_all_reordered$ImageNumber_cell <= 6 & df_all_reordered$Bin_Number_New <= 5  ),], x = "Time_weeks", y = "MedianRadius_soma",
                       add = c("mean_se"),
                       color = "Time_weeks")+
#  geom_boxplot()+
#  facet_grid(~Time_weeks)+
  ggtitle("Number of cell in bin number below 5") +
  xlab("Image Number") + ylab("Number of Cells")
#  ggpubr::stat_compare_means(method = "anova", label.y = 10)+      # Add global p-value
 # ggpubr::stat_compare_means(label = "p.signif", method = "t.test",
  #                   ref.group = "0") 

A

B <- ggplot(df_all_reordered[which(df_all_reordered$ImageNumber_cell <= 6 & df_all_reordered$Bin_Number_New >= 10  ),], aes(x = Time_weeks, y = MedianRadius_soma))+
  geom_boxplot()+
 # facet_grid(~Time_weeks)+
  ggtitle("Number of cell in bin number above 10") +
  xlab("Image Number") + ylab("Number of Cells")




A+B








#####
  ggplot(df_all_filtered[which(df_all_filtered$Bin_Number_New <= 17 & df_all_filtered$Condition_cell == '6_2'),], aes(radial_dist, Non_Trunk_Branch))+
  geom_point()+
  geom_smooth(method = 'lm')+
  ggpubr :: stat_cor(method = "pearson", label.x = 2500, label.y = 2)

ggplot(df_all_reordered[which(df_all$ImageNumber_cell == 1 & df_all$Condition_cell == '6_2'),], aes(radial_dist, area_ratio))+
  geom_point(outlier.shape = NA)+
  geom_smooth()


ggplot(df_all_reordered[which(df_all$Condition_cell == '11_8'),], aes(Bin_Number_New))+
  geom_histogram()


corr <- cor(df_all_reordered_corr)
corrplot(corr, method = "number", type = 'lower')


pheatmap(df_all_reordered_new, cutree_rows = 4,
         cutree_cols = 3)
                                                                                                                                                                                                                                                                                                              


##### RANDOM FOREST #####

train_data <- df_all_reordered[which(df_all_reordered$ImageNumber_cell <= 5),]


train_data$Bin_Number_New <- as.factor(train_data$Bin_Number_New)

summary(train_data)

set.seed(71)
rf <-randomForest(radial_dist ~ ., data=df_all_reordered_clust, ntree=500) 




##### HEIRARCHY CLUSTERING EXTRA #####

# Finding distance matrix
scale_data <- scale(df_all_reordered_clust_mad)
distance_mat <- dist(scale_data, method = 'euclidean')
distance_mat <- as.data.frame(t(distance_mat))
distance_mat

# Fitting Hierarchical clustering Model
# to training dataset
set.seed(240) # Setting seed
Hierar_cl <- hclust(t(distance_mat), method = "average")
Hierar_cl

# Plotting dendrogram
plot(Hierar_cl)

# Choosing no. of clusters
# Cutting tree by height
abline(h = 90, col = "green")

# Cutting tree by no. of clusters
fit <- cutree(Hierar_cl, k = 3 )
fit

table(fit)
rect.hclust(Hierar_cl, k = 3, border = "green")


