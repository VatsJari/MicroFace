# -------------------------------
# 1. COUNT PLOT FOR CELLS VS DISTANCE (ALL CONDITIONS)
# -------------------------------

# Initialize list to store objects
count <- list()

# Summarize cell counts per bin for each image and condition
count$df_counts <- import$df_all %>%
  group_by(ImageNumber_cell, Condition_cell, Bin_Number_New) %>%
  summarise(num_cells = n(), .groups = "drop")

# Define column names for separation
count$colmn_count <- paste('Electrode_Thickness', 1:2)

# Split Condition_cell into Electrode_Thickness and Time_weeks
count$df_counts <- tidyr::separate(
  data = count$df_counts,
  col = Condition_cell,
  sep = "_",
  into = count$colmn_count,
  remove = FALSE
)

# Rename the split columns
names(count$df_counts)[names(count$df_counts) == 'Electrode_Thickness 1'] <- 'Electrode_Thickness'
names(count$df_counts)[names(count$df_counts) == 'Electrode_Thickness 2'] <- 'Time_weeks'

# Remove Bin 17 (outlier or empty bin)
count$df_counts <- dplyr::filter(count$df_counts, Bin_Number_New != 17)

# Calculate radial distance and annular bin area
count$df_counts$radial_dist <- 139 * count$df_counts$Bin_Number_New
count$df_counts$norm_area <- (pi * (count$df_counts$radial_dist)^2) -
  (pi * (count$df_counts$radial_dist - 139)^2)

# -------------------------------
# 2. PLOT: CELL DENSITY VS DISTANCE
# -------------------------------

# Create the boxplot
count$plot <- ggplot(count$df_counts, aes(x = 139*Bin_Number_New, y = 100*(count$df_counts$num_cells / 2*sqrt((pi / count$df_counts$norm_area))), group = Time_weeks, color = Time_weeks)) +
  geom_smooth(linewidth = 2, method = "loess", se = F) +
  ggtitle("Number of Cells per Bin")+
  scale_color_manual(values=company_colors)+
  stat_summary(fun.y=median, geom="point", size=2, color="white")+
  xlab("Distance from implantation site (µm)") + ylab("Cell density normalized to area [au.]")+
  theme_classic()+
  ggtitle("")+
  labs(color = "Time (Weeks)")+
  theme(
    plot.title = element_text(size=12, hjust = 0.5, face="bold"),
    axis.title.x = element_text(size=12, face="bold"),
    axis.title.y = element_text(size=12, face="bold"),
    axis.text.x = element_text(size = 10, face="bold"),
    axis.text.y  = element_text(size = 10, face="bold"),
    legend.text = element_text(size = 8,  face="bold"),
    legend.title = element_text(size = 8,  face="bold"),
    legend.key.size = unit(1.5, "lines"),
    legend.position = "right",
    strip.text = element_text(size = 10, face = "bold"))


# -------------------------------
# 3. DISPLAY PLOT
# -------------------------------

print(count$plot)
