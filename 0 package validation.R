##### CHECK FOR THE PACKAGES AND INSTALL IF NOT AVAILABLE #####

my_packages <- c("readr", "plyr", "readxl", "dplyr", "factoextra", "cluster", "readxl"
                 , "tidyverse", "corrplot", "dataRetrieval", "dplyr", "tidyr", "ggplot2", "rsq"
                 , "ggpmisc", "writexl", "Biobase", "cluster", "BiocManager", "ConsensusClusterPlus", "pheatmap", "vroom", "ggforce", "plotrix",
                 "moments", "Seurat", "patchwork", "clusterSim", "tidymodels", "recipes", "tidytext", "embed", "corrr", "viridis", "randomForest", "BiocParallel", "pheatmap",
                 "dendextend", "RColorBrewer", "dendsort", "ape")                                        # Specify your packages
not_installed <- my_packages[!(my_packages %in% installed.packages()[ , "Package"])]    # Extract not installed packages
if(length(not_installed)) install.packages(not_installed)   

##### BIOCONDUCTOR BASED PACKAGES #####


if (!require("BiocManager", quietly = TRUE))
  install.packages("BiocManager")

BiocManager::install("ConsensusClusterPlus")
BiocManager::install("BiocParallel")
BiocManager::install("ggbiplot")

##### LOAD ALL THE PACKAGES AT ONCE #####
lapply(my_packages, require, character.only = TRUE)
 

