# Create a list to store validation plots
validation <- list()

# Load validation data
validation$data <- read_excel("/Users/vatsaljariwala/Documents/Brain Injury project/4 Datasheet/Validation.xlsx")

# -------------------------------
# 1. COMPARE NUMBER OF TRUNKS
# -------------------------------

validation$trunk <- ggplot(validation$data, aes(x = ObjectSkeleton_NumberTrunks_MorphologicalSkeleton, 
                                                y = Manual_Trunk)) +
  geom_point(size = 2, color = 'blue') +
  geom_jitter(size = 2, width = 0.5, colour = 'blue') +
  geom_smooth(method = "lm", se = TRUE, color = 'green') +
  ggpubr::stat_cor(method = "pearson", color = 'black') +
  labs(x = "", y = "Manual Analysis") +
  ggtitle("Trunk Branches") +
  theme_classic() +
  theme(
    plot.title = element_text(size = 12, hjust = 0.5, face = "bold"),
    axis.title.x = element_text(size = 12, face = "bold"),
    axis.title.y = element_text(size = 12, face = "bold"),
    axis.text.x  = element_text(size = 10, face = "bold"),
    axis.text.y  = element_text(size = 10, face = "bold")
  )

print(validation$trunk)

# -------------------------------
# 2. COMPARE NUMBER OF NON-TRUNKS
# -------------------------------

validation$non_trunk <- ggplot(validation$data, aes(x = ObjectSkeleton_NumberNonTrunkBranches_MorphologicalSkeleton, 
                                                    y = Manual_Non_Trunk)) +
  geom_point(size = 2, color = 'blue') +
  geom_jitter(size = 2, width = 5, colour = 'blue') +
  geom_smooth(method = "lm", se = TRUE, color = 'green') +
  ggpubr::stat_cor(method = "pearson", color = 'black') +
  labs(x = "MicroFace", y = "") +
  ggtitle("Non-Trunk Branches") +
  theme_classic() +
  theme(
    plot.title = element_text(size = 12, hjust = 0.5, face = "bold"),
    axis.title.x = element_text(size = 12, face = "bold"),
    axis.title.y = element_text(size = 12, face = "bold"),
    axis.text.x  = element_text(size = 10, face = "bold"),
    axis.text.y  = element_text(size = 10, face = "bold")
  )

print(validation$non_trunk)

# -------------------------------
# 3. COMPARE AREA MEASUREMENT
# -------------------------------

validation$area <- ggplot(validation$data, aes(x = AreaShape_Area, 
                                               y = Manual_Area)) +
  geom_point(size = 2, color = 'blue') +
  geom_jitter(size = 2, width = 5, colour = 'blue') +
  geom_smooth(method = "lm", se = TRUE, color = 'green') +
  ggpubr::stat_cor(method = "pearson", color = 'black') +
  labs(x = "", y = "") +
  ggtitle("Area") +
  theme_classic() +
  theme(
    plot.title = element_text(size = 12, hjust = 0.5, face = "bold"),
    axis.title.x = element_text(size = 12, face = "bold"),
    axis.title.y = element_text(size = 12, face = "bold"),
    axis.text.x  = element_text(size = 10, face = "bold"),
    axis.text.y  = element_text(size = 10, face = "bold")
  )

print(validation$area)

# -------------------------------
# 4. COMBINED PLOT OUTPUT
# -------------------------------

plot_grid(validation$trunk, validation$non_trunk, validation$area, ncol = 3)
