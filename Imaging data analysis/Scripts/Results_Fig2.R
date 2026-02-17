##### Fig2 PLOT FOR NUMBER OF CELLS IN VARIATION TO BIN NUMBER FOR ALL CONDITIONS #####

# create a new object for this part of result
Fig2 <- list()

# import the datasheet from import to Fig2 object. then perform Fig2ing of cells using group_by function

Fig2$df_Fig2s <- import$df_all %>% 
  group_by(ImageNumber_cell, SubImage, Animal_No , Bin_Number_New, Time_weeks, Electrode_Thickness ) %>% 
  summarize(num_cells = n())

# create two seperate coloums for time_weeks and electrode thickness


Fig2$df_Fig2s<- filter(Fig2$df_Fig2s, Bin_Number_New != 17)
Fig2$df_Fig2s$radial_dist <- 139 *Fig2$df_Fig2s$Bin_Number_New
Fig2$df_Fig2s$norm_area <- (pi * (Fig2$df_Fig2s$radial_dist)^2) - (pi * (Fig2$df_Fig2s$radial_dist-139)^2)

# Create the boxplot
Fig2$plot <- ggplot(Fig2$df_Fig2s, aes(x = 139*Bin_Number_New, y = 100*(Fig2$df_Fig2s$num_cells / 2*sqrt((pi / Fig2$df_Fig2s$norm_area))), group = Time_weeks, color = Time_weeks)) +
  geom_smooth(linewidth = 2, method = "loess", se = F) +
  #  geom_vline(xintercept = c(4, 8), linetype = "dashed", color = "Blue", size = 0.5) +
  ggtitle("Number of Cells per Bin")+
  scale_color_manual(values=company_colors)+
  stat_summary(fun.y=median, geom="point", size=2, color="white")+
  xlab("Distance from implantation site (µm)") + ylab("Cell density normalized to area [au.]")+
  theme_classic()+
  ggtitle("")+
  #facet_grid(~Electrode_Thickness)+
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

# Print the plot
print(Fig2$plot)


Fig2$plot2 <- ggplot(Fig2$df_Fig2s, aes(x = 139*Bin_Number_New, y = 100*(Fig2$df_Fig2s$num_cells / 2*sqrt((pi / Fig2$df_Fig2s$norm_area))), group = Time_weeks, color = Time_weeks)) +
  geom_smooth(linewidth = 2, method = "loess", se = F) +
  #  geom_vline(xintercept = c(4, 8), linetype = "dashed", color = "Blue", size = 0.5) +
  ggtitle("Number of Cells per Bin")+
  scale_color_manual(values=company_colors)+
  stat_summary(fun.y=median, geom="point", size=2, color="white")+
  xlab("Distance from implantation site (µm)") + ylab("Cell density normalized to area [au.]")+
  theme_classic()+
  ggtitle("")+
  facet_grid(~Electrode_Thickness)+
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



# Print the plot
print(Fig2$plot2)









# ============================================
# FIG2 - Cell Density Analysis (Normalized by Image Count)
# ============================================

Fig2 <- list()


# Step 1: Group by all relevant factors and count cells per image-bin
Fig2$df_raw <- import$df_all %>% 
  group_by(ImageNumber_cell, SubImage, Animal_No, Bin_Number_New, Time_weeks, Electrode_Thickness) %>% 
  summarise(cells_per_image_bin = n(), .groups = "drop")

# Step 2: Remove bin 17
Fig2$df_raw <- filter(Fig2$df_raw, Bin_Number_New != 17)

# Step 3: Calculate radial distance and area for each bin
Fig2$df_raw$radial_dist <- 139 * Fig2$df_raw$Bin_Number_New
Fig2$df_raw$bin_area <- pi * (Fig2$df_raw$radial_dist)^2 - pi * (Fig2$df_raw$radial_dist - 139)^2

# Step 4: IMPORTANT - Count number of unique images per group
# This accounts for different numbers of images across conditions
Fig2$image_counts <- Fig2$df_raw %>%
  group_by(Bin_Number_New, Time_weeks, Electrode_Thickness) %>%
  summarise(
    n_images = n_distinct(ImageNumber_cell),
    total_cells = sum(cells_per_image_bin),
    .groups = "drop"
  )

# Step 5: Calculate average cells per image and density
Fig2$df_summary <- Fig2$df_raw %>%
  group_by(Bin_Number_New, Time_weeks, Electrode_Thickness) %>%
  summarise(
    # Average cells per image (accounts for varying number of images)
    avg_cells_per_image = mean(cells_per_image_bin, na.rm = TRUE),
    # Total cells
    total_cells = sum(cells_per_image_bin, na.rm = TRUE),
    # Number of images contributing to this bin
    n_images = n_distinct(ImageNumber_cell),
    # Standard deviation and SEM
    sd_cells = sd(cells_per_image_bin, na.rm = TRUE),
    sem_cells = sd_cells / sqrt(n_images),
    # Bin area (same for all, but keep for calculation)
    bin_area = first(bin_area),
    radial_dist = first(radial_dist),
    .groups = "drop"
  )

# Step 6: Calculate normalized density
# Using your formula: 100 * (cells / (2 * sqrt(pi/area)))
Fig2$df_summary <- Fig2$df_summary %>%
  mutate(
    # Density based on average cells per image
    density_avg = 100 * (avg_cells_per_image / (2 * sqrt(pi / bin_area))),
    # Density based on total cells (alternative)
    density_total = 100 * (total_cells / n_images / (2 * sqrt(pi / bin_area))),
    # Upper and lower bounds using SEM
    density_upper = 100 * ((avg_cells_per_image + sem_cells) / (2 * sqrt(pi / bin_area))),
    density_lower = 100 * ((avg_cells_per_image - sem_cells) / (2 * sqrt(pi / bin_area)))
  )

# Print verification
cat("\n=== VERIFICATION: Image Counts per Group ===\n")
print(Fig2$image_counts)

cat("\n=== SUMMARY STATISTICS ===\n")
print(Fig2$df_summary %>% 
        dplyr::select(Bin_Number_New, Time_weeks, Electrode_Thickness, 
               avg_cells_per_image, n_images, density_avg))

# Step 7: Plot 1 - Without faceting (smoothed lines)
Fig2$plot1 <- ggplot(Fig2$df_summary, 
                     aes(x = radial_dist, 
                         y = log(density_avg), 
                         group = interaction(Time_weeks),
                         color = as.factor(Time_weeks))) +
  # Smoothed lines
  geom_smooth(linewidth = 1.5, method = "loess", se = FALSE) +
  # Points with error bars
 # geom_point(size = 2, alpha = 0.7) +
  geom_errorbar(aes(ymin = log(density_lower), ymax = log(density_upper)), 
                width = 50, alpha = 0.5) +
  # Colors and themes
  scale_color_manual(values = company_colors, name = "Time (Weeks)") +
 # scale_linetype_manual(values = c("solid", "dashed"), name = "Thickness") +
  labs(
    title = "Cell Density Normalized by Area",
    x = "Distance from implantation site (µm)", 
    y = "Cell density [normalized to area]"
  ) +
  theme_classic() +
  theme(
    plot.title = element_text(size = 12, hjust = 0.5, face = "bold"),
    axis.title.x = element_text(size = 12, face = "bold"),
    axis.title.y = element_text(size = 12, face = "bold"),
    axis.text.x = element_text(size = 10, face = "bold"),
    axis.text.y = element_text(size = 10, face = "bold"),
    legend.text = element_text(size = 8, face = "bold"),
    legend.title = element_text(size = 8, face = "bold"),
    legend.key.size = unit(1.5, "lines"),
    legend.position = "right"
  )

print(Fig2$plot1)

# Step 8: Plot 2 - With faceting by Electrode_Thickness
Fig2$plot2 <- ggplot(Fig2$df_summary, 
                     aes(x = radial_dist, 
                         y = density_avg, 
                         group = Time_weeks,
                         color = as.factor(Time_weeks))) +
  # Smoothed lines
  geom_smooth(linewidth = 1.5, method = "loess", se = FALSE) +
  # Points with error bars
  geom_point(size = 2, alpha = 0.7) +
  geom_errorbar(aes(ymin = density_lower, ymax = density_upper), 
                width = 50, alpha = 0.5) +
  # Colors and themes
  scale_color_manual(values = Fig2$company_colors, name = "Time (Weeks)") +
  facet_wrap(~Electrode_Thickness, ncol = 2) +
  labs(
    title = "Cell Density by Electrode Thickness",
    x = "Distance from implantation site (µm)", 
    y = "Cell density [normalized to area]"
  ) +
  theme_classic() +
  theme(
    plot.title = element_text(size = 12, hjust = 0.5, face = "bold"),
    axis.title.x = element_text(size = 12, face = "bold"),
    axis.title.y = element_text(size = 12, face = "bold"),
    axis.text.x = element_text(size = 10, face = "bold"),
    axis.text.y = element_text(size = 10, face = "bold"),
    legend.text = element_text(size = 8, face = "bold"),
    legend.title = element_text(size = 8, face = "bold"),
    legend.key.size = unit(1.5, "lines"),
    legend.position = "right",
    strip.text = element_text(size = 10, face = "bold")
  )

print(Fig2$plot2)

# Step 9: Alternative - Bar plot showing image counts
Fig2$plot_image_counts <- ggplot(Fig2$image_counts, 
                                 aes(x = as.factor(Bin_Number_New), 
                                     y = n_images, 
                                     fill = as.factor(Time_weeks))) +
  geom_bar(stat = "identity", position = "dodge") +
  facet_wrap(~Electrode_Thickness) +
  scale_fill_manual(values = Fig2$company_colors) +
  labs(
    title = "Number of Images per Bin",
    x = "Bin Number", 
    y = "Number of Images",
    fill = "Time (Weeks)"
  ) +
  theme_classic() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

print(Fig2$plot_image_counts)

# Step 10: Combined figure
if (requireNamespace("patchwork", quietly = TRUE)) {
  library(patchwork)
  
  Fig2$combined <- (Fig2$plot1 + Fig2$plot_image_counts) / Fig2$plot2 +
    plot_annotation(
      title = "Figure 2: Cell Density Analysis",
      subtitle = paste("Total images analyzed:", 
                       sum(Fig2$image_counts$n_images)),
      theme = theme(plot.title = element_text(size = 16, face = "bold", hjust = 0.5))
    )
  
  print(Fig2$combined)
}

# Step 11: Summary statistics
Fig2$summary <- list(
  total_images = n_distinct(Fig2$df_raw$ImageNumber_cell),
  images_per_time = Fig2$df_raw %>%
    group_by(Time_weeks) %>%
    summarise(n_images = n_distinct(ImageNumber_cell)),
  images_per_thickness = Fig2$df_raw %>%
    group_by(Electrode_Thickness) %>%
    summarise(n_images = n_distinct(ImageNumber_cell)),
  avg_cells_per_image = mean(Fig2$df_raw$cells_per_image_bin),
  total_cells_analyzed = sum(Fig2$df_raw$cells_per_image_bin)
)

cat("\n=== FINAL SUMMARY ===\n")
print(Fig2$summary)

# Step 12: Save results
# write.csv(Fig2$df_summary, "Fig2_density_summary.csv", row.names = FALSE)
# ggsave("Fig2_density_plot.png", Fig2$plot2, width = 10, height = 6, dpi = 300)

