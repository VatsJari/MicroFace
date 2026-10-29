# Data analysis

R workflow that turns the CellProfiler feature tables from
`../Image processing analysis/` into filtered, dimensionality-reduced,
clustered single-cell morphology data, and then into the published figures.

Run `../Image processing analysis/` first.

---

## 1. How this works

The scripts are **sequential and share one R session**. Each builds on objects
left in the environment by the previous one, so they cannot be run in
isolation or out of order. Results accumulate in named lists (`import`,
`Filter`, `PCA`, `ClusterAnalysis`, `Fig1` ... `Fig5`, `Fig_S6` ...) to keep the
workspace navigable.

Open `Scripts/TBI_Manuscript.Rproj` in RStudio, then run in this order:

| Order | Script | Produces |
|-------|--------|----------|
| 1 | `01_Load_packages.R` | dependencies installed and loaded |
| 2 | `02_Import_Data.R` | `import$df_all`, `import$df_all_PCA` |
| 3 | `03_Wins_Filtering_PCA.R` | `Filter$...`, `PCA$...` |
| 4 | `04_Clustering_UMAP.R` | `ClusterAnalysis$final_df_full`, `$final_df_sampled` |
| 5 | `Figure_1.R` ... `Figure_S8.R` | published figures |

The figure scripts depend on steps 1 to 4 but are independent of each other,
with two exceptions: `Figure_5.R` consumes `Fig4$df_phate_phenotype`, and
`Figure_S6.R` / `Figure_S8.R` reference upstream `Fig4` objects. So run
`Figure_4.R` before 5, S6 and S8.

---

## 2. Before you run anything

### Edit the file paths

**Every path in these scripts is absolute and points at the original author's
machine.** Nothing will run until you change them. The lines to edit:

| Script | Variable or call | Points at |
|--------|------------------|-----------|
| `02_Import_Data.R` | `import$folder_path_soma` | folder of per-image soma tables |
| `02_Import_Data.R` | `import$folder_path_cell` | folder of per-image cell tables |
| `02_Import_Data.R` | `read_csv(...)` for `import$Injury_center` | `Datasheet/Injury_Center/coordinates.csv` |
| `Figure_2.R` | three `read_csv(...)` calls | `Datasheet/validation/*.csv` |

If you place your data inside the project folder, relative paths work and are
preferable, since they survive being moved between machines.

### Get the input data

Scripts from step 2 onward expect **two folders of per-image CellProfiler
output**, one table per image:

```
Datasheet/
├── df_soma/     one soma table per image
├── df_cell/     one cell table per image
├── Injury_Center/coordinates.csv      (provided)
├── Meta_data_file/                    (provided, see note below)
└── validation/                        (provided)
```

`df_soma/` and `df_cell/` are **not in this repository** because of size. Either
generate them yourself by running `The_Skeleton_Pipeline.cpproj` on your images,
or obtain the deposited tables from the data archive accompanying the paper.

The two files in `Meta_data_file/` are **outputs, not inputs**. They are
animal-level and image-level summaries written by `Figure_S6.R` (the write calls
are commented out) and are shipped here as a reference for what that script
should reproduce. Nothing reads them.

### Filenames must follow the naming contract

`02_Import_Data.R` recovers all experimental metadata by splitting the image
filename on underscores into exactly **six** fields:

```
R10_4hpi_16_Iba1_1_FilteredSubtracted.tif
 |    |    |    |   |        |
 |    |    |    |   |        └─ Bagsub
 |    |    |    |   └────────── SubImage
 |    |    |    └────────────── Staining
 |    |    └─────────────────── Electrode_Thickness
 |    └──────────────────────── Time_weeks
 └───────────────────────────── Animal_No
```

A filename with a different number of underscore-separated fields will
misassign every metadata column, silently. There is no validation step, so
check `table(import$df_all$Time_weeks)` straight after step 2.

Timepoint labels are then standardised: `4hpi` becomes `00WPI`, `5dpi` becomes
`01WPI`, `14dpi` and `2wpi` become `02WPI`, `8wpi` becomes `08WPI`, `18wpi`
becomes `18WPI`. **Any label not in that list becomes `NA`**, so if you have
other timepoints you must extend the `case_when` in section 11.

### Software

- **R** 4.0 or later, and RStudio
- **Python** 3.6 or later, needed by `phateR` and `Rmagic` for Figures 4 and 5

`01_Load_packages.R` installs missing CRAN packages and pins Bioconductor to
release 3.17. If you are on a newer R, that pin will fail and should be edited.
PHATE additionally needs its Python module:

```r
library(reticulate)
py_install("phate", pip = TRUE)
```

Figures 1, 2, 3 and the supplementary figures do not need PHATE. If you only
want those, you can skip the Python setup.

---

## 3. Step by step

### `01_Load_packages.R`

Installs any missing CRAN packages, sets up Bioconductor, loads everything.
Run once per session, first.

### `02_Import_Data.R`

Reads every table in the two input folders, binds them, derives `Condition`
from the source filename, strips the `AreaShape_` prefix, suffixes columns
`_soma` or `_cell`, and merges the two sides into `import$df_all`.

It then joins the implant coordinates, splits metadata out of the filename as
described above, and computes:

**Spatial position**

| Variable | Definition |
|----------|------------|
| `radial_dist` | Euclidean distance from soma centre to implant centre |
| `bin_number` | `radial_dist` split into 25 equal-count bins (`ntile`) |
| `Bin_Number_New` | as above, with bins above 16 collapsed into bin 17 |
| `bin_range_new` | `Bin_Number_New * 139`, bin midpoint in distance units |
| `Impact_Region` | `Close` (bins 1-6), `Middle` (7-10), `Far` (above 10) |

Note that the bins are **equal-count, not equal-width**: `ntile` puts the same
number of cells in each bin, so bin width varies with local cell density. This
is appropriate for comparing proportions across bins but means bin index is not
linear in distance. Use `bin_range_new` when distance itself matters.

**Morphological features**

| Feature | Definition | Interpretation |
|---------|------------|----------------|
| `RI` | ramification index, perimeter-to-area normalised against a circle of equal area | arbor complexity independent of cell size; falls as cells de-ramify |
| `area_ratio` | `Area_cell / Area_soma` | territory per unit cell body, a soma-versus-arbor rebalancing readout |
| `Cyto_Area` | `Area_cell - Area_soma` | absolute arbor footprint |
| `Length_Width_Ratio` | `MaxFeret / MinFeret`, soma and cell | elongation, captures rod-like morphology |
| `Aspect_Ratio` | `MajorAxis / MinorAxis`, soma and cell | polarisation, sensitive to orientation toward the lesion |
| `Total_Branch` | `Non_Trunk_Branch + Trunk_Branch` | total branch count |
| `Health_score` | 1 when `Total_Branch >= 20`, declining linearly below | convenience scalar only |

`Health_score` is a monotone transform of `Total_Branch`, not an independent
measurement. Do not enter both into the same model.

**Check after running:** `colnames(import$df_all)` and
`table(import$df_all$Impact_Region)`.

### `03_Wins_Filtering_PCA.R`

Two-stage, deliberately conservative treatment of extreme values:

1. **Winsorisation** at 1% per tail, which compresses tails without removing
   any cell, so no cell is lost on the basis of one aberrant feature.
2. **Mahalanobis distance filtering** on the winsorised matrix to remove
   genuine multivariate outliers.

Features are then scaled and reduced by `prcomp`. The script emits QC plots:
cell counts before and after, the Mahalanobis distribution with the cutoff
marked, PCA before versus after, and distributions of the most variable
features.

**Check after running:** that the proportion of cells removed is small and that
the before/after PCA plots do not differ structurally. Losing a visible
subpopulation here means the cutoff is too aggressive.

Outputs: `Filter$df_clean_final`, `Filter$feat_scaled`, `Filter$meta_clean`,
`PCA$pca`, `PCA$pca_df`.

### `04_Clustering_UMAP.R`

Samples cells, clusters, then projects assignments back onto the full dataset.

- **Sampling.** Tries stratified sampling at `sample_size = 30000`, falling
  back to systematic and then random sampling. Clustering is computed on the
  sample for tractability and assignments are extended to all cells.
- **Clustering.** k-means with **k fixed at 13** (`ClusterAnalysis$optimal_k`,
  line 283). The elbow and silhouette selection code is present but commented
  out. k=13 is the published value and is a declared granularity rather than an
  automatically selected optimum, because the morphological continuum does not
  present a sharp elbow.
- **UMAP** for visualisation only. Cluster identity comes from k-means on PCA
  scores, not from the UMAP embedding.
- **False-positive removal.** Clusters **1 and 12** are dropped
  (`remove_cluster <- c(1, 12)`, line 441) as segmentation artefacts rather
  than morphological states. Both `final_df_sampled` and `final_df_full` are
  overwritten in place with the filtered versions.

If you change `k`, the cluster numbers change, so `remove_cluster` here and
every hard-coded cluster-to-phenotype mapping in `Figure_4.R` and `Figure_5.R`
must be revisited. These mappings are dataset-specific by construction.

Outputs: `ClusterAnalysis$final_df_full`, `ClusterAnalysis$final_df_sampled`,
`ClusterAnalysis$summary`.

> **Known issue before you run `Figure_4.R`.** `Figure_4.R` expects an object
> called `ClusterAnalysis_Filter`, which `04_Clustering_UMAP.R` does not create;
> script 04 overwrites `ClusterAnalysis` in place instead. Running `Figure_4.R`
> directly therefore stops with
> `"ClusterAnalysis_Filter not found. Please run the filtering script first."`,
> which also blocks Figures 5, S6 and S8. Until this is reconciled in the code,
> alias the object after running script 04:
> ```r
> ClusterAnalysis_Filter <- ClusterAnalysis
> ```
> This is correct because script 04 has already removed clusters 1 and 12 by
> that point, so `ClusterAnalysis` holds exactly the filtered data that
> `Figure_4.R` is asking for.

### Figure scripts

| Script | Figures | Content | Extra input |
|--------|---------|---------|-------------|
| `Figure_1.R` | 1, S4 | Cell positions with radial bins, faceted by time and electrode thickness | |
| `Figure_2.R` | 2, S2, S4 | Manual-versus-automated validation scatter plots, cell density across bins and time | three CSVs from `Datasheet/validation/` |
| `Figure_3.R` | 3 | Feature correlation heatmap with module detection, NMF rank selection, NMF feature and cell programs | |
| `Figure_4.R` | 4 | PHATE, UMAP with centroids, cluster parameter heatmap, frequency across bins, phenotype assignment | PHATE via Python |
| `Figure_5.R` | 5 | Transition cluster sub-clustering (T1/T2), dendrogram, enrichment dot plots, frequency heatmaps | `Fig4$df_phate_phenotype` |
| `Figure_S6.R` | S6 | Animal-level metadata, cells per image and per animal, cluster and phenotype proportions | |
| `Figure_S7.R` | S7 | Cluster proportions over time, clusters with largest change | |
| `Figure_S8.R` | S8 | Cluster proportions by electrode thickness (6, 11, 16, 50) | |

`Figure_1.R` builds its panel through `Fig1$plot_by_time_thickness()`, which
takes `bins_to_show` (default `1:5`), `n_images_per_time`, `time_weeks`,
`electrode_thickness`, `random`, `point_size`, `alpha` and `show_circles`. Call
it with your own arguments rather than editing the body, and use
`Fig1$short_filename()` to shorten labels. The example call at the foot of the
script reproduces the published panel.

Phenotype assignment in `Figure_4.R` and `Figure_5.R` maps specific cluster
numbers to named morphological states through `case_when`. Those numbers are
specific to this dataset and this value of k. Adjust them to your own data;
they are a biological interpretation, not a computation.

---

## 4. Saving outputs

All results stay in memory as R objects. The `ggsave`, `write.csv` and `pdf`
calls are commented out throughout, so **nothing is written to disk by
default**. Uncomment the ones you want, at the end of each script.

---

## 5. Troubleshooting

**`phate` Python module not found.** Run
`reticulate::py_install("phate", pip = TRUE)`. If you use a virtualenv, point
`use_virtualenv()` at it, as in `Figure_4.R`. Only Figures 4 and 5 need PHATE.

**`ClusterAnalysis_Filter not found`.** See the known issue above.

**Memory errors during NMF.** `Figure_3.R` downsamples to 10,000 cells by
default. Reduce `n_cells_use` further if needed.

**All metadata columns look wrong.** Your filenames do not have six
underscore-separated fields. See the naming contract above.

**`Time_weeks` is full of `NA`.** Your timepoint labels are not in the
`case_when` mapping in section 11 of `02_Import_Data.R`.

**Missing column errors in a figure script.** The figure scripts assume
columns created upstream (`Cluster`, `UMAP1`, `PHATE1_2D`, `Bin_Number_New`,
`Impact_Region`). Confirm steps 2 to 4 completed without error.

**Masked function warnings.** Restart the R session and run the scripts in
order without loading other packages in between. The dependency list is large
and several packages mask `dplyr` verbs.

---

## 6. Citation

> Jariwala, V.D., Ponnamma, S., Ravi, V.M., Beck, J., Hofmann, U.G., and
> Joseph, K. (2026). MicroFace maps microglial morphology remodeling, revealing
> spatial zones and bifurcated trajectories during brain microinjury recovery.
> *iScience* **29**, 116485. https://doi.org/10.1016/j.isci.2026.116485
