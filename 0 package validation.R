##### CHECK FOR THE PACKAGES AND INSTALL IF NOT AVAILABLE #####

packages <- list()


packages$my_packages <- c("readr", "plyr", "readxl", "dplyr", "factoextra", "cluster", "readxl"
                 , "tidyverse", "corrplot", "dataRetrieval", "dplyr", "tidyr", "ggplot2", "rsq"
                 , "ggpmisc", "writexl", "Biobase", "cluster", "BiocManager", "ConsensusClusterPlus", "pheatmap", "vroom", "ggforce", "plotrix",
                 "moments", "Seurat", "patchwork", "clusterSim", "tidymodels", "recipes", "tidytext", "embed", "corrr", "viridis", "randomForest", "BiocParallel", "pheatmap",
                 "dendextend", "RColorBrewer", "dendsort", "ape", "BBmisc", "ggExtra", "fmsb", "GGally", "gghighlight", "wesanderson","remotes", "ggstream", "devtools", "ggdark",
                  "streamgraph", "reshape2", "cardiomoon/moonBook","cardiomoon/webr")                                        # Specify your packages
packages$not_installed <- packages$my_packages[!(packages$my_packages %in% installed.packages()[ , "Package"])]    # Extract not installed packages
if(length(packages$not_installed)) install.packages(packages$not_installed)   

##### BIOCONDUCTOR BASED PACKAGES #####


if (!require("BiocManager", quietly = TRUE))
  install.packages("BiocManager")
BiocManager::install(version = "3.16")

BiocManager::install("ConsensusClusterPlus")
BiocManager::install("BiocParallel")
BiocManager::install("ggbiplot")

devtools::install_github("nsgrantham/ggdark")
remotes::install_github("davidsjoberg/ggstream")
devtools::install_github("hrbrmstr/streamgraph")

devtools::install_github("cardiomoon/moonBook")
devtools::install_github("cardiomoon/webr")

##### LOAD ALL THE PACKAGES AT ONCE #####
lapply(packages$my_packages, require, character.only = TRUE)
 

