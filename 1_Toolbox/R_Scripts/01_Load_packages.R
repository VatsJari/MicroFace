# ============================================================================
# Package Management Script for RStudio Project
# ============================================================================
# This script checks for required packages, installs missing ones from CRAN,
# and then loads all packages for use.
#
# Every package the MicroFace analysis scripts call is on CRAN. No step of
# this workflow uses a Bioconductor package, so no Bioconductor setup is
# needed. Mahalanobis distance, PCA and k-means are computed with stats::
# functions from base R.
# ============================================================================

##### 1. CHECK FOR CRAN PACKAGES AND INSTALL IF NOT AVAILABLE #####

# List of required CRAN packages.
# The first block is called directly by scripts 02 to 05; the second block is
# loaded for convenience and for user extensions of the analysis.
packages <- list()
packages$my_packages <- c(
  # called directly by 02_Import_Data.R to 05_Morpho_Enrichment.R
  "vroom", "dplyr", "tidyr", "tibble",
  "ggplot2", "patchwork", "scales", "ggrepel",
  "gridExtra", "RColorBrewer", "uwot",
  # available for extending the analysis
  "ClusterR", "factoextra", "umap", "cluster", "readxl", "ggpubr",
  "cowplot", "corrplot", "readr", "pheatmap", "NMF", "viridis",
  "plotly", "stringr")

# Identify packages that are not yet installed
packages$not_installed <- packages$my_packages[!(packages$my_packages %in% installed.packages()[ , "Package"])]

# Install missing CRAN packages (if any)
if (length(packages$not_installed)) install.packages(packages$not_installed)


##### 2. LOAD ALL PACKAGES AT ONCE #####

# Load every package listed in my_packages
invisible(lapply(packages$my_packages, require, character.only = TRUE))
