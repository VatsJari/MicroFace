##### Overall trend for morpho-frequence heatmap #####


Morpho$df_Morpho_count <- Morpho$df_clust_all[,c(51,58)]
Morpho$df_Morpho_count <- Morpho$df_Morpho_count[which(Morpho$df_Morpho_count$Bin_Number_New <= 16), ]
Morpho$df_Morpho_count.t <- table(Morpho$df_Morpho_count)
Morpho$df_Morpho_count_scale.t <- scale(Morpho$df_Morpho_count.t)


Morpho$quantile_breaks <- function(xs, n = 16) {
  breaks <- quantile(xs, probs = seq(0, 1, length.out = n))
  breaks[!duplicated(breaks)]
}

Morpho$mat_breaks <- Morpho$quantile_breaks(Morpho$df_Morpho_count_scale.t, n = 16)


#basic heatmap using the count matrix
pheatmap(Morpho$df_Morpho_count_scale.t,
         color             = rev(inferno(length(Morpho$mat_breaks) - 1)),
         breaks            = Morpho$mat_breaks,
         cutree_cols = 4, cutree_rows = 5,
         fontsize          = 14,
         Rowv = NA,
         main              = "Moprho-type Frequency Heatmap")

## SORTING

Morpho$morpho_hm_col <- hclust(dist(t(Morpho$df_Morpho_count_scale.t)))
plot(Morpho$morpho_hm_col, main = "Unsorted Dendrogram", xlab = "", sub = "")

Morpho$sort_hclust <- function(...) as.hclust(dendsort(as.dendrogram(...)))

Morpho$morpho_hm_col <- Morpho$sort_hclust(Morpho$morpho_hm_col)
plot(morpho_hm_col, main = "Sorted Dendrogram", xlab = "", sub = "")

Morpho$morpho_hm_row <- Morpho$sort_hclust(hclust(dist(Morpho$df_Morpho_count_scale.t)))

pheatmap(Morpho$df_Morpho_count_scale.t,
         color             = viridis(length(Morpho$mat_breaks)-2),
         breaks            = Morpho$mat_breaks,
         cutree_cols = 1,
         cutree_rows = 4,
         cluster_cols      = Morpho$morpho_hm_col,
         cluster_rows      = FALSE,
         fontsize          = 14,
         Rowv = FALSE,
         main              = "Moprho-type Frequency Heatmap overview")



##### TIMEPOIMT 00 HEATMAP #####
#Transition - 1
# ramified - 2
#ameboid-3
# rod-ike 4

Morpho$df_morpho_weeks <- Morpho$df_clust_all[which(Morpho$df_clust_all$Bin_Number_New <= 4), ][,c(51,55,56,58)]


# Create a new column "Group" based on the Morpho column
Morpho$df_morpho_weeks$Phenotype <- ifelse(Morpho$df_morpho_weeks$Morpho %in% c("M03", "M04", "M05", "M06"), "1", 
                   ifelse(Morpho$df_morpho_weeks$Morpho %in% c("M12", "M13", "M14"), "2", 
                          ifelse(Morpho$df_morpho_weeks$Morpho %in% c("M08", "M09", "M11"), "3", 
                                 ifelse(Morpho$df_morpho_weeks$Morpho %in% c("M01", "M02", "M07", "M10"), "4", NA))))


Morpho$df_morpho_weeks <- Morpho$df_morpho_weeks[which(Morpho$df_morpho_weeks$Phenotype == "1"), ][,c(1,2)]

Morpho$df_morpho_weeks.t <- table(Morpho$df_morpho_weeks)
Morpho$df_morpho_weeks_scale <- scale(Morpho$df_morpho_weeks.t)


quantile_breaks <- function(xs, n = 16) {
  breaks <- quantile(xs, probs = seq(0, 1, length.out = n))
  breaks[!duplicated(breaks)]
}

Morpho$mat_breaks <- quantile_breaks(Morpho$df_morpho_weeks_scale, n = 16)


#basic heatmap using the count matrix
pheatmap(Morpho$df_morpho_weeks_scale,
         color             = inferno(length(Morpho$mat_breaks) - 1),
         breaks            = Morpho$mat_breaks,
         cutree_cols = 4, cutree_rows = 5,
         fontsize          = 14,
         cluster_rows = FALSE, 
         Rowv =  NA,
         main              = "Moprho-type Frequency Heatmap")

## SORTING

Morpho$morpho_hm_col_week <- hclust(dist(t(Morpho$df_morpho_weeks_scale)))
plot(Morpho$morpho_hm_col_week, main = "Unsorted Dendrogram", xlab = "", sub = "")

sort_hclust <- function(...) as.hclust(dendsort(as.dendrogram(...)), method = "centroid")

Morpho$morpho_hm_col_week <- sort_hclust(Morpho$morpho_hm_col_week)
plot(Morpho$morpho_hm_col_week, main = "Sorted Dendrogram", xlab = "", sub = "")

Morpho$morpho_hm_row <- sort_hclust(hclust(dist(Morpho$df_morpho_weeks_scale)))

pheatmap(Morpho$df_morpho_weeks_scale,
         color             = (viridis(length(mat_breaks)+1 )),
         breaks            = mat_breaks,
         cutree_cols = ,
         cluster_cols      = F,
         clustering_distance_rows = "correlation",
         cluster_rows      = FALSE,
         Rowv =  NA,
         fontsize          = 14,
         main              = "Transition Microglia")
 



##### PLOTS FOR NUMBER OF CELLS AND MORPHO PRESENT IN EACH BIN #####



Morpho$df_clust_all_count <- Morpho$df_clust_all[which(Morpho$df_clust_all$Bin_Number_New <= 16), ]

ggplot(Morpho$df_clust_all_count, aes(x = Morpho, y = area_ratio, group = Morpho, fill = factor(Morpho)))+
  scale_fill_viridis_d()+
  geom_boxplot(outlier.shape = NA)+
#  facet_grid(~Time_weeks)+
  xlab("Morphology type")+
  ylab("Area ratio of cell to soma ")+
 # ylim(0, 27000)+
  theme_bw()+
  theme(
    plot.title = element_text(size=24, hjust = 0.5, face="bold"),
    axis.title.x = element_text(size=22, face="bold"),
    axis.title.y = element_text(size=22, face="bold"),
    axis.text.x = element_text(size = 19, face="bold"),
    axis.text.y  = element_text(size = 19, face="bold"),
    legend.text = element_text(size = 14,  face="bold"),
    legend.title = element_text(size = 18,  face="bold"),
    legend.key.size = unit(1.5, "lines"),
    legend.position = "NA",
    strip.text = element_text(size = 18, face = "bold"))



ggplot(df_clust_all_count[which(df_clust_all_count$Time_weeks == "02" ), ],
       aes(Center_X_cell, Center_Y_cell, colour = factor(Morpho)))+
  geom_point()+
  scale_fill_viridis_d()+
  #facet_grid(~Time_weeks)+
  xlab("Bin Number") + ylab("Number of Cells")+
  theme_bw()+
  ggtitle("Major morpho-families of microglia")+
  theme(
    plot.title = element_text(size=20, hjust = 0.5, face="bold"),
    axis.title.x = element_text(size=14, face="bold"),
    axis.title.y = element_text(size=14, face="bold")
  )


