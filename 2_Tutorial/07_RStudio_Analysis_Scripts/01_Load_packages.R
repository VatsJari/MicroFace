# ============================================================================
# Package Management Script for RStudio Project
# ============================================================================
# This script checks for required packages, installs missing ones from CRAN,
# Bioconductor, and GitHub, and then loads all packages for use.
# ============================================================================

##### 1. CHECK FOR CRAN PACKAGES AND INSTALL IF NOT AVAILABLE #####

# List of required CRAN packages (original list + additional packages from user code)
packages <- list()
packages$my_packages <-  c(
  "dplyr", "MASS", "gridExtra", "ggplot2", "patchwork", "ClusterR", "factoextra",
  "umap", "RColorBrewer", "cluster", "ggrepel", "uwot", "readxl", "ggpubr",
  "cowplot", "corrplot", "readr", "pheatmap", "NMF", "viridis", "reshape2",
  "reticulate", "phateR", "Rmagic", "dendsort", "plotly", "vroom", "tidyr",
  "stringr", "scales", "Seurat")
# Identify packages that are not yet installed
packages$not_installed <- packages$my_packages[!(packages$my_packages %in% installed.packages()[ , "Package"])]

# Install missing CRAN packages (if any)
if(length(packages$not_installed)) install.packages(packages$not_installed)


##### 2. BIOCONDUCTOR SETUP AND PACKAGE INSTALLATION #####

# Ensure BiocManager is installed and set to version 3.17
if (!require("BiocManager", quietly = TRUE))
  install.packages("BiocManager")
BiocManager::install(version = "3.17")


##### 4. LOAD ALL PACKAGES AT ONCE #####

# Load every package listed in my_packages (including duplicates)
lapply(packages$my_packages, require, character.only = TRUE)

# Note: Some packages installed from Bioconductor or GitHub (e.g., ggrast, ggdark, ggstream, moonBook, webr)
# are not included in the loading loop because they were added after the initial list.
# Load them manually if needed in subsequent scripts.

