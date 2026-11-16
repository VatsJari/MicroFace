# 1_Toolbox

The MicroFace pipeline, as the files you can drop into your own project. No
example data, no figure code. If you want to be walked through it on a worked
example first, go to **[../2_Tutorial](../2_Tutorial/)**.

```
1_Toolbox/
├── Fiji/Pre_Processing.ijm                 stage 1: image pre-processing
├── CellProfiler/Skeleton_Pipeline.cpproj   stage 2: segmentation + skeletonisation
└── R_Scripts/                              stage 3: datasheet assembly and analysis
    ├── 01_Load_packages.R
    ├── 02_Import_Data.R
    ├── 03_Wins_Filtering_PCA.R
    ├── 04_Clustering_UMAP.R
    └── 05_Morpho_Enrichment.R
```

This folder holds the single authoritative copy of every one of these files.
`2_Tutorial` points here rather than keeping copies of its own, so there is
never more than one version of a file in the repository.

Run the stages in order. Stage 2 expects the output of stage 1, and stage 3
expects the tables written by stage 2.

| | Requirement |
|---|---|
| Stage 1 | Fiji / ImageJ 1.53 or later |
| Stage 2 | CellProfiler 4.2.x |
| Stage 3 | R 4.0 or later, about 8 GB of RAM |

What comes out of stage 2: one tab-delimited feature table per object class,
plus three QC overlays and one binary whole-cell mask per image. Stage 3 is one
route from those tables to morphological states; it is not the only one, and
[MicroFace_V2](https://github.com/VatsJari/MicroFace_V2) packages another.

---

## Stage 1: `Fiji/Pre_Processing.ijm`

In Fiji, `Plugins > Macros > Run...`, select the macro. It prompts for an input
folder and an output folder, then processes every file in the input folder in
batch mode.

Per image, in order:

1. Convert to **8-bit** if the image is not already, so that every image enters
   the pipeline on the same intensity scale regardless of acquisition depth.
2. `Enhance Contrast` with `saturated=1.0 normalize`, equalising dynamic range
   across sections stained and imaged in different sessions.
3. `Subtract Background` with `rolling=50`, removing the low-frequency
   autofluorescence pedestal.
4. Duplicate the image, apply a `Median` filter of **radius 20** to the
   duplicate, and subtract that median-filtered copy from the original.
5. Confirm the result is 8-bit and write it to the output folder as TIFF, with
   **`_Processed`** appended to the original file name.

The suffix matters in practice: raw and processed images remain distinguishable
at a glance, and a file that already carries it is visibly not a candidate for a
second pass. Files whose extension is not a recognised image type are skipped
and reported in the log rather than silently ignored.

**Step 4 is the one that matters, and the one to tune first.** The radius-20
median image is a local background estimate at a spatial scale well above the
width of a microglial process. Subtracting it suppresses diffuse residual
signal and non-specific staining while leaving thin ramifications intact.

Without it, adaptive thresholding in stage 2 merges neighbouring process fields
and inflates skeleton length wherever cells are dense, which is exactly where
the biology is most interesting. The practical consequence is that reactive and
ramified cells stop being separable in the peri-implant zone.

If your objective or pixel size differs from ours, scale the radius so it stays
several times the process width in **pixels**, not microns. Too small and it
erodes real processes; too large and it stops estimating background.

---

## Stage 2: `CellProfiler/Skeleton_Pipeline.cpproj`

Open in CellProfiler, drag your **pre-processed** images into the `Images`
module, set the default output folder, set your own filename prefix in
`ExportToSpreadsheet`, then `Analyze Images`.

### The idea

The pipeline resolves soma and arbor as separate objects and pairs them
afterwards, rather than segmenting the whole cell in one pass:

```
Soma_first        soma candidates, from the median-filtered image
    |  merge fragmented soma
Soma_Merged
    |  propagate arbor outward on the neurite-enhanced image
Cell              whole-cell objects
    |  discard anything touching the border, parent soma included
Soma_Filtered     soma whose arbor was fully resolved
    |  skeletonise the arbor, seeded on the soma
skeleton topology per cell
```

`Soma_Filtered`, not `Soma_Merged`, is the soma table to analyse. It is the
soma set for which a complete, non-truncated arbor was resolved. Discarding
border-touching cells removes arbors clipped by the field of view, which would
otherwise enter your dataset as spuriously low-complexity cells and compress
the ramified-to-reactive axis.

Skeleton measures appear in the **soma** table, because
`MeasureObjectSkeleton` is seeded on `Soma_Filtered`: trunks, non-trunk
branches and branch endpoints are counted outward from the cell body. Pair soma
to cell on `Parent_Soma_Merged`.

### The parameters you will actually need to change

| Module | Setting | Shipped value | When to change it |
|--------|---------|---------------|-------------------|
| `IdentifyPrimaryObjects` | Typical diameter (min,max), pixels | `16,45` | **Always check this first.** It is in pixels, so it is wrong for any objective or binning other than ours. Measure a few soma in Fiji and set the range around them. |
| `IdentifyPrimaryObjects` | Adaptive Otsu, two-class, bounds | `0.13,1` | Raise the lower bound if dim background is detected as soma; lower it if faint soma are missed. |
| `IdentifyPrimaryObjects` | Size of smoothing filter | `10` | Raise if adjacent soma are split apart; lower if touching soma are merged. |
| `EnhanceOrSuppressFeatures` | Feature size, `Neurites` | `10` | Scale with process width in pixels. |
| `IdentifySecondaryObjects` | Threshold correction factor | `0.5` | **The main arbor-extent dial.** Lower includes more faint distal process; higher is conservative and will under-call ramification. |
| `IdentifySecondaryObjects` | Expansion, pixels | `10` | Minimum arbor growth around each soma. |
| `ExportToSpreadsheet` | Filename prefix | `ADD_PREFIX_` | Set to your own run identifier before every run. The prefix is prepended verbatim, so keep a trailing separator. The deposited example used `Test_`. |

The soma diameter range and the secondary threshold correction factor are the
two that decide whether the output is usable. Everything else is secondary.

### Quality control, which is not optional

Four images are written per input field: three overlays to look at, and the
binary mask the overlays were built from. Look at all three overlays before you
quantify anything.

| Suffix | Content | What a failure looks like |
|--------|---------|---------------------------|
| `*OIC.tiff` | whole-cell objects over the image | arbors fused between neighbouring cells, or truncated |
| `*SWS.png` | skeleton with soma overlaid | discontinuous skeleton, spurious loops, skeleton off-centre from the soma |
| `*QC.png` | cell and soma outlines on the original | soma mask inflated into proximal processes |
| `*MASK.png` | binary whole-cell mask, the segmented foreground itself | not an overlay and not an analysis input |

`*MASK.png` is written so that the exact foreground underlying the feature
tables is preserved beside them. That is what allows a segmentation to be
re-measured later, compared against another method on the same fields, or taken
into other software without rerunning the pipeline. It is also the image to
open when an overlay looks wrong and it is unclear whether the fault lies in the
mask or in the object assignment built on top of it.

Segmentation failure is far easier to see than to detect statistically, and it
distorts the **derived ratios** (`area_ratio`, cytoplasmic area) more than the
raw areas, because errors in soma and cell area push the ratio in opposite
directions. A dataset that looks plausible in summary statistics can still be
built on bad masks. Fix the overlays, then analyse.

---

## Stage 3: `R_Scripts/`

Five scripts, run **in order, in a single R session**. Each builds on objects
left by the previous one, so they cannot be run out of order or in isolation.

| Script | Does | Key parameter |
|--------|------|---------------|
| `01_Load_packages.R` | installs missing CRAN packages and loads them | none; every dependency is on CRAN |
| `02_Import_Data.R` | merges the soma and cell tables, derives composite features | **two file paths at the top, edit these first** |
| `03_Wins_Filtering_PCA.R` | winsorisation, Mahalanobis filtering, median/IQR scaling, PCA | `max_remove_pct = 0.005` |
| `04_Clustering_UMAP.R` | k selection, k-means, UMAP for display | `default_k = 6`, override after seeing the elbow plot |
| `05_Morpho_Enrichment.R` | per-cluster feature enrichment, as row z-scores with adjusted p values | none; reads what `04` produced |

Everything the analysis calls is on CRAN. No step uses a Bioconductor package:
Mahalanobis distance, PCA and k-means come from `stats` in base R, and the
embedding from `uwot`.

`02_Import_Data.R` opens with two paths that must point at the
`*Soma_Filtered.txt` and `*Cell.txt` tables **from the same CellProfiler run**.
The merge keys on `FileName_Original_Iba1`, `ImageNumber` and
`Parent_Soma_Merged`, all of which are assigned per run, so tables from two
different runs merge to zero rows.

`04` produces clusters; `05` is what tells you what those clusters are made of.
k-means returns groups, not phenotypes, and naming a feature combination as a
morphological state is an interpretive step rather than an output of the script.

---

## Reporting

If you publish results produced with this toolbox, report the soma diameter
range, both threshold settings, the median filter radius, and your pixel size.
Those five numbers are what make a MicroFace result comparable between labs.
Please also cite the paper, as given in
**[../README.md](../README.md)**.
