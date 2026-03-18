# Microglial Morphology Analysis Pipeline

This repository contains a complete workflow for analyzing microglial morphology from imaging data following brain injury. The pipeline processes raw CellProfiler output files, performs quality control filtering, clustering, dimensionality reduction (PCA, UMAP, PHATE), and generates publication‑ready figures.

## 1. Overview

The analysis is divided into sequential R scripts, each building on the outputs of the previous one. The main steps are:

1. **Package installation and loading** – ensures all required R packages are available.
2. **Data import and preprocessing** – reads soma and cell morphology text files, merges them, adds metadata (injury coordinates, experimental conditions), and computes derived metrics (radial distance, binning, health score, etc.).
3. **Filtering and PCA** – applies outlier removal (winsorization, Mahalanobis distance), performs PCA on cleaned data, and creates diagnostic plots.
4. **Clustering and UMAP** – samples the data (stratified/random), determines optimal cluster number (k=13 by default), performs k‑means on PCA scores, assigns clusters to all cells, and runs UMAP for visualization.
5. **Figure 1** – radial bin visualizations of cell positions, faceted by time and electrode thickness.
6. **Figure 2** – validation of automated measurements against manual counts (scatter plots) and cell density analysis.
7. **Figure 3** – feature correlation heatmap, NMF rank selection, and NMF feature/cell programs.
8. **Figure 4** – PHATE analysis, UMAP with cluster centroids, cluster parameter heatmap, frequency heatmap across bins, and phenotype assignment.
9. **Figure 5** – detailed phenotype analysis, including splitting Transition clusters (T1/T2), hierarchical clustering of Transition clusters, enrichment dot plots, and frequency heatmaps across bins and time.
10. **Re‑run clustering after filtering** – removes false positive clusters (1,12) and re‑computes PCA, clustering, and UMAP on the filtered data.

All results are stored in structured lists (`import`, `Filter`, `PCA`, `ClusterAnalysis`, `ClusterAnalysis_Filter`, `Fig1`…`Fig5`) to keep the workspace organized.

---

## 2. Prerequisites

### Software
- **R** (version ≥ 4.0) and **RStudio** (recommended)
- **Python** (≥ 3.6) – required for `phateR` and `Rmagic` packages.  
  *If you do not have Python, the scripts will attempt to install it via `reticulate`, but a manual installation is safer.*

### R Packages
All required CRAN packages are listed in the first script and will be installed automatically. Additionally, the following Bioconductor and GitHub packages are used:

- `BiocManager`, `ConsensusClusterPlus`, `BiocParallel`, `ggrast`
- `ggdark`, `ggstream`, `moonBook`, `webr` (from GitHub)

**Important:** The `phateR` and `Rmagic` packages require a Python environment with the `phate` module. After running the package installation script, execute:

```r
library(reticulate)
py_install("phate", pip = TRUE)
```

Make sure your Python environment is correctly configured (see `reticulate` documentation).

### Folder Structure
Place the following folders and files as described (adjust paths in the scripts if necessary):

```
project_root/
├── scripts/                 (all R scripts)
├── Datasheet/
│   ├── df_soma/             (soma text files, one per image)
│   ├── df_cell/             (cell text files, one per image)
│   ├── Injury_Center/
│   │   └── coordinates.csv   (injury x,y per image)
│   └── validation/           (validation CSV files)
└── outputs/                  (figures and tables will be saved here)
```

The exact file paths are hard‑coded in the import script. **You must edit these paths** to match your local setup before running.

---

## 3. Step‑by‑Step Workflow

Run the scripts **in order**. Each script assumes the previous ones have been executed and the required R objects exist in the environment.

### Script 1: `00_packages.R`
- **Purpose**: Install and load all required R packages.
- **Input**: None.
- **Output**: All packages loaded into the session.
- **Note**: Run this first. If you encounter issues with `phateR`, follow the Python installation instructions above.

### Script 2: `01_data_import.R`
- **Purpose**: Read all text files, merge soma and cell data, add metadata (injury coordinates, experimental conditions), compute derived metrics (radial distance, bins, RI, area ratio, health score), and define color palettes.
- **Input**: 
  - Folder paths for soma and cell text files.
  - `coordinates.csv` (injury centers).
- **Output**: List `import` containing:
  - `df_soma`, `df_cell`, `df_all` (merged data)
  - `Injury_center`
  - `df_all_PCA` (cleaned for PCA)
  - Color palettes (`company_colors`, `morpho_colours`)
- **Check**: After running, verify `colnames(import$df_all)` to ensure all expected columns are present.

### Script 3: `02_filtering_pca.R`
- **Purpose**: Winsorize features, remove outliers via Mahalanobis distance, scale data, perform PCA, and generate QC plots.
- **Input**: `import$df_all_PCA` from previous script.
- **Output**: Lists `Filter` and `PCA`.
  - `Filter$df_clean_final` – filtered data (original scale)
  - `Filter$feat_scaled` – scaled features
  - `PCA$pca` – PCA object
  - `PCA$pca_df` – PCA scores with metadata
  - QC plots stored in `Filter` (cell count, Mahalanobis, feature distributions, etc.)
- **Note**: The script creates several diagnostic plots. Check that the outlier removal looks reasonable.

### Script 4: `03_clustering_umap.R`
- **Purpose**: Sample cells (stratified/random), run k‑means clustering (k=13 by default), assign clusters to full dataset, run UMAP, and create final data frames.
- **Input**: `Filter$meta_clean`, `Filter$feat_clean`, `PCA$pca$x`.
- **Output**: List `ClusterAnalysis` containing:
  - `final_df_sampled` – sampled cells with UMAP coordinates and clusters
  - `final_df_full` – all cells with clusters (no UMAP)
  - `summary` – sampling statistics
  - UMAP plot (base R)
- **Note**: The script automatically tries stratified, then systematic, then random sampling. You can adjust `sample_size` (default 30000).

### Script 5: `figure1.R`
- **Purpose**: Generate plots showing cell positions with radial bins, faceted by time and electrode thickness.
- **Input**: `ClusterAnalysis$final_df_full` – filtered data
- **Output**: List `Fig1` containing the main plotting function `plot_by_time_thickness()` and an example call that produces the figure used in the paper.
- **How to use**: After loading the script, run the example at the bottom (or call the function with your desired parameters). The plot will be displayed.
- **Note**: The script includes helper functions to list available images. Use `Fig1$show_images_by_time()` to see what images exist.

### Script 6: `figure2.R`
- **Purpose**: Create correlation scatter plots (manual vs. automated measurements) and cell density plots across bins and time.
- **Input**: Validation CSV files (must be present in `Datasheet/validation/`) and `ClusterAnalysis$final_df_full`.
- **Output**: List `Fig2` containing:
  - Correlation plots: `cor_area`, `cor_perimeter`, `cor_maxferet`, `cor_solidity`
  - Density plots: `plot_density_all`, `plot_density_facet`
- **Note**: The validation files are specific to this dataset. If you are using your own validation data, adjust column names accordingly.

### Script 7: `figure3.R`
- **Purpose**: Compute feature correlation matrix with modules, determine optimal NMF rank, run NMF, and generate heatmaps of feature programs and cell activity.
- **Input**: `ClusterAnalysis$final_df_full`.
- **Output**: List `Fig3` containing:
  - `heatmap_cor` – correlation heatmap with modules
  - `rank_est` and `best_rank` – NMF rank selection
  - `heatmap_W` – NMF feature programs
  - `heatmap_Ht` – program activity across cells
  - `heatmap_actual` / `heatmap_scaled` – region comparison (Close/Middle/Far)
- **Note**: The script downsamples cells for NMF (10,000 by default). Adjust `n_cells_use` if needed.

### Script 8: `figure4.R`
- **Purpose**: Run PHATE on sampled data, create UMAP with centroid labels, generate cluster parameter heatmap, frequency heatmap across bins, PHATE1 boxplot, and phenotype annotation plots.
- **Input**: `ClusterAnalysis$final_df_sampled` and `ClusterAnalysis_Filter$final_df_full`.
- **Output**: List `Fig4` containing:
  - `phate_cluster`, `phate1_boxplot` – PHATE visualizations
  - `umap_cluster` – UMAP with centroids
  - `cluster_heatmap` – z‑scored feature means per cluster
  - `pheatmap` / `pheatmap_viridis` – frequency heatmaps
  - `phenotype_heatmap` – Z‑score by phenotype
  - `phenotype_deviation` – phenotype trends across bins
- **Note**: The phenotype mapping (cluster → phenotype) is user‑defined. Adjust the `case_when` statement in the script to match your biological interpretation.

### Script 9: `figure5.R`
- **Purpose**: Refine Transition clusters into T1 and T2, perform hierarchical clustering of Transition clusters, create enrichment dot plots, and generate frequency heatmaps for T1 vs. T2 across bins and time.
- **Input**: `Fig4$df_phate_phenotype`  and `ClusterAnalysis_Filter$final_df_full` (from Script 8).
- **Output**: List `Fig5` containing:
  - `phate_2d_phenotype`, `phate_3d_interactive`
  - `dendrogram_transition_clusters` – cluster dendrogram
  - `dotplot_t1t2` – enrichment dot plot
  - `heatmap_bins` / `heatmap_time` – scaled frequency heatmaps
  - `density_phate_facet` – density maps by phenotype group
- **Note**: The definition of T1/T2 clusters is based on the cluster numbers in your data. Modify the vectors `transition_1_clusters` and `transition_2_clusters` accordingly.

---

## 4. Outputs and File Generation

All scripts store results in R lists. To save figures or tables to disk, uncomment the relevant `ggsave`, `write.csv`, or `pdf` lines. The following files are generated if you uncomment them:

- **Figure 1**: `Radial_Bins_Time_Thickness.png`
- **Figure 2**: Correlation plots (`Fig2_cor_area.png`, etc.) and density plots (`Fig2_density_all.png`, `Fig2_density_facet.png`)
- **Figure 3**: 
  - `Figure3A_Feature_Correlation_Modules.pdf`
  - `Figure3B_NMF_Feature_Programs.pdf`
  - `Figure3C_NMF_Program_Activity_per_Cell.pdf`
  - `Figure3_NMF_Rank_Selection_Highlighted.pdf`
  - `Figure3_Feature_Module_Assignments.csv`
- **Figure 4**: `Fig4_UMAP_Clusters.png`, `Fig4_PHATE_2D.png`, `Fig4_Cluster_Heatmap.png`, etc.
- **Figure 5**: `Fig5_PHATE_2D_Phenotype.png`, `Fig5_Dotplot_T1T2.png`, `Fig5_Heatmap_Bins.png`, `Fig5_Heatmap_Time.png`

All filenames can be adjusted in the scripts.

---

## 5. Customization and Troubleshooting

### Adjusting paths
All file paths are currently absolute (e.g., `/Users/...`). You must change them to match your system. Look for lines like `import$folder_path_soma <- ...` and `read_csv(...)`. Use relative paths if you place everything inside the project folder.

### Changing parameters
- **Sample size** for clustering: modify `sample_size` in Script 4.
- **Number of clusters**: change `ClusterAnalysis$optimal_k` (default 13) in Script 4 and also in the phenotype mapping.
- **Top parameters** for heatmaps: adjust `n_top` in Script 4 (cluster heatmap) and Script 5 (phenotype heatmap).
- **PHATE parameters**: `knn`, `decay`, `gamma`, etc. can be tuned in Script 8.

### Common issues

1. **`phate` Python module not found**  
   Run:  
   ```r
   library(reticulate)
   py_install("phate", pip = TRUE)
   ```
   If you use a virtual environment, ensure `use_virtualenv()` points to the correct one (as in Script 8).

2. **Memory errors during NMF**  
   The NMF step downsamples to 10,000 cells. If you have a very large dataset, you may need to reduce this further. Adjust `n_cells_use` in Script 7.

3. **Missing columns**  
   Some scripts assume specific column names (e.g., `Cluster`, `UMAP1`, `PHATE1_2D`). If you modified earlier steps, ensure these columns exist.

4. **Package conflicts**  
   If you see errors like “function X is masked”, restart your R session and run the scripts in order without loading other packages manually.

---

## 6. Citation

If you use this pipeline in your research, please cite:

(MicroFace (2026))

---

## 7. Contact

For questions or issues, please contact vatsjari@gmail.com or open an issue on the GitHub repository.

