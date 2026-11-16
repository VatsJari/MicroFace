# 2_Tutorial

A guided, end-to-end walkthrough of MicroFace on a 12-image worked example:
from a raw Iba1 TIFF to a clustered single-cell morphology dataset with
per-cluster spatial maps.

This is the place to start if you are new. It is written to be followed in
order, and it explains **why** each step is there, not only which button to
press, because almost every failure in morphometric analysis is a parameter
chosen without understanding what it does.

**Time required:** about 2 to 3 hours, most of it unattended while
CellProfiler runs.

---

## What you will learn

1. How to pre-process Iba1 images so that thresholding behaves consistently.
2. Why MicroFace segments soma and arbor as **separate objects**, and how to
   tell when that segmentation has failed by looking at it.
3. How skeleton topology (trunks, branches, endpoints) is measured outward from
   the soma, and which output table it lands in.
4. How to filter extreme cells without deleting real biology.
5. How to choose a cluster count honestly, and how to check whether a cluster
   is a morphological state or a technical artefact.

---

## Prerequisites

| Software | Version | Needed for |
|----------|---------|------------|
| [Fiji](https://fiji.sc/) | 1.53 or later | step 2 |
| [CellProfiler](https://cellprofiler.org/) | 4.2.x | step 4 |
| [R](https://www.r-project.org/) + [RStudio](https://posit.co/download/rstudio-desktop/) | R 4.0 or later | step 7 |

The download is 546 MB and expands to about **3.8 GB**, of which the
quality-control folder is 3.3 GB. Allow roughly 5 GB of free disk space for
the archive and its extraction, and about 8 GB of RAM for the R step.

No prior CellProfiler experience is assumed. Some familiarity with R will help
in step 7, but the scripts run top to bottom as supplied.

---

## Download the example data

This repository is code only. The images and feature tables live on Zenodo:

**[Zenodo archive &middot; 10.5281/zenodo.24278540](https://doi.org/10.5281/zenodo.24278540)**

The record holds one file, `Archive_Version_2.zip` (546 MB). It extracts to
the same seven numbered folders as this tutorial, so each one drops straight
into the matching folder here.

You will not need all of it. Pick your entry point and delete the rest after
extracting:

| If you want to | Use | Size once extracted |
|----------------|-----|---------------------|
| Follow every step from raw images | `01_Raw_Images` | 264 MB |
| Skip Fiji, start at CellProfiler | `03_Pre_processed_Images` | 264 MB |
| Skip imaging, go straight to the R analysis | `06_Datasheet` | 25 MB |
| Compare your segmentation against ours | `05_Quality_Check_Mask_Outputs` | 3.3 GB |

**If you are short on time or disk, download `06_Datasheet` only** and start at
step 7. That is the morphometric analysis, and it is the part most people came
for. You can return to the imaging steps later.

---

## The pipeline

```
01_Raw_Images                  12 raw Iba1 TIFFs
      |
      |  02  Fiji macro                    8-bit, contrast, background, median subtraction
      v
03_Pre_processed_Images        12 *_Processed.tif
      |
      |  04  CellProfiler pipeline         soma + arbor segmentation, skeletonisation
      v
05_Quality_Check_Mask_Outputs  3 overlays + 1 binary mask per image: look at these
06_Datasheet                   per-object feature tables
      |
      |  07  R scripts                     filter, PCA, cluster, UMAP, enrichment
      v
clustered single-cell morphology
```

Steps 4 produces both 05 and 06 at once. Only 06 feeds the R analysis; 05
exists so that you can see whether the segmentation deserves to be trusted
before you quantify anything from it.

---

## Step 1: the raw images

**Folder:** [`01_Raw_Images/`](01_Raw_Images/)

Twelve single-channel Iba1 TIFFs spanning four post-implantation intervals
(4 hpi, 14 dpi, 8 wpi, 18 wpi), about 23 MB each.

```
R<animal>_<timepoint>_<section>_Iba1_<image>.tif
R33_8wpi_11_Iba1_3.tif
```

Open two or three in Fiji before going further, one early and one late
timepoint. You should be able to see by eye what the analysis is going to
quantify: cells near the implant track have smaller, denser arbors and larger
somata, cells far from it are finely ramified. If you cannot see it, the
analysis will not find it either.

---

## Step 2: pre-processing in Fiji

**Folder:** [`02_Fiji_Pre-processing_Macro/`](02_Fiji_Pre-processing_Macro/)
**Macro:** [`../1_Toolbox/Fiji/Pre_Processing.ijm`](../1_Toolbox/Fiji/Pre_Processing.ijm)

In Fiji: `Plugins > Macros > Run...`, select the macro. It asks for an input
folder (`01_Raw_Images`) and an output folder (`03_Pre_processed_Images`), then
runs in batch mode.

Per image:

1. **Convert to 8-bit** if the image is not already, so every image enters the
   pipeline on the same intensity scale regardless of acquisition bit depth.
2. **Enhance Contrast** (`saturated=1.0 normalize`). Equalises dynamic range
   across sections stained and imaged in different sessions, so one adaptive
   threshold works for all of them.
3. **Subtract Background** (`rolling=50`). Removes the low-frequency
   autofluorescence pedestal.
4. **Median subtraction.** Duplicate the image, median filter the duplicate at
   **radius 20**, subtract it from the original.
5. **Write out** as 8-bit TIFF with **`_Processed`** appended to the file name.

Step 4 is the one worth understanding. A radius-20 median image is a local
background estimate at a spatial scale well above the width of a microglial
process, so subtracting it removes diffuse haze and non-specific staining while
leaving thin ramifications intact.

**What happens without it:** adaptive thresholding in step 4 bridges the gap
between neighbouring process fields, fusing adjacent cells into one object and
inflating skeleton length. This happens worst where cells are densest, which is
the peri-implant zone, which is where the biology is. The failure therefore
destroys exactly the signal you are trying to measure, and it does so quietly.

**Check before continuing:** open one output image next to its input. Processes
should still be visible and continuous, background should be flatter. If
processes have thinned or broken, the median radius is too small for your pixel
size.

Keep the input and output folders separate. A file that already carries
`_Processed` is processed a second time if it is sitting in the input folder,
which is what happens when both point at the same place.

---

## Step 3: the pre-processed images

**Folder:** [`03_Pre_processed_Images/`](03_Pre_processed_Images/)

Either your own output from step 2, or the deposited copy: twelve 8-bit TIFFs
named `..._Processed.tif`. These are the input to CellProfiler. Do not feed the
raw images to step 4; the pipeline's thresholds assume pre-processed input.

---

## Step 4: segmentation and skeletonisation

**Folder:** [`04_Skeleton_Pipeline/`](04_Skeleton_Pipeline/)
**Pipeline:** [`../1_Toolbox/CellProfiler/Skeleton_Pipeline.cpproj`](../1_Toolbox/CellProfiler/Skeleton_Pipeline.cpproj)

This is the heart of the method. Full parameter documentation is in
[`../1_Toolbox/README.md`](../1_Toolbox/README.md); this section is the guided
run.

1. Open the pipeline in CellProfiler.
2. Drag the contents of `03_Pre_processed_Images` into the `Images` module.
   The pipeline has 24 modules; confirm they all load.
3. Set the default output folder to `05_Quality_Check_Mask_Outputs` under
   `File > Preferences`, then set `Output file location` to
   `Default Output Folder` in all four `SaveImages` modules and in
   `ExportToSpreadsheet`. They ship pointing at paths from the machine the
   pipeline was developed on. Left unchanged, the overlays are written back
   into the folder holding the input images, where the next run will load them
   as input, and the export fails after the analysis has already finished.
4. In `ExportToSpreadsheet`, change the filename prefix from `ADD_PREFIX_` to
   something of your own. It is prepended verbatim, so keep a trailing
   separator; the deposited example used `Test_`.
5. **Before running everything, press `Start Test Mode` and step through one
   image.** Watch each module's window. This takes two minutes and saves hours.
6. `Analyze Images`. Expect roughly an hour for 12 images.

### What the pipeline is doing

Soma and arbor are found separately, then paired:

```
Soma_first      20,446    soma candidates
Soma_Merged     19,373    after merging fragmented soma
Soma_Filtered   18,680    soma whose arbor was fully resolved
Cell            18,680    paired whole-cell objects
```

Those are the counts you should see on this example data. If yours differ
substantially, your soma diameter range is wrong for your images.

The drop from 19,373 to 18,680 is deliberate. Cells touching the image border
are discarded **together with their parent soma**, because an arbor clipped by
the field of view would enter the dataset as a spuriously low-complexity cell
and compress the ramified-to-reactive axis. That is why `Soma_Filtered`, not
`Soma_Merged`, is the soma table you analyse.

The arbor is then skeletonised and measured **seeded on the soma**, so trunks,
non-trunk branches and endpoints are counted outward from the cell body. This
is why skeleton measures appear in the soma table rather than the cell table, a
point that confuses almost everyone the first time.

The run writes four images per field to `05_` and six tables to wherever
`ExportToSpreadsheet` points: 48 image files and 6 tables for these 12
images.

---

## Step 5: quality control, which is not optional

**Folder:** [`05_Quality_Check_Mask_Outputs/`](05_Quality_Check_Mask_Outputs/)

Four files per image, 48 in all. Three are overlays to look at; the fourth is
the binary mask they were built from. **Look at all 36 overlays before you
quantify anything.**

| Suffix | Shows | Failure looks like |
|--------|-------|--------------------|
| `*OIC.tiff` | whole-cell objects over the image | arbors fused between neighbours, or truncated |
| `*SWS.png` | skeleton with soma overlaid | broken skeleton, spurious loops, skeleton off-centre |
| `*QC.png` | cell and soma outlines on the original | soma mask inflated into proximal processes |
| `*MASK.png` | the binary whole-cell mask itself | not an overlay, and not an analysis input |

`*MASK.png` keeps the exact segmented foreground beside the numbers derived
from it, so a segmentation can be re-measured, compared against another method
on the same fields, or taken into other software without rerunning the
pipeline. It is also the image to open when an overlay looks wrong and it is
unclear whether the fault lies in the mask or in the object assignment built on
top of it.

Why this step gets its own folder: segmentation failure is far easier to see
than to detect statistically. It also distorts the **derived ratios** more than
the raw measurements, because an inflated soma mask shrinks the arbor estimate
at the same time, pushing `area_ratio` and cytoplasmic area in opposite
directions. A dataset can look entirely reasonable in its summary statistics
and still rest on bad masks.

If the overlays disagree with the images, adjust the soma diameter range and the
secondary threshold correction factor, then rerun step 4. Do not proceed on
segmentation you have not looked at.

---

## Step 6: the feature tables

**Folder:** [`06_Datasheet/`](06_Datasheet/)

Tab-delimited, one row per object.

File names begin with the prefix set in `ExportToSpreadsheet` at step 4. The
deposited copy was exported with `Test_`.

| File | Rows | Role |
|------|------|------|
| `Test_Soma_Filtered.txt` | 18,680 | **analysis input**: soma shape + skeleton topology |
| `Test_Cell.txt` | 18,680 | **analysis input**: whole-cell shape |
| `Test_Soma_Merged.txt` | 19,373 | intermediate, provenance only |
| `Test_Soma_first.txt` | 20,446 | intermediate, provenance only |
| `Test_Image.txt` | 12 | per-image counts, thresholds, timings |
| `Test_Experiment.txt` | 338 | run provenance, full pipeline text |
| `Injury_Center.csv` | 291 | implant centre coordinates |

**Only the first two are read by the R scripts.** Soma pairs to cell on
`Parent_Soma_Merged`.

Worth opening `Test_Image.txt` once: it holds the per-image object counts and
the actual thresholds chosen. If one image produced far fewer cells than the
others, that is where you find out.

`Injury_Center.csv` covers the full published cohort, and its filenames use the
study's `*_FilteredSubtracted.tif` convention, so it does not key directly onto
these 12 images. It is included because radial distance from the implant is
required to reproduce the spatial-zone analysis; match on the animal and
section fields if you adapt it.

---

## Step 7: analysis in R

**Folder:** [`07_RStudio_Analysis_Scripts/`](07_RStudio_Analysis_Scripts/)
**Scripts:** [`../1_Toolbox/R_Scripts/`](../1_Toolbox/R_Scripts/)

Five scripts, run **in order, in one R session**. Each builds on objects left
by the previous one, so they cannot be run out of order or in isolation.

### `01_Load_packages.R`

Installs missing CRAN packages and loads them. Everything the analysis calls is
on CRAN; no step uses a Bioconductor package. Mahalanobis distance, PCA and
k-means come from `stats` in base R, and the embedding from `uwot`.

### `02_Import_Data.R`

**Edit the two paths at the top first.** They ship as placeholders
(`/FOLDER_PATH_TO_/Test_Soma_Filtered.txt` and
`/FOLDER_PATH_TO_/Test_Cell.txt`) and must point at your own
`06_Datasheet/Test_Soma_Filtered.txt` and `Test_Cell.txt`.

Strips the `AreaShape_` prefix, suffixes columns `_soma` and `_cell`, and
merges on `FileName_Original_Iba1` + `ImageNumber` + `Parent_Soma_Merged`. The
triple key is necessary: an image holds thousands of objects, so filename and
image number alone do not identify a cell.

Then computes the derived features:

| Feature | Definition | Interpretation |
|---------|------------|----------------|
| `RI` | perimeter-to-area, normalised against a circle of equal area | arbor complexity independent of cell size; falls as cells de-ramify |
| `area_ratio` | `Area_cell / Area_soma` | territory per unit cell body |
| `Cyto_Area` | `Area_cell - Area_soma` | absolute arbor footprint |
| `Length_Width_Ratio` | `MaxFeret / MinFeret` | elongation, captures rod-like cells |
| `Aspect_Ratio` | `MajorAxis / MinorAxis` | polarisation |
| `Total_Branch` | trunk + non-trunk branches | total branch count |
| `Health_score` | 1 above 20 branches, linear below | convenience scalar only |

`Health_score` is a monotone transform of `Total_Branch`, not an independent
measurement. Never put both in the same model.

**Check:** `colnames(import$df_all)` and `nrow(import$df_all)`, which should be
18,680.

### `03_Wins_Filtering_PCA.R`

Extreme values in two conservative stages:

1. **Winsorise** at 1% per tail. Compresses tails without removing any cell, so
   no cell is lost because of one aberrant feature.
2. **Mahalanobis filtering**, with the cutoff set to the stricter of a
   chi-square quantile (0.9999) and a hard cap at 0.5% of cells.

That hard cap is the part that matters. Single-cell morphometric distributions
are heavy-tailed, so a purely theoretical chi-square cutoff discards genuine
reactive cells, which are the biologically interesting ones. The script reports
which of the two bound the cutoff; if it says "chi-square", consider whether
you are losing real cells.

Features are then centred on the **median** and scaled by the **IQR** rather
than z-scored, because several remain skewed after winsorisation and median/IQR
scaling stops a handful of extreme cells dominating the leading components.

**Check:** the before-versus-after PCA panel. Removing extremes should trim the
edges of the cloud. If a whole lobe disappears, you deleted a subpopulation and
should relax `max_remove_pct`.

### `04_Clustering_UMAP.R`

k-means on the components reaching 97% cumulative variance, then UMAP for
visualisation only. Cluster identity comes from k-means on PCA scores, never
from the UMAP layout.

**k is not chosen automatically, on purpose.** The script draws a labelled
elbow plot, marks a reference knee, and then uses `k = 6`. Inspect the plot and
override if your data differ:

```r
ClusterAnalysis$optimal_k_override <- 8   # then rerun from step 3
```

The morphological continuum has no sharp elbow, because microglial morphology
is genuinely continuous rather than composed of discrete types. An automated
knee would impose a cluster count the data do not support. `k` is a declared
granularity, and should be reported as such.

### `05_Morpho_Enrichment.R`

`04` gives you clusters. This script tells you what they are made of: for every
feature, the row z-score of the cluster mean against the other clusters, with an
adjusted p value and the fraction of cells in the cluster lying above the global
median for that feature. Output is a heat map, a dot plot in which point size is
that fraction, and a per-cluster feature ranking.

Read it before naming anything. k-means returns groups, not phenotypes, and the
clusters it returns separate along two largely independent axes: arbor
complexity, carried by `RI`, branch endpoints and skeleton length, and
soma-versus-arbor balance, carried by `Area_soma` and `area_ratio`. Which
combination of those deserves to be called a reactive or a ramified state is an
interpretive judgement, not an output of the script. For the assignments used in
the published analysis, see the iScience paper cited in
[`../README.md`](../README.md).

### Two checks that decide whether your clusters are real

The script produces both; they are the point of the exercise.

1. **Per-image composition heatmap.** A cluster confined to one or two images is
   more likely a staining or imaging artefact than a morphological state. Step 8
   provides `ClusterAnalysis$remove_cluster_override` for that case.
2. **Spatial facets.** A morphologically meaningful cluster should show spatial
   structure relative to the implant. A cluster scattered uniformly across every
   field is usually technical.

Also inspect the UMAP overlays for `RI`, `Trunk_Branch`, `Branch_Ends` and
`Area_soma`. These should vary smoothly across the embedding. Smooth gradients
mean you have resolved a continuum; sharp discontinuities that do not follow
cluster boundaries usually mean a batch effect.

Save calls at the end are commented out, so nothing is written to disk by
default.

---

## Troubleshooting

**Object counts very different from ours.** Soma diameter range in
`IdentifyPrimaryObjects` is in **pixels** and is specific to our objective and
binning. Measure a few soma in Fiji and set the range accordingly.

**Arbors fused between neighbouring cells.** Raise the threshold correction
factor in `IdentifySecondaryObjects` from 0.5, or check that step 2 actually
ran, since this is the signature failure of skipping median subtraction.

**Soma masks swallowing proximal processes.** Raise the lower threshold bound in
`IdentifyPrimaryObjects` above 0.13.

**R: "object 'import' not found".** The scripts share one session and must run
in order, starting at `01`.

**R: merge returns zero rows.** Your two input files come from different
CellProfiler runs. Both must come from the same run, so `ImageNumber` and
`Parent_Soma_Merged` are consistent.

**R: masked function warnings.** Restart the session and run the scripts in
order without loading other packages in between.

**CellProfiler runs out of memory.** Analyse in batches by dragging fewer
images into the `Images` module; the feature tables can be concatenated after.

---

## Where to go next

- **Your own images:** [`../1_Toolbox`](../1_Toolbox/), with its parameter table.
- **Scripting the analysis:** [MicroFace_V2](https://github.com/VatsJari/MicroFace_V2),
  the same analysis as an installable R package.
- **Reproducing the paper:** [`../3_Manuscript_iScience_2026`](../3_Manuscript_iScience_2026/).
  Note that it uses k = 13, stratified sampling, and radial binning against the
  implant centre, so its numbers differ from this tutorial by design.

Please cite the paper if you use MicroFace. The citation is in
[`../README.md`](../README.md).
