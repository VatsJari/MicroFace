


#### create a new object called H_clust

H_clust <- list()

### import the dataframe to the list 
H_clust$df_clust <- import$df_all_reordered[, colnames(import$df_all_reordered)[c(31, 32,  25, 35:82)]]
H_clust$df_clust<- filter(H_clust$df_clust, Bin_Number_New <= 16)
H_clust$df_clust <-  H_clust$df_clust[,-42]

#### scale the coloums 

H_clust$scale <- scale(H_clust$df_clust[ ,4:50])
H_clust$scaled_df <- cbind(H_clust$df_clust[, 1:3], H_clust$scale)



H_clust$cluster_cols <- hclust(dist(t(H_clust$scaled_df[,4:50])))



plot(H_clust$cluster_cols, main = "Unsorted Dendrogram", xlab = "", sub = "")


H_clust$sort_hclust <- function(...) as.hclust(dendsort(as.dendrogram(...)))

H_clust$cluster_cols <- H_clust$sort_hclust(H_clust$cluster_cols)

H_clust$gobal_dendrogram <- fviz_dend(H_clust$cluster_cols, cex = 0.8, k=4, 
          rect = TRUE,  
          k_colors = "jco",
          rect_border = "jco", 
          rect_fill = TRUE, 
          horiz = TRUE )+
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
    


plot(H_clust$gobal_dendrogram)


plot(as.phylo(H_clust$cluster_cols), main = "Sorted Dendrogram", type = "fan",label.offset=0.2,no.margin=TRUE, cex=0.70, show.node.label = TRUE)












##### IMPORANCE BUBBLE PLOT #####


# Calculate the importance of each column in each condition
H_clust$importance <- aggregate(H_clust$scaled_df[, 4:50], by = list(Weeks = H_clust$scaled_df$Time_weeks), FUN = mean)

# Melt the data frame to long format
H_clust$importance_melted <- melt(H_clust$importance, id.vars = c("Weeks"), variable.name = "Parameter", value.name = "Importance")


H_clust$df_grouped <- H_clust$importance_melted %>% group_by(Weeks)


H_clust$f_top20 <- H_clust$df_grouped %>% 
  slice_max(order_by = Importance, n = 20) %>%
  ungroup()



H_clust$top20_parameter <- ggplot(H_clust$f_top20, aes(x = Importance, y = Parameter, fill = factor(Weeks))) + 
  geom_col() +
  facet_grid(~Weeks) +
  scale_fill_manual(values=company_colors)+
  labs(title = "Top 20 Parameters") +
  theme_bw()+
  labs(fill = "Time (Weeks)")+
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
    strip.text = element_text(size = 18, face = "bold"))+
  xlab("Variation Value") +
  ylab("Parameter")

plot(H_clust$top20_parameter)


# group by time points and calculate sum of importance
H_clust$sum_imp <- H_clust$f_top20 %>%
  group_by(Weeks) %>%
  summarize(total_importance = sum(Importance))

# plot as a bar chart
ggplot(H_clust$sum_imp, aes(x = factor(Weeks), y = total_importance, fill = factor(Weeks))) +
  geom_col() +
  scale_fill_manual(values=company_colors)+theme_bw()+
  theme(
    plot.title = element_text(size=20, hjust = 0.5, face="bold"),
    axis.title.x = element_text(size=18, face="bold"),
    axis.title.y = element_text(size=18, face="bold"),
    axis.text.x = element_text(size = 16, face="bold"),
    axis.text.y  = element_text(size = 16, face="bold"))+
  labs(x = "Time points (weeks)", y = "Summed importance")+
  geom_smooth(method = "lm", se = FALSE)



##### comparision dendrogram ####


dend_comp <- list()


##### DENDOGRAMS FOR DIFFERENT TIMEPOINTS #####

#00 = 3,11
#01 = 3, 13
# 02 = 3, 9
# 08 = 4, 9
#18 - 3,12


dend_comp$df_dend <- import$df_all_reordered_raw

dend_comp$df_0_dend <- dend_comp$df_dend[dend_comp$df_dend$Time_weeks == "02", ]

dend_comp$df_0_dend_close <- dend_comp$df_0_dend[which(dend_comp$df_0_dend$Bin_Number_New <= 3 ), ] 
dend_comp$df_0_dend_close <-  dend_comp$df_0_dend_close[,-1:-4]
dend_comp$df_0_dend_close <-  dend_comp$df_0_dend_close[,-38]
dend_comp$df_0_dend_close_scale <- scale(dend_comp$df_0_dend_close) 

dend_comp$df_0_dend_far <- dend_comp$df_0_dend[which(dend_comp$df_0_dend$Bin_Number_New >= 9), ]
dend_comp$df_0_dend_far <- dend_comp$df_0_dend_far[,-1:-4]
dend_comp$df_0_dend_far <- dend_comp$df_0_dend_far[,-38]
dend_comp$df_0_dend_far_scale <- scale(dend_comp$df_0_dend_far)



dend_comp$scale_cluster_cols <- hclust(dist(t(dend_comp$df_0_dend_close_scale)))

dend_comp$sort_hclust <- function(...) as.hclust(dendsort(as.dendrogram(...)))

dend_comp$scale_cluster_cols <- dend_comp$sort_hclust(dend_comp$scale_cluster_cols)

plot(dend_comp$scale_cluster_cols, main = "Close to Injury site - Acute ", xlab = "", sub = "")



dend_comp$scale_cluster_cols_far <- hclust(dist(t(dend_comp$df_0_dend_far_scale)))

dend_comp$sort_hclust <- function(...) as.hclust(dendsort(as.dendrogram(...)))

dend_comp$scale_cluster_cols_far <- dend_comp$sort_hclust(dend_comp$scale_cluster_cols_far)

plot(dend_comp$scale_cluster_cols_far, main = "Far away from Injury site - Acute ", xlab = "", sub = "")



tanglegram(dend_comp$scale_cluster_cols, dend_comp$scale_cluster_cols_far,
           highlight_distinct_edges = FALSE, # Turn-off dashed lines
           common_subtrees_color_branches = TRUE # Color common branches
) %>%
  untangle(method = "step1side") %>%
  entanglement()



dend_comp$tanglegram_values <- all.equal(dend_comp$scale_cluster_cols, dend_comp$scale_cluster_cols_far)

view(dend_comp$tanglegram_values)

##### DENDOGRAM COMPARISION FOR ACTUE CONDITION VS DIFF TIME POINT NEAR TO IMPACT AREA #####

dend_weeks <- list()

dend_weeks$df_dend <- import$df_all_reordered_raw 


dend_weeks$df_0_dend <- dend_weeks$df_dend[dend_weeks$df_dend$Time_weeks == '00', ]
dend_weeks$df_1_dend <- dend_weeks$df_dend[dend_weeks$df_dend$Time_weeks == '18', ]

dend_weeks$df_0_dend_close <- dend_weeks$df_0_dend[which(dend_weeks$df_0_dend$Bin_Number_New <= 4), ] 
dend_weeks$df_0_dend_close <-  dend_weeks$df_0_dend_close[,-1:-4]
dend_weeks$df_0_dend_close_scale <- scale(dend_weeks$df_0_dend_close) 

dend_weeks$df_1_dend_close <- dend_weeks$df_1_dend[which(dend_weeks$df_1_dend$Bin_Number_New <= 3), ]
dend_weeks$df_1_dend_close <- dend_weeks$df_1_dend_close[,-1:-4]
dend_weeks$df_1_dend_01_scale <- scale(dend_weeks$df_1_dend_close)



dend_weeks$scale_cluster_cols <- hclust(dist(t(dend_weeks$df_0_dend_close_scale)))

dend_weeks$sort_hclust <- function(...) as.hclust(dendsort(as.dendrogram(...)))

dend_weeks$scale_cluster_cols <- dend_weeks$sort_hclust(dend_weeks$scale_cluster_cols)

plot(dend_weeks$scale_cluster_cols, main = "Close to Injury site - Acute ", xlab = "", sub = "")



dend_weeks$scale_cluster_cols_2 <- hclust(dist(t(dend_weeks$df_1_dend_01_scale)))

dend_weeks$sort_hclust <- function(...) as.hclust(dendsort(as.dendrogram(...)))

dend_weeks$scale_cluster_cols_2 <- dend_weeks$sort_hclust(dend_weeks$scale_cluster_cols_2)

plot(dend_weeks$scale_cluster_cols_2, main = "Far away from Injury site - Acute ", xlab = "", sub = "")



tanglegram(dend_weeks$scale_cluster_cols, dend_weeks$scale_cluster_cols_2,
           highlight_distinct_edges = FALSE, # Turn-off dashed lines
           common_subtrees_color_branches = TRUE) +
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
    strip.text = element_text(size = 18, face = "bold"))%>%  # Color common branches
  untangle(method = "step1side") %>%
  entanglement()

all.equal(dend_weeks$scale_cluster_cols, dend_weeks$scale_cluster_cols_2)


#####

para_plot <- list()


para_plot$df_plot <- filter_data_1(import$df_all) %>% dplyr::select(c(9,10,11,12,13,14,19, 29 ,32,33,34,37,38,39,
                                                  40,41,42,47,57, 60, 65, 66, 68, 69, 70, 71, 78, 81), everything())

para_plot$df_plot <- para_plot$df_plot[, colnames(para_plot$df_plot)[c(31, 32,  25, 35:82)]]

para_plot$df_plot<- filter(para_plot$df_plot, Bin_Number_New <= 17)


# Create the plot



para_plot$df_value <- para_plot$df_plot %>%
  mutate(bin_group = ifelse(Bin_Number_New %in% 1:4, "Close", ifelse(Bin_Number_New %in% 12:16, "Far", "other"))) %>%
  filter(bin_group %in% c("Close", "Far"))


# create the plot


# area
# RI
# aspect ratio
# endpoints
# perimeter
# solidity

  para_plot$plot <-  ggplot(para_plot$df_value, aes(x = bin_group, y = Area_soma, group = bin_group, fill = Time_weeks)) +
  geom_boxplot() +
  scale_fill_manual(values=company_colors)+
  stat_summary(fun = median, geom = "point", size = 3, color = "white") +
  facet_wrap(~Time_weeks, nrow = 1) +
#  ggpubr :: stat_compare_means(method = "t.test", comparisons = list(c("Close", "Far")))+
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
      strip.text = element_text(size = 18, face = "bold"))+
  labs(x = "Bin Group", y = "Area of cell") 
 # ggtitle("RI by Bin Group and Time Weeks")


plot(para_plot$plot)


##### Corrplot


para_plot$corr_df <- para_plot$df_plot[, colnames(para_plot$df_plot)[c(4:51)]]
para_plot$corr <- cor(para_plot$corr_df)
corrplot(para_plot$corr, method = 'color', order = 'hclust', col = COL2('RdBu'))



