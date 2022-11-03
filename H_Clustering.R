

##### CONSENSUS CLUSTERING #####


df_all_reordered_clust <- df_all_reordered[, colnames(df_all_reordered)[c(29:77)]]

mads=apply(df_all_reordered_clust,1,mad)

df_all_reordered_clust_mad=df_all_reordered_clust[rev(order(mads))[1:50000],]

df_all_reordered_clust_hc = sweep(df_all_reordered_clust_mad,1, apply(df_all_reordered_clust_mad,1,median,na.rm=T))

title=tempdir()

df_all_reordered_clust_mad = as.matrix(df_all_reordered_clust_mad)
df_all_reordered_clust_hc = as.matrix(df_all_reordered_clust_hc)


results_1 = ConsensusClusterPlus(df_all_reordered_clust_hc, maxK=6,reps=1000,pItem=0.8,pFeature=1,
                               title=title, clusterAlg="hc",distance="pearson")

results_2 = ConsensusClusterPlus(df_all_reordered_clust_mad, maxK=6,reps=1000,pItem=0.8,pFeature=1,
                                 title=title, clusterAlg="km",distance="euclidean")

results_3 = ConsensusClusterPlus(df_all_reordered_clust_mad, maxK=6,reps=1000,pItem=0.8,pFeature=1,
                                 title=title, clusterAlg="pam",distance="manhattan")


icl = calcICL(results,title=title,plot="png")
icl[["clusterConsensus"]]



##### HEATMAP RAW DATA #####


df_all_reordered_clust <- df_all_reordered[, colnames(df_all_reordered)[c(30:77)]]

scale_data_raw <- scale(df_all_reordered_clust[1:10000,])



pheatmap(scale_data_raw, scale = "column", 
         cutree_cols = 4, cutree_rows = 4,
         color=inferno(10),
         show_rownames     = FALSE)


##### SORT THE BREAKS FOR HEATMAP COLOUR #####

scale_breaks <- seq(min(scale_data_raw), max(scale_data_raw), length.out = 10)


quantile_breaks <- function(xs, n = 10) {
  breaks <- quantile(xs, probs = seq(0, 1, length.out = n))
  breaks[!duplicated(breaks)]
}

scale_breaks_quantile <- quantile_breaks(scale_data_raw, n = 11)


pheatmap(scale_data_raw, scale = "column", 
         cutree_cols = 4, cutree_rows = 4,
         color=inferno(length(scale_breaks_quantile) - 1),
         breaks = scale_breaks_quantile,
         show_rownames     = FALSE)

##### DENDOGRAM SORTING #####


scale_cluster_cols <- hclust(dist(t(scale_data_raw)))

plot(scale_cluster_cols, main = "Unsorted Dendrogram", xlab = "", sub = "")


sort_hclust <- function(...) as.hclust(dendsort(as.dendrogram(...)))

scale_cluster_cols <- sort_hclust(scale_cluster_cols)

plot(scale_cluster_cols, main = "Sorted Dendrogram", xlab = "", sub = "")

scale_cluster_rows <- sort_hclust(hclust(dist(scale_data_raw)))


plot(as.phylo(scale_cluster_cols), main = "Sorted Dendrogram", type = "fan")

##### PLOT SORTED DENDOGRAM HEATMAP #####

pheatmap(scale_data_raw, 
         cutree_cols = 4, cutree_rows = 5,
         color=inferno(length(scale_breaks_quantile) - 1),
         breaks = scale_breaks_quantile, border_color      = NA,
         cluster_cols      = scale_cluster_cols,
         cluster_rows      = scale_cluster_rows,
         show_rownames     = FALSE,
         main              = "Sorted Dendrograms")



##### CORRPLOT #####
corr <- cor(scale_data_raw)
corrplot(corr, method = "circle", type = 'lower', )



##### DENDOGRAMS FOR DIFFERENT TIMEPOINTS #####

df_dend <- df_all_reordered[, colnames(df_all_reordered)[c(23, 30 , 32:78)]]


df_0_dend <- df_dend[df_dend$Time_weeks == '18', ]

df_0_dend_close <- df_0_dend[which(df_0_dend$Bin_Number_New <= 10), ] 
df_0_dend_close <-  df_0_dend_close[,-1:-2]
df_0_dend_close_scale <- scale(df_0_dend_close) 

df_0_dend_far <- df_0_dend[which(df_0_dend$Bin_Number_New >= 10), ]
df_0_dend_far <- df_0_dend_far[,-1:-2]
df_0_dend_far_scale <- scale(df_0_dend_far)



scale_cluster_cols <- hclust(dist(t(df_0_dend_close_scale)))

sort_hclust <- function(...) as.hclust(dendsort(as.dendrogram(...)))

scale_cluster_cols <- sort_hclust(scale_cluster_cols)

plot(scale_cluster_cols, main = "Close to Injury site - Acute ", xlab = "", sub = "")




scale_cluster_cols_far <- hclust(dist(t(df_0_dend_far_scale)))

sort_hclust <- function(...) as.hclust(dendsort(as.dendrogram(...)))

scale_cluster_cols_far <- sort_hclust(scale_cluster_cols_far)

plot(scale_cluster_cols_far, main = "Far away from Injury site - Acute ", xlab = "", sub = "")



tanglegram(scale_cluster_cols, scale_cluster_cols_far,
           highlight_distinct_edges = FALSE, # Turn-off dashed lines
           common_subtrees_color_branches = TRUE # Color common branches
           ) %>%
  untangle(method = "step1side") %>%
  entanglement()
  ggtitle("dend")

all.equal(scale_cluster_cols, scale_cluster_cols_far)

