# ===================================================
# PACKAGE MANAGEMENT SYSTEM
# Description: Checks, installs, and loads all required packages
# ===================================================

# Define package groups
packages <- list(
  # CRAN packages
  cran = c(
    # Data I/O
    "readr", "readxl", "writexl", "vroom",
    
    # Data manipulation
    "dplyr", "tidyr", "plyr", "reshape2",
    
    # Visualization
    "ggplot2", "patchwork", "cowplot", "ggforce", 
    "plotrix", "ggExtra", "fmsb", "GGally", 
    "gghighlight", "wesanderson", "ggstream",
    "viridis", "corrplot", "pheatmap",
    
    # Analysis
    "factoextra", "cluster", "clusterSim", "moments",
    "randomForest", "corrr", "ape", "dendextend",
    "dendsort", "Rmagic", "phateR",
    
    # Utilities
    "remotes", "devtools", "parallel", "BBmisc",
    "rsq", "ggpmisc", "tidytext", "embed"
  ),
  
  # Bioconductor packages
  bioc = c(
    "Biobase", "ConsensusClusterPlus", 
    "BiocParallel", "ggrast"
  ),
  
  # GitHub packages
  github = c(
    "nsgrantham/ggdark",
    "davidsjoberg/ggstream",
    "hrbrmstr/streamgraph",
    "cardiomoon/moonBook",
    "cardiomoon/webr"
  )
)

# ===================================================
# 1. INSTALLATION SECTION
# ===================================================

# Function to install missing packages
install_missing <- function(pkg_list, source = "cran") {
  if(source == "cran") {
    missing_pkgs <- pkg_list[!pkg_list %in% installed.packages()[,"Package"]]
    if(length(missing_pkgs) > 0) {
      install.packages(missing_pkgs)
    }
  }
  else if(source == "bioc") {
    if (!require("BiocManager", quietly = TRUE)) {
      install.packages("BiocManager")
    }
    BiocManager::install(version = "3.17")
    missing_pkgs <- pkg_list[!pkg_list %in% installed.packages()[,"Package"]]
    if(length(missing_pkgs) > 0) {
      BiocManager::install(missing_pkgs)
    }
  }
  else if(source == "github") {
    lapply(pkg_list, function(pkg) {
      if(!require(basename(pkg), character.only = TRUE)) {
        devtools::install_github(pkg)
      }
    })
  }
}

# Install from all sources
install_missing(packages$cran, "cran")
install_missing(packages$bioc, "bioc")
install_missing(packages$github, "github")

# ===================================================
# 2. LOADING SECTION
# ===================================================

# Load all packages with error handling
load_packages <- function(pkg_list) {
  suppressPackageStartupMessages({
    lapply(pkg_list, function(pkg) {
      if(!require(pkg, character.only = TRUE, quietly = TRUE)) {
        warning(paste("Package", pkg, "failed to load"))
      }
    })
  })
}

# Load CRAN and Bioconductor packages
load_packages(c(packages$cran, packages$bioc))

# ===================================================
# 3. VERIFICATION SECTION
# ===================================================

# Check which packages failed to load
loaded <- sapply(c(packages$cran, packages$bioc), 
                 function(pkg) requireNamespace(pkg, quietly = TRUE))

if(!all(loaded)) {
  warning("The following packages failed to load: \n",
          paste(names(loaded)[!loaded], collapse = "\n"))
}

# Print session info for reproducibility
cat("\n===== SESSION INFO =====\n")
sessionInfo()
