# 07_RStudio_Analysis_Scripts

**Scripts:** [`../../1_Toolbox/R_Scripts/`](../../1_Toolbox/R_Scripts/)

The scripts live in `1_Toolbox` so there is a single authoritative copy rather
than one per folder, the same arrangement as the Fiji macro and the CellProfiler
pipeline. Open them from there.

Five R scripts, run **in order, in a single R session**. Each builds on objects
left by the previous one, so they cannot be run out of order or in isolation.

| Script | Does | Key parameter |
|--------|------|---------------|
| `01_Load_packages.R` | installs missing CRAN packages and loads them | none; every dependency is on CRAN |
| `02_Import_Data.R` | merges soma and cell tables, derives features | **two file paths at the top, edit these first** |
| `03_Wins_Filtering_PCA.R` | winsorises, removes outliers, PCA | `max_remove_pct = 0.005` |
| `04_Clustering_UMAP.R` | k-means and UMAP | `default_k = 6`, override after seeing the elbow plot |
| `05_Morpho_Enrichment.R` | per-cluster feature enrichment | none; reads what `04` produced |

Requires R 4.0 or later and about 8 GB of RAM. Needs
`06_Datasheet/Test_Soma_Filtered.txt` and `Test_Cell.txt`, or the equivalent
pair under your own export prefix.

Three things to know before running:

**Edit the paths.** `02_Import_Data.R` opens with two placeholder paths
(`/FOLDER_PATH_TO_/Test_Soma_Filtered.txt` and
`/FOLDER_PATH_TO_/Test_Cell.txt`) that will not match your machine. Both files
must come from the **same** CellProfiler run: the merge keys on
`FileName_Original_Iba1`, `ImageNumber` and `Parent_Soma_Merged`, which are
assigned per run, so tables from two different runs merge to zero rows.

**k is deliberately not automatic.** The morphological continuum has no sharp
elbow, because microglial morphology is genuinely continuous rather than
composed of discrete types. The script plots the elbow, marks a reference knee,
then uses `k = 6`. Inspect and override:

```r
ClusterAnalysis$optimal_k_override <- 8   # then rerun from step 3
```

**Nothing is saved by default.** The `ggsave` and `write.csv` calls at the end
are commented out.

`04` gives you clusters; `05_Morpho_Enrichment.R` is what tells you what those
clusters are made of, as row z-scores of the cluster mean per feature with an
adjusted p value and the fraction of cells in the cluster above the global
median. k-means returns groups, not phenotypes, so naming a feature combination
as a morphological state is an interpretive step rather than an output of the
script.

Full walkthrough, including the two checks that tell you whether a cluster is a
morphological state or a technical artefact:
[tutorial step 7](../README.md#step-7-analysis-in-r).

**Back to:** [tutorial](../README.md)
