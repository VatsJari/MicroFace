##### SECTION 1: INITIALIZATION #####

Meta <- list()

# Path to folder containing metadata text files
Meta$meta_df_path = "/Users/vatsaljariwala/Documents/Brain Injury project/4 Datasheet/Metadata"

# List of all .txt files in the metadata folder
Meta$list_of_files <- list.files(
  path = Meta$meta_df_path,
  recursive = TRUE,
  pattern = "*.txt",
  full.names = TRUE
)

##### SECTION 2: LOAD & COMBINE DATA FILES #####

# Read and combine all metadata files into one dataframe
file_list <- lapply(Meta$list_of_files, function(file) {
  vroom(file, col_select = 1:30, .name_repair = "minimal") %>%
    mutate(FileName = file)
})

Meta$df_meta <- bind_rows(file_list)

##### SECTION 3: EXTRACT IDENTIFIERS & CLEAN FIELDS #####

Meta$df_meta <- Meta$df_meta %>%
  mutate(
    Animal_ID = sub("_.*", "", FileName_Original_Iba1),
    probe_size = sub(".*?(\\d+um).*", "\\1", FileName),
    WPI = ifelse(grepl("Acute", FileName), "Acute", sub(".*_(\\d+WPI)_.*", "\\1", FileName)),
    filename_cleaned = ifelse(grepl("Acute", FileName), "Acute", sub(".*?\\d+um_(\\d+WPI)_.*", "\\1", FileName))
  )

##### SECTION 4: SUMMARY - UNIQUE ANIMALS PER WPI #####

Meta$df_processed <- Meta$df_meta[, c(2, 33:35)]

Meta$df_summary <- Meta$df_processed %>%
  group_by(WPI, probe_size) %>%
  summarise(total_animals = n_distinct(Animal_ID), .groups = "drop") %>%
  group_by(WPI) %>%
  summarise(total_animals = sum(total_animals), .groups = "drop")

Meta$df_summary$WPI <- factor(Meta$df_summary$WPI, levels = c("Acute", "1WPI", "2WPI", "8WPI", "18WPI"))

##### SECTION 5: COUNT CELLS PER ANIMAL #####

Meta$df_summary_counts <- Meta$df_processed %>%
  group_by(Animal_ID, WPI, probe_size) %>%
  summarise(total_count_cell = sum(Count_Cell, na.rm = TRUE), .groups = "drop") %>%
  mutate(
    WPI = factor(WPI, levels = c("Acute", "1WPI", "2WPI", "8WPI", "18WPI")),
    animal_symbol = row_number()
  ) %>%
  arrange(WPI)

##### SECTION 6: TOTAL CELL COUNT PER WPI (BAR PLOT) #####

Meta$df_summary_wpi <- Meta$df_summary_counts %>%
  group_by(WPI) %>%
  summarise(total_count_cell = sum(total_count_cell, na.rm = TRUE), .groups = "drop")

ggplot(Meta$df_summary_wpi, aes(x = WPI, y = total_count_cell, fill = WPI)) +
  geom_bar(stat = "identity", color = "black") +
  scale_fill_manual(values = company_colors) +
  labs(title = "Total Count_Cell per WPI", x = "WPI", y = "Total Count_Cell") +
  theme_minimal() +
  theme(
    axis.text.x = element_text(size = 10, face = "bold"),
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
    legend.position = "none"
  )

##### SECTION 7: MERGE MORPHOLOGY DATA #####

Meta$Morpho_df <- Morpho$df_clust_all_count

Meta$df_meta_2 <- Meta$df_meta[, c(27, 33:35)]

Meta$df_meta_3 <- Meta$df_summary_counts %>%
  left_join(Meta$df_meta_2 %>% dplyr::select(ImageNumber, Animal_ID, probe_size, WPI),
            by = c("probe_size", "Animal_ID", "WPI"))

# Add formatted 'Condition' field
Meta$df_meta_3 <- Meta$df_meta_3 %>%
  mutate(
    probe_size = sprintf("%02d", as.numeric(gsub("um", "", probe_size))),
    WPI = sprintf("%02d", as.numeric(ifelse(WPI == "Acute", "00", gsub("WPI", "", WPI)))),
    Condition = paste(probe_size, WPI, sep = "_")
  )

Meta$df_meta_4 <- Meta$df_meta_3[, c(1, 5:7)]

# Final join with morphology
Meta$df_meta_morpho <- Meta$Morpho_df %>%
  left_join(Meta$df_meta_4 %>% dplyr::select(ImageNumber, Animal_ID, animal_symbol, Condition),
            by = c("Condition_cell" = "Condition", "ImageNumber_cell" = "ImageNumber"))

Meta$df_meta_morpho_final <- Meta$df_meta_morpho[, 49:60]

##### SECTION 8: PHENOTYPE CATEGORIZATION #####

Meta$df_meta_morpho_final$Phenotype <- ifelse(
  Meta$df_meta_morpho_final$Morpho %in% c("M01", "M02", "M10", "M07"), "Transition",
  ifelse(Meta$df_meta_morpho_final$Morpho %in% c("M12", "M13", "M14", "M06", "M05", "M04", "M03"), "Ramified",
         ifelse(Meta$df_meta_morpho_final$Morpho %in% c("M08", "M09", "M11"), "Ameboid", NA))
)

##### SECTION 9: PIE CHART - ANIMAL DISTRIBUTION #####

ggplot(Meta$df_summary, aes(x = "", y = total_animals, fill = WPI)) +
  geom_bar(stat = "identity", width = 1, color = "white") +
  coord_polar("y", start = 0) +
  scale_fill_manual(values = company_colors) +
  labs(x = "", y = "Number of animals") +
  geom_text(aes(label = paste(total_animals)), position = position_stack(vjust = 0.5), size = 7, fontface = "bold", color = "white") +
  theme_void() +
  theme(
    legend.position = "right",
    legend.text = element_text(size = 9, face = "bold"),
    legend.title = element_text(size = 10, face = "bold")
  )

##### SECTION 10: BAR PLOT - CELL COUNTS PER ANIMAL #####

Meta$cell_counts_summary <- Meta$df_meta_morpho_final %>%
  group_by(animal_symbol, Time_weeks) %>%
  summarise(cell_count = n())
Meta$average_count_cell <- mean(Meta$df_summary_counts$total_count_cell, na.rm = TRUE)

ggplot(Meta$cell_counts_summary, aes(x = as.factor(animal_symbol), y = cell_count, fill = Time_weeks)) +
  geom_bar(stat = "identity", color = "white") +
  geom_hline(yintercept = Meta$average_count_cell, linetype = "dashed", color = "black", size = 1) +
  labs(
    title = "Total Segmentation per Animal",
    subtitle = paste("Average segmentation count across animals:", round(Meta$average_count_cell, 1)),
    x = "Animal ID", y = "Number of Segmentation"
  ) +
  scale_fill_manual(values = company_colors) +
  theme_bw() +
  theme(
    axis.text.x = element_text(size = 10, angle = 90, hjust = 1, vjust = 0.5),
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 12, face = "italic", hjust = 0.5)
  )

##### SECTION 11: PHENOTYPE PROPORTIONS PER TIME POINT #####

Meta$cluster_summary <- Meta$df_meta_morpho_final %>%
  group_by(animal_symbol, Morpho, Time_weeks) %>%
  summarise(cell_count = n(), .groups = "drop") %>%
  group_by(Time_weeks) %>%
  mutate(proportion = cell_count / sum(cell_count))

ggplot(Meta$cluster_summary, aes(x = as.factor(animal_symbol), y = proportion, fill = Morpho)) +
  geom_bar(stat = "identity", position = "fill") +
  scale_fill_manual(values = morpho_colours) +
  labs(
    title = "Proportion of Morpho-types per Time-point",
    x = "Animal ID", y = "Proportion of Morpho-types"
  ) +
  theme_bw()

ggplot(Meta$cluster_summary, aes(x = as.factor(Time_weeks), y = proportion, fill = Morpho)) +
  geom_bar(stat = "identity", position = "fill") +
  scale_fill_manual(values = morpho_colours) +
  labs(
    title = "Proportion of Morpho-types per Time-point",
    x = "Time points", y = "Proportion of Morpho-types"
  ) +
  theme_bw()

##### SECTION 12: PHENOTYPE PROPORTIONS OVER TIME #####

Meta$Phenotype_summary <- Meta$df_meta_morpho_final %>%
  group_by(Time_weeks, Phenotype) %>%
  summarise(cell_count = n(), .groups = "drop") %>%
  group_by(Phenotype) %>%
  mutate(proportion = cell_count / sum(cell_count))

ggplot(Meta$Phenotype_summary, aes(x = as.factor(Time_weeks), y = proportion, fill = Phenotype)) +
  geom_bar(stat = "identity", position = "fill") +
  scale_fill_manual(values = phenotype_color) +
  labs(
    title = "Proportion of Morpho-types per Animal",
    x = "WPI", y = "Proportion of Morpho-types"
  ) +
  theme_bw()

