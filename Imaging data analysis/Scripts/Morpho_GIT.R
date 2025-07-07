# ------------------------------------------------------
# 1. INITIALIZE LIST AND LOAD CLUSTERED DATA
# ------------------------------------------------------

Morpho_git <- list()

Morpho_git$df_clust1 <- PCA$Clust1
Morpho_git$df_clust2 <- PCA$Clust2
Morpho_git$df_clust3 <- PCA$Clust3
Morpho_git$df_clust4 <- PCA$Clust4

# ------------------------------------------------------
# 2. STANDARDIZE CLUSTER COLUMN NAMES
# ------------------------------------------------------

names(Morpho_git$df_clust2)[names(Morpho_git$df_clust2) == 'Cluster_2'] <- 'Cluster_1'
names(Morpho_git$df_clust3)[names(Morpho_git$df_clust3) == 'Cluster_3'] <- 'Cluster_1'
names(Morpho_git$df_clust4)[names(Morpho_git$df_clust4) == 'Cluster_4'] <- 'Cluster_1'

# ------------------------------------------------------
# 3. COMBINE ALL CLUSTER DATA INTO ONE DATAFRAME
# ------------------------------------------------------

Morpho_git$df_clust_all <- bind_rows(
  Morpho_git$df_clust1,
  Morpho_git$df_clust2,
  Morpho_git$df_clust3,
  Morpho_git$df_clust4
)

# ------------------------------------------------------
# 4. ASSIGN MORPHOTYPES BASED ON CLUSTER COMBINATIONS
# ------------------------------------------------------

Morpho_git$df_clust_all$Morpho <- case_when(
  Morpho_git$df_clust_all$Cluster == 1 & Morpho_git$df_clust_all$Cluster_1 == 1 ~ "M01",
  Morpho_git$df_clust_all$Cluster == 1 & Morpho_git$df_clust_all$Cluster_1 == 2 ~ "M02",
  Morpho_git$df_clust_all$Cluster == 1 & Morpho_git$df_clust_all$Cluster_1 == 3 ~ "M03",
  Morpho_git$df_clust_all$Cluster == 1 & Morpho_git$df_clust_all$Cluster_1 == 4 ~ "M04",
  Morpho_git$df_clust_all$Cluster == 2 & Morpho_git$df_clust_all$Cluster_1 == 1 ~ "M05",
  Morpho_git$df_clust_all$Cluster == 2 & Morpho_git$df_clust_all$Cluster_1 == 2 ~ "M06",
  Morpho_git$df_clust_all$Cluster == 2 & Morpho_git$df_clust_all$Cluster_1 == 3 ~ "M07",
  Morpho_git$df_clust_all$Cluster == 3 & Morpho_git$df_clust_all$Cluster_1 == 1 ~ "M08",
  Morpho_git$df_clust_all$Cluster == 3 & Morpho_git$df_clust_all$Cluster_1 == 2 ~ "M09",
  Morpho_git$df_clust_all$Cluster == 3 & Morpho_git$df_clust_all$Cluster_1 == 3 ~ "M10",
  Morpho_git$df_clust_all$Cluster == 3 & Morpho_git$df_clust_all$Cluster_1 == 4 ~ "M11",
  Morpho_git$df_clust_all$Cluster == 4 & Morpho_git$df_clust_all$Cluster_1 == 1 ~ "M12",
  Morpho_git$df_clust_all$Cluster == 4 & Morpho_git$df_clust_all$Cluster_1 == 2 ~ "M13",
  Morpho_git$df_clust_all$Cluster == 4 & Morpho_git$df_clust_all$Cluster_1 == 3 ~ "M14"
)

# ------------------------------------------------------
# 5. ASSIGN PHENOTYPES BASED ON MORPHOTYPES
# ------------------------------------------------------

Morpho_git$df_clust_all$Phenotype <- ifelse(
  Morpho_git$df_clust_all$Morpho %in% c("M01", "M02", "M10", "M07"), "Transition",
  ifelse(
    Morpho_git$df_clust_all$Morpho %in% c("M12", "M13", "M14", "M06", "M05", "M04", "M03"), "Ramified",
    ifelse(
      Morpho_git$df_clust_all$Morpho %in% c("M08", "M09", "M11"), "Ameboid",
      NA
    )
  )
)

# ------------------------------------------------------
# 6. COLOR MAPPING FOR PHENOTYPES
# ------------------------------------------------------

Morpho_git$phenotype_color <- c(
  "Transition" = "#E41E25",
  "Ramified" = "#386C34",
  "Ameboid" = "#6C6A6A"
)

# ------------------------------------------------------
# 7. DEFINE FUNCTION: PLOT BY MORPHOTYPE
# ------------------------------------------------------

Morpho_git$plot_morpho_param <- function(data, param, y_label, y_lim = NULL, angle_x = 0) {
  if (!param %in% names(data)) {
    warning(paste("Variable", param, "not found in data."))
    return(NULL)
  }
  
  p <- ggplot(data, aes_string(x = "Morpho", y = param, group = "Morpho", fill = "Morpho", color = "Morpho")) +
    geom_boxplot(outlier.shape = NA) +
    stat_summary(fun = median, geom = "point", size = 0.1, color = "white") +
    scale_fill_manual(values = morpho_colours) +
    scale_color_manual(values = morpho_colours) +
    theme_classic() +
    theme(
      plot.title = element_text(size = 12, hjust = 0.5, face = "bold"),
      axis.title.x = element_text(size = 10, face = "bold"),
      axis.title.y = element_text(size = 10, face = "bold"),
      axis.text.x = element_text(size = 7, face = "bold", angle = angle_x, hjust = 1),
      axis.text.y = element_text(size = 10, face = "bold"),
      legend.position = "none"
    ) +
    labs(x = "", y = y_label)
  
  if (!is.null(y_lim)) p <- p + ylim(y_lim)
  
  return(p)
}

# ------------------------------------------------------
# 8. DEFINE FUNCTION: PLOT BY PHENOTYPE
# ------------------------------------------------------

Morpho_git$plot_pheno_param <- function(data, param, y_label, y_lim = NULL, angle_x = 0) {
  if (!param %in% names(data)) {
    warning(paste("Variable", param, "not found in data."))
    return(NULL)
  }
  
  p <- ggplot(data, aes_string(x = "Phenotype", y = param, fill = "Phenotype", color = "Phenotype")) +
    geom_violin() +
    stat_summary(fun = median, geom = "point", size = 0.5, color = "white") +
    scale_fill_manual(values = Morpho_git$phenotype_color) +
    scale_color_manual(values = Morpho_git$phenotype_color) +
    theme_classic() +
    theme(
      plot.title = element_text(size = 12, hjust = 0.5, face = "bold"),
      axis.title.x = element_text(size = 10, face = "bold"),
      axis.title.y = element_text(size = 10, face = "bold"),
      axis.text.x = element_text(size = 8, face = "bold", angle = angle_x, hjust = 1),
      axis.text.y = element_text(size = 10, face = "bold"),
      legend.position = "none"
    ) +
    labs(x = "", y = y_label)
  
  if (!is.null(y_lim)) p <- p + ylim(y_lim)
  
  return(p)
}

# ------------------------------------------------------
# 9. DEFINE PARAMETERS TO PLOT FOR MORPHOTYPES
# ------------------------------------------------------

Morpho_git$param_list_morpho <- list(
  list(var = "RI", label = "Ramification Index"),
  list(var = "Solidity_cell", label = "Solidity of cell"),
  list(var = "Cyto_Area", label = "Cytoplasm area", ylim = c(0, 30000)),
  list(var = "Branch_Ends", label = "Branch endpoints", ylim = c(0, 120)),
  list(var = "Perimeter_cell", label = "Perimeter of cell", ylim = c(0, 5500), angle = 45),
  list(var = "FormFactor_soma", label = "Form factor of cell", angle = 45)
)

# ------------------------------------------------------
# 10. GENERATE AND STORE MORPHOTYPE PLOTS
# ------------------------------------------------------

Morpho_git$plots <- lapply(Morpho_git$param_list_morpho, function(p) {
  Morpho_git$plot_morpho_param(
    data = Morpho_git$df_clust_all,
    param = p$var,
    y_label = p$label,
    y_lim = if (!is.null(p$ylim)) p$ylim else NULL,
    angle_x = if (!is.null(p$angle)) p$angle else 45
  )
})

# ------------------------------------------------------
# 11. DEFINE PARAMETERS TO PLOT FOR PHENOTYPES
# ------------------------------------------------------

Morpho_git$param_list_pheno <- list(
  list(var = "RI", label = "Ramification Index"),
  list(var = "Solidity_cell", label = "Solidity of cell"),
  list(var = "Cyto_Area", label = "Cytoplasm area", ylim = c(0, 30000)),
  list(var = "Branch_Ends", label = "Branch endpoints", ylim = c(0, 120)),
  list(var = "Perimeter_cell", label = "Perimeter of cell", ylim = c(0, 5500)),
  list(var = "FormFactor_soma", label = "Form factor of cell")
)

# ------------------------------------------------------
# 12. GENERATE AND STORE PHENOTYPE PLOTS
# ------------------------------------------------------

Morpho_git$pheno_plots <- lapply(Morpho_git$param_list_pheno, function(p) {
  Morpho_git$plot_pheno_param(
    data = Morpho_git$df_clust_all,
    param = p$var,
    y_label = p$label,
    y_lim = if (!is.null(p$ylim)) p$ylim else NULL,
    angle_x = if (!is.null(p$angle)) p$angle else 45
  )
})

# ------------------------------------------------------
# 13. DISPLAY ALL PLOTS
# ------------------------------------------------------

plot_grid(plotlist = Morpho_git$plots, ncol = 2)
plot_grid(plotlist = Morpho_git$pheno_plots, ncol = 3)


# ============================================
# 14. BIN-LEVEL FILTERING & BAR PLOT PROPORTIONS
# ============================================

Morpho_git$df_morpho_weeks <- Morpho_git$df_clust_all[which(Morpho_git$df_clust_all$Bin_Number_New <= 16), ][,c(51,55,56,58,59)]


# Filter rows that meet the condition
Morpho_git$filtered_rows <- Morpho_git$df_morpho_weeks[(Morpho_git$df_morpho_weeks$Bin_Number_New >= 1 & Morpho_git$df_morpho_weeks$Morpho == "M09"), ]

# Randomly sample 50% of the filtered rows
Morpho_git$sampled_rows <- Morpho_git$filtered_rows[sample(nrow(Morpho_git$filtered_rows), nrow(Morpho_git$filtered_rows) * 0.01), ]

# Remove sampled rows from the original dataframe
Morpho_git$df_morpho_weeks <- Morpho_git$df_morpho_weeks[!(Morpho_git$df_morpho_weeks$Bin_Number_New %in% Morpho_git$sampled_rows$Bin_Number_New & Morpho_git$df_morpho_weeks$Morpho %in% Morpho_git$sampled_rows$Morpho), ]

# Now Morpho$df_morpho_weeks contains only the rows that do not meet the condition

Morpho_git$df_morpho_weeks <- Morpho_git$df_morpho_weeks[,c(1,5)]
Morpho_git$df_morpho_weeks$Bin_Number_New <- 1*Morpho_git$df_morpho_weeks$Bin_Number_New

# Calculate the counts and proportions for each bin number and phenotype
Morpho_git$proportion_count <- table(Morpho_git$df_morpho_weeks)

#define function to scale values between 0 and 1
Morpho_git$scale_values <- function(x){(x-min(x))/(max(x)-min(x))}

Morpho_git$proportion_count <- data.frame(Morpho_git$scale_values(Morpho_git$proportion_count))

# Plot the proportion bar plot
# Stacked + percent
ggplot(Morpho_git$proportion_count, aes(fill=Phenotype, y=Freq, x=Bin_Number_New)) + 
  geom_bar(position="fill", stat="identity", alpha = 1)+
  # facet_grid(~Time_weeks)+
  xlab("Bin Number ") +
  ylab("Relative abundance") +
  scale_fill_manual(values=phenotype_color)+
  theme_classic()+
  theme(
    plot.title = element_text(size=24, hjust = 0.5, face="bold"),
    axis.title.x = element_text(size=12, face="bold"),
    axis.title.y = element_text(size=14, face="bold"),
    axis.text.x = element_text(size = 10, face="bold"),
    axis.text.y  = element_text(size = 10, face="bold"),
    legend.text = element_blank(),
    legend.title = element_blank(),
    strip.text = element_text(size = 10, face = "bold"),
    legend.position = "none")


