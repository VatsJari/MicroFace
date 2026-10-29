# 07_RStudio_Analysis_Scripts

Four R scripts, run **in order, in a single R session**. Each builds on objects
left by the previous one, so they cannot be run out of order or in isolation.

| Script | Does | Key parameter |
|--------|------|---------------|
| `01_Load_packages.R` | installs and loads dependencies | Bioconductor pinned to 3.17 |
| `02_Import_Data.R` | merges soma and cell tables, derives features | **two file paths at the top, edit these first** |
| `03_Wins_Filtering_PCA.R` | winsorises, removes outliers, PCA | `max_remove_pct = 0.005` |
| `04_Clustering_UMAP.R` | k-means and UMAP | `default_k = 6`, override after seeing the elbow plot |

Requires R 4.0 or later and about 8 GB of RAM. Needs
`06_Datasheet/_TestSoma_Filtered.txt` and `_TestCell.txt`.

Three things to know before running:

**Edit the paths.** `02_Import_Data.R` opens with two absolute paths that will
not match your machine.

**k is deliberately not automatic.** The morphological continuum has no sharp
elbow, because microglial morphology is genuinely continuous rather than
composed of discrete types. The script plots the elbow, marks a reference knee,
then uses `k = 6`. Inspect and override:

```r
ClusterAnalysis$optimal_k_override <- 8   # then rerun from step 3
```

**Nothing is saved by default.** The `ggsave` and `write.csv` calls at the end
are commented out.

Full walkthrough, including the two checks that tell you whether a cluster is a
morphological state or a technical artefact:
[tutorial step 7](../README.md#step-7-analysis-in-r).

**Back to:** [tutorial](../README.md)
