# Install required packages if not already installed
if (!require(viridis)) install.packages("viridis")
if (!require(ggplot2)) install.packages("ggplot2")
if (!require(readr)) install.packages("readr")
if (!require(Rmagic)) install.packages("Rmagic")

# Load libraries
library(viridis)
library(ggplot2)
library(readr)
library(Rmagic)
library(phateR)

Phate_map_git <- list()

# Filter data for Bin_Number_New <= 16
Phate_map_git$df_phate <- Morpho_git$df_clust_all[which(Morpho_git$df_clust_all$Bin_Number_New <= 16), ]

# Define Phenotype groups based on Morpho codes
Phate_map_git$df_phate$Phenotype <- ifelse(
  Phate_map_git$df_phate$Morpho %in% c("M01","M02", "M10", "M07"), "Transition",
  ifelse(
    Phate_map_git$df_phate$Morpho %in% c("M12", "M13", "M14", "M06", "M05", "M04", "M03"), "Ramified",
    ifelse(
      Phate_map_git$df_phate$Morpho %in% c("M08", "M09", "M11"), "Ameboid",
      NA
    )
  )
)

# Normalize data: square root transform (columns 1 to 48 assumed numeric features)
Phate_map_git$df_phate_norm <- sqrt(Phate_map_git$df_phate[, 1:48])

# PCA on normalized data
Phate_map_git$df_phate_PCA <- as.data.frame(prcomp(Phate_map_git$df_phate_norm)$x)

# PCA plot colored by 'Mpo' column (assumed in original df)
Phate_map_git$PCA_plot <- ggplot(Phate_map_git$df_phate_PCA) +
  geom_point(aes(x = PC1, y = PC2, color = Phate_map_git$df_phate$Mpo)) +
  labs(color = "Mpo") +
  scale_color_manual(values = company_colors) # make sure company_colors is defined

plot(Phate_map_git$PCA_plot)

# Run PHATE embedding on normalized data
Phate_map_git$PHATE <- phate(Phate_map_git$df_phate_norm)

# PHATE plot colored by Phenotype
ggplot(data = as.data.frame(Phate_map_git$PHATE$embedding), aes(x = PHATE1, y = PHATE2)) +
  geom_point(aes(color = Phate_map_git$df_phate$Phenotype), alpha = 1, size = 0.5) +
  labs(color = "Phenotype") +
  scale_color_manual(values = phenotype_color) + # make sure phenotype_color is defined
  theme_void()
