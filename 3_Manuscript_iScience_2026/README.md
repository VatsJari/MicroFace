# 3_Manuscript_iScience_2026

The analysis exactly as it was run for:

> Jariwala, V.D., Ponnamma, S., Ravi, V.M., Beck, J., Hofmann, U.G., and
> Joseph, K. (2026). MicroFace maps microglial morphology remodeling, revealing
> spatial zones and bifurcated trajectories during brain microinjury recovery.
> *iScience* **29**, 116485.
> https://doi.org/10.1016/j.isci.2026.116485

This folder is the **record of the publication** and is frozen. Parameters here
are the published ones, including the fixed cluster count and the
dataset-specific cluster-to-phenotype mappings. Do not treat it as a starting
point for new data: use **[../1_Toolbox](../1_Toolbox/)** for that, after
working through **[../2_Tutorial](../2_Tutorial/)**.

```
3_Manuscript_iScience_2026/
├── Image processing analysis/    Fiji macros + CellProfiler pipelines
└── Data analysis/                R scripts, reference tables, figure code
```

Read **[Image processing analysis/README.md](Image%20processing%20analysis/README.md)**
first, then **[Data analysis/README.md](Data%20analysis/README.md)**. Both
document each file, what it consumes, and what it produces.

---

## Experimental design

A rat model of neuroinflammation was used to develop an automated workflow for
quantifying microglia morphology over an extended implantation period. The
effect of flexible neural probe implantation on microglial morphology was
investigated in order to identify features sensitive to different activation
states. Animals were sacrificed across a time course from 4 hours to 18 weeks
post-implantation, and cortical sections were processed by immunohistochemistry
for Iba1.

Images were pre-processed in Fiji, then segmented and skeletonised with a
CellProfiler pipeline resolving soma and arbor independently. Per-cell feature
tables were filtered, reduced and clustered in R. Each cell additionally
carries a radial distance from the implant centre, so morphological state could
be related to spatial position rather than only to time.

---

## Before you try to run it

Three things will stop you, and all three are documented in detail in the two
folder READMEs:

1. **Every file path is absolute** and points at the original author's machine.
   You must edit them.
2. **The per-image feature tables are not in this repository.** Scripts from
   `02_Import_Data.R` onward expect folders of CellProfiler output
   (`Datasheet/df_soma/` and `Datasheet/df_cell/`) that are too large to host
   on GitHub.
3. **`Figure_4.R` stops on a missing object.** It requires
   `ClusterAnalysis_Filter`, which `04_Clustering_UMAP.R` never creates, and
   this also blocks Figures 5, S6 and S8. The one-line workaround is in
   [Data analysis/README.md](Data%20analysis/README.md).

---

## How this differs from the tutorial

Both reach single-cell morphological states, by deliberately different routes.

| | This folder | [../2_Tutorial](../2_Tutorial/) |
|---|---|---|
| Input | folders of per-image tables | two merged tables |
| Scale | full cohort, 200+ images | 12-image worked example |
| Clustering | k-means, k fixed at 13 | k-means, k = 6 by default, chosen from the elbow plot |
| Sampling | stratified sample of 30,000 cells, assignments projected back | no sampling, all cells clustered |
| Spatial | radial bins and impact regions relative to implant centre | spatial plots by image |
| Figures | all published main and supplementary figures | none |

The tutorial is the gentler path and teaches the method. This folder reproduces
the paper. Numbers will not match between them, by design.
