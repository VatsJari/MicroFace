# MicroFace: automated toolbox for microglia morphology analysis

<img width="7916" height="4702" alt="cover_page_2" src="https://github.com/user-attachments/assets/48b1388d-c3ac-4b75-bba3-5bd5405f47e2" />

MicroFace is an end-to-end workflow for quantifying microglial morphology at
single-cell scale from Iba1 immunofluorescence images. It segments soma and
arbor as separate objects, skeletonises the arbor, extracts a multidimensional
morphometric feature set per cell, and resolves the resulting feature space
into morphological states and their spatial organisation around a brain
microinjury.

The workflow reconstructed **over 250,000 microglia from more than 200 images**
in the associated publication.

---

## Which repository do I want?

This project is split across two repositories with different purposes. Pick the
one that matches what you are trying to do.

| | **MicroFace** (this repository) | **MicroFace_V2** |
|---|---|---|
| **Purpose** | Reproduce the published analysis | Apply the method to your own data |
| **Form** | Ordered analysis scripts plus the exact Fiji and CellProfiler pipelines used | Installable R package with a documented function API |
| **Use it when** | You are checking, reviewing, or rerunning the iScience paper | You have your own CellProfiler output and want the toolbox |
| **Clustering** | k-means, k fixed at 13, as published | Gaussian mixture model by default, with k selection helpers |
| **Stability** | Frozen as the record of the paper | Actively developed |
| **Link** | you are here | https://github.com/VatsJari/MicroFace_V2 |

The two are not interchangeable and will not give identical numbers. The
parameters in this repository are the ones behind the published figures; V2 is
a generalised reimplementation. If you are reviewing the paper, stay here.

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
CellProfiler pipeline that resolves soma and arbor independently. The resulting
per-cell feature tables were filtered, reduced and clustered in R, and each
cell was additionally assigned a radial distance from the implant centre so
that morphological state could be related to spatial position.

---

## Repository layout

```
MicroFace/
├── Image processing analysis/        STEP 1 and 2: image to feature table
│   ├── Fiji/
│   │   ├── Auto_Brightness.ijm       batch pre-processing of raw TIFFs
│   │   ├── Injury_Center.ijm         manual implant-centre picking -> coordinates.csv
│   │   ├── Cluster_Crop.ijm          per-cluster cell crops (figure panels)
│   │   └── Cluster_Crop_montage.ijm  crops plus per-cluster stacks and montages
│   ├── Cellprofiler/
│   │   ├── The_Skeleton_Pipeline.cpproj   main segmentation and skeletonisation
│   │   └── Valdidation_Pipeline.cpproj    manual-versus-automated validation
│   └── README.md                     image-processing instructions
│
└── Data analysis/                    STEP 3: feature table to morphological states
    ├── Scripts/
    │   ├── 01_Load_packages.R        install and load dependencies
    │   ├── 02_Import_Data.R          import, merge, metadata, derived features
    │   ├── 03_Wins_Filtering_PCA.R   winsorise, outlier removal, PCA
    │   ├── 04_Clustering_UMAP.R      k-means (k=13) and UMAP
    │   ├── Figure_1.R                radial bins (also Figure S4)
    │   ├── Figure_2.R                validation and density (also Figures S2, S4)
    │   ├── Figure_3.R                feature correlation modules and NMF
    │   ├── Figure_4.R                PHATE, cluster scoring, phenotypes
    │   ├── Figure_5.R                transition sub-clustering and enrichment
    │   ├── Figure_S6.R               animal-level metadata and proportions
    │   ├── Figure_S7.R               temporal dynamics
    │   ├── Figure_S8.R               electrode thickness
    │   └── TBI_Manuscript.Rproj      RStudio project
    ├── Datasheet/
    │   ├── Injury_Center/coordinates.csv       implant centres per image
    │   ├── Meta_data_file/                    animal and image summaries
    │   └── validation/                        manual-versus-automated tables
    └── README.md                     analysis instructions, step by step
```

---

## Workflow at a glance

```
raw Iba1 TIFFs
     |
     |  Fiji: Auto_Brightness.ijm            16-bit, rolling-ball 50, contrast 0.35%
     v
pre-processed TIFFs
     |
     |  CellProfiler: The_Skeleton_Pipeline.cpproj
     v
per-image soma and cell tables  +  QC overlays
     |
     |  Fiji: Injury_Center.ijm              -> coordinates.csv
     v
R: 01 -> 02 -> 03 -> 04                      merge, filter, PCA, cluster
     |
     v
R: Figure_1 ... Figure_S8                    published figures
```

---

## Getting started

Full step-by-step instructions, including what each script consumes and
produces, live in the two folder READMEs:

- **[Image processing analysis/README.md](Image%20processing%20analysis/README.md)** for the Fiji and CellProfiler stages
- **[Data analysis/README.md](Data%20analysis/README.md)** for the R stages

Read those before running anything. Two things will otherwise catch you out:

1. **All file paths in the R scripts are absolute** and point at the original
   author's machine (`/Users/vatsaljariwala/...`). You must edit them.
2. **The per-image feature tables are not in this repository.** Scripts
   `02_Import_Data.R` onward expect folders of CellProfiler output
   (`Datasheet/df_soma/` and `Datasheet/df_cell/`) that are too large to host
   here. See the data availability note below.

---

## Data availability

This repository holds code, pipelines, and the small reference tables
(implant-centre coordinates, validation tables, metadata summaries). It does
**not** hold the imaging data or the per-image feature tables.

- Representative raw images, pre-processed images, QC overlays, and the
  per-object feature tables are deposited separately as an executable archive
  with its own step-by-step README.
- Public transcriptomic datasets referenced in the paper are available through
  GEO.
- Anything else required for reanalysis can be requested from the
  corresponding author.

---

## Citation

If you use MicroFace, please cite:

> Jariwala, V.D., Ponnamma, S., Ravi, V.M., Beck, J., Hofmann, U.G., and
> Joseph, K. (2026). MicroFace maps microglial morphology remodeling, revealing
> spatial zones and bifurcated trajectories during brain microinjury recovery.
> *iScience* **29**, 116485.
> https://doi.org/10.1016/j.isci.2026.116485

---

## Contact

Corresponding author: kevin.joseph@uniklinik-freiburg.de

For problems with the code specifically, please open an issue on this
repository rather than emailing, so that the answer is visible to other users.
