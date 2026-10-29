# ============================================================================
# SUPPLEMENTARY FIGURE S6: Animal-level metadata and cluster/phenotype proportions
# ============================================================================
# This script uses data from ClusterAnalysis_filtered and produces:
#   1. Animal-level summaries (counts of animals per time point, cells per image/animal)
#   2. Pie chart of animal distribution by time point
#   3. Bar plot of cell counts per animal (coloured by time point)
#   4. Stacked bar plots of cluster proportions per animal (faceted by time)
#   5. Stacked bar plots of phenotype proportions per animal (faceted by time)
#   6. Stacked bar plot of cluster proportions per file (with facet by time)
# All outputs are stored in the list 'Fig_S6'.
# ============================================================================

# Initialize the list
Fig_S6 <- list()

# ----------------------------------------------------------------------------
# 1. Prepare the main dataframe (from ClusterAnalysis_filtered)
# ----------------------------------------------------------------------------
if (!exists("Fig4") || is.null(Fig4$df_phate_phenotype)) {
  stop("Fig4$df_phate_phenotype not found. Please run Figure 4 script first.")
}

Fig_S6$df_processed <- Fig4$df_phate_phenotype
colnames(Fig_S6$df_processed)

# ----------------------------------------------------------------------------
# 2. Create unique Animal_ID based on Animal_No, Time_weeks, Electrode_Thickness
# ----------------------------------------------------------------------------
Fig_S6$df_processed <- Fig_S6$df_processed %>%
  group_by(Animal_No, Time_weeks, Electrode_Thickness) %>%
  mutate(Animal_ID = cur_group_id()) %>%
  ungroup()

# ----------------------------------------------------------------------------
# 3. Summarise total animals per time point (ignoring probe size)
# ----------------------------------------------------------------------------
# Step 1: Group by Time_weeks and Electrode_Thickness to count distinct animals
Fig_S6$df_summary <- Fig_S6$df_processed %>%
  group_by(Time_weeks, Electrode_Thickness) %>%
  summarise(
    total_animals = n_distinct(Animal_No),  # Count unique Animal_No
    .groups = "drop"
  )

# Step 2: Sum across probe sizes to get total animals per time point
Fig_S6$df_summary <- Fig_S6$df_summary %>%
  group_by(Time_weeks) %>%
  summarise(
    total_animals = sum(total_animals),  # Sum across all probe sizes
    .groups = "drop"
  )

# ----------------------------------------------------------------------------
# 4. Create image-level summary: cells per image, animal, time, electrode, sub‑image
# ----------------------------------------------------------------------------
Fig_S6$image_summary <- Fig_S6$df_processed %>%
  group_by(FileName_Original_Iba1_cell, Time_weeks, Electrode_Thickness, SubImage, Animal_ID) %>%
  summarise(number_of_cells = n(), .groups = "drop")

# Write to CSV (side effect – not stored in list)
#write_csv(Fig_S6$image_summary, path = "/Users/vatsaljariwala/Documents/Brain Injury project/Revised_Submission/Datasheet/Meta_data_file/Metadata.csv" )

# ----------------------------------------------------------------------------
# 5. Average cells per animal (sum over all images)
# ----------------------------------------------------------------------------
Fig_S6$avg_cells_per_animal <- Fig_S6$image_summary %>%
  group_by(Animal_ID) %>%
  summarise(
    avg_cells = sum(number_of_cells),
    total_images = n(),
    .groups = "drop"
  )

#write_csv(Fig_S6$avg_cells_per_animal, path = "/Users/vatsaljariwala/Documents/Brain Injury project/Revised_Submission/Datasheet/Meta_data_file/Metadata_per_animal.csv" )

# ----------------------------------------------------------------------------
# 6. Pie chart of animal distribution across time points
# ----------------------------------------------------------------------------
Fig_S6$pie_animal_time <- ggplot(Fig_S6$df_summary, aes(x = "", y = total_animals, fill = Time_weeks)) +
  geom_bar(stat = "identity", width = 1, color = "white") +
  coord_polar("y", start = 0) +
  scale_fill_manual(values = company_colors) +
  labs(
    x = "",
    y = "Number of animals"
  ) +
  geom_text(
    aes(label = paste(total_animals)), 
    position = position_stack(vjust = 0.5), 
    size = 7, 
    fontface = "bold",
    color = "white"
  ) +
  theme_void() +
  theme(
    axis.title.y = element_text(size = 12, face = "bold"),
    axis.text.x = element_text(size = 0, face = "bold"),
    axis.text.y = element_text(size = 0, face = "bold"),
    legend.text = element_text(size = 9, face = "bold"),
    legend.title = element_text(size = 10, face = "bold"),
    legend.key.size = unit(1, "lines"),
    legend.position = "right",
  )
print(Fig_S6$pie_animal_time)

# ----------------------------------------------------------------------------
# 7. Bar plot of cell counts per animal (coloured by time point)
# ----------------------------------------------------------------------------
Fig_S6$cell_counts <- Fig_S6$df_processed %>%
  group_by(Animal_ID, Time_weeks) %>%
  summarise(cell_count = n(), .groups = "drop")

# Ensure Time_weeks is factor with correct order
Fig_S6$cell_counts$Time_weeks <- factor(Fig_S6$cell_counts$Time_weeks,
                                        levels = c("00WPI", "01WPI", "02WPI", "08WPI", "18WPI"))

# Arrange for plotting
Fig_S6$cell_counts <- Fig_S6$cell_counts %>%
  arrange(Time_weeks, desc(cell_count)) %>%
  mutate(Animal_ID = factor(Animal_ID, levels = unique(Animal_ID)))

# Bar plot
Fig_S6$gg_cell_counts <- ggplot(Fig_S6$cell_counts, aes(x = Animal_ID, y = 10*cell_count, fill = Time_weeks)) +
  geom_col(width = 0.5) +
  scale_fill_manual(values = company_colors) +
  labs(x = "Animal ID", y = "Number of cells", fill = "Time point") +
  theme_classic() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 6)) +
  guides(fill = "none")   # hide legend if desired; remove to keep
print(Fig_S6$gg_cell_counts)

# ----------------------------------------------------------------------------
# 8. Cluster proportions per animal, faceted by Time_weeks
# ----------------------------------------------------------------------------
# Use Animal_ID factor ordering from cell_counts
animal_order <- levels(Fig_S6$cell_counts$Animal_ID)
Fig_S6$df_processed$Animal_ID <- factor(Fig_S6$df_processed$Animal_ID, levels = animal_order)

Fig_S6$cluster_props <- Fig_S6$df_processed %>%
  group_by(Animal_ID, Time_weeks, Cluster) %>%
  summarise(count = n(), .groups = "drop_last") %>%   # drop_last keeps Animal_ID grouping
  mutate(prop = count / sum(count) * 100) %>%         # proportion within each animal
  ungroup()

Fig_S6$cluster_props$Cluster <- as.factor(Fig_S6$cluster_props$Cluster)

Fig_S6$gg_cluster_props <- ggplot(Fig_S6$cluster_props, 
                                  aes(x = Animal_ID, y = prop, fill = Cluster)) +
  geom_col(position = "stack", width = 0.7) +
  # facet_wrap(~Time_weeks) +   # uncomment if faceting desired
  scale_fill_manual(values = morpho_colours) +
  labs(x = "Animal ID", y = "Proportion of cells (%)", fill = "Cluster") +
  theme_classic() +
  guides(fill = guide_legend(ncol = 13)) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 6),
        strip.background = element_blank(),
        strip.text = element_text(size = 10, face = "bold"),
        legend.position = "top")
print(Fig_S6$gg_cluster_props)

# ----------------------------------------------------------------------------
# 9. Phenotype proportions per animal, faceted by Time_weeks
# ----------------------------------------------------------------------------
Fig_S6$phenotype_props <- Fig_S6$df_processed %>%
  group_by(Animal_ID, Time_weeks, Phenotype) %>%
  summarise(count = n(), .groups = "drop_last") %>%
  mutate(prop = count / sum(count) * 100) %>%
  ungroup()

Fig_S6$phenotype_props$Phenotype <- as.factor(Fig_S6$phenotype_props$Phenotype)

Fig_S6$gg_phenotype_props <- ggplot(Fig_S6$phenotype_props, 
                                    aes(x = Animal_ID, y = prop, fill = Phenotype)) +
  geom_col(position = "stack", width = 0.7) +
  # facet_wrap(~Time_weeks) +   # uncomment if faceting desired
  scale_fill_manual(values = pheno_colors) +
  labs(x = "Animal ID", y = "Proportion of cells (%)", fill = "Phenotype") +
  theme_classic() +
  guides(fill = guide_legend(ncol = 13)) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 6),
        strip.background = element_blank(),
        strip.text = element_text(size = 10, face = "bold"),
        legend.position = "top")
print(Fig_S6$gg_phenotype_props)


# ----------------------------------------------------------------------------
# 11. Summary of stored objects
# ----------------------------------------------------------------------------
cat("\n=== FIG_S6 COMPLETE ===\n")
cat("All results stored in list 'Fig_S6'.\n")
cat("Contents:\n")
print(names(Fig_S6))

# ============================================================================
# End of Supplementary Figure S6 script
# ============================================================================