##### COUNT PLOT FOR NUMBER OF CELLS IN VARIATION TO BIN NUMBER FOR ALL CONDITIONS #####

# create a new object for this part of result
count <- list()

# import the datasheet from import to count object. then perform counting of cells using group_by function

count$df_counts <- import$df_all %>% 
  group_by(ImageNumber_cell, Condition_cell, Bin_Number_New) %>% 
  summarize(num_cells = n())

# create two seperate coloums for time_weeks and electrode thickness

count$colmn_count <- paste('Electrode_Thickness',1:2)


count$df_counts <- tidyr::separate(
  data = count$df_counts,
  col = Condition_cell,
  sep = "_",
  into = count$colmn_count,
  remove = FALSE)

names(count$df_counts)[names(count$df_counts) == 'Electrode_Thickness 2'] <- 'Time_weeks'
names(count$df_counts)[names(count$df_counts) == 'Electrode_Thickness 1'] <- 'Electrode_Thickness'
count$df_counts<- filter(count$df_counts, Bin_Number_New != 17)



count$df_counts$radial_dist <- 139 *count$df_counts$Bin_Number_New
count$df_counts$norm_area <- (pi * (count$df_counts$Bin_Number_New)^2) - (pi * (count$df_counts$Bin_Number_New-1)^2)

# Create the boxplot
count$plot <- ggplot(count$df_counts, aes(x = 56.96*Bin_Number_New, y = num_cells /(sqrt((2*pi / count$df_counts$norm_area))) , group = Bin_Number_New, fill = Time_weeks)) +
  geom_boxplot() +
  facet_grid(~Time_weeks)+
  ggtitle("Number of Cells per Bin")+
  scale_fill_manual(values=company_colors)+
  stat_summary(fun.y=median, geom="point", size=2, color="white")+
  xlab("Bin Number") + ylab("Number of Cells normalized to the area")+
  theme_bw()+
  ggtitle("")+
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
    strip.text = element_text(size = 18, face = "bold"))
  


# Print the plot
print(count$plot)









df_image <-  Morpho$df_clust_all[ which(Morpho$df_clust_all$Morpho == "M14"),]



df_image <-  Morpho$df_clust_all[ which(Morpho$df_clust_all$Condition_cell == "06_08" & Morpho$df_clust_all$ImageNumber_cell == "3" & Morpho$df_clust_all$Morpho == "M14"),]
Morpho$df_clust_all_count <- Morpho$df_clust_all[which(Morpho$df_clust_all$Bin_Number_New <= 17), ]