# Image processing analysis

This folder contains the two image-processing stages of **MicroFace**: batch
pre-processing in [Fiji](https://fiji.sc/), and segmentation plus
skeletonisation in [CellProfiler](https://cellprofiler.org/). Together they
turn raw Iba1 immunofluorescence TIFFs into per-cell morphometric feature
tables and the QC overlays needed to trust them.

Run these stages **before** anything in `../Data analysis/`.

---

## Contents

| File | Stage | Purpose |
|------|-------|---------|
| `Fiji/Auto_Brightness.ijm` | 1 | Batch pre-processing of raw TIFFs |
| `Cellprofiler/The_Skeleton_Pipeline.cpproj` | 2 | Soma and arbor segmentation, skeletonisation, feature export |
| `Fiji/Injury_Center.ijm` | 3 | Manual implant-centre picking, writes `coordinates.csv` |
| `Cellprofiler/Valdidation_Pipeline.cpproj` | optional | Manual-versus-automated segmentation validation (Figure 2) |
| `Fiji/Cluster_Crop.ijm` | optional | Per-cluster single-cell crops, run after clustering |
| `Fiji/Cluster_Crop_montage.ijm` | optional | As above, plus per-cluster stacks and montages |

> The filename `Valdidation_Pipeline.cpproj` contains a typo. It is left
> unchanged so that paths referenced elsewhere stay valid.

---

## Stage 1: pre-processing in Fiji

**Macro:** `Fiji/Auto_Brightness.ijm`

Open Fiji and run `Plugins > Macros > Run...`, then select the macro. It
prompts for an input folder and an output folder, and processes every `.tif`
or `.tiff` in the input folder in batch mode.

Per image, in order:

1. **Convert to 16-bit.** Normalises bit depth across sections acquired in
   different sessions.
2. **Subtract Background**, rolling-ball radius **50 px**. Removes the
   low-frequency autofluorescence pedestal while leaving fine processes intact.
   The radius is set well above the width of a microglial process, so the
   estimate is of background rather than of signal.
3. **Enhance Contrast**, `saturated=0.35 normalize`. Clips the top and bottom
   0.35% of the intensity histogram and rescales, which equalises dynamic range
   across images so that a single adaptive threshold in CellProfiler behaves
   consistently.

Why this matters downstream: if contrast is not equalised first, adaptive
thresholding in Stage 2 fuses neighbouring process fields in densely populated
regions such as the peri-implant zone, which inflates skeleton length and
collapses the distinction between a ramified and a reactive cell.

![Fiji pre-processing](https://github.com/vatsal-jari/MicroFace.github.io/assets/85255019/ff531a23-6052-4ece-b216-12beff3a4824)

---

## Stage 2: segmentation and skeletonisation in CellProfiler

**Pipeline:** `Cellprofiler/The_Skeleton_Pipeline.cpproj`
**Requires:** CellProfiler 4.2 or later

1. Open the project in CellProfiler.
2. Drag the **pre-processed** images from Stage 1 into the `Images` module.
   Do not use the raw images.
3. Set the default output folder to a new, empty directory.
4. In `ExportToSpreadsheet`, set the filename prefix to a run identifier of
   your own.
5. Press **Analyze Images**.

### What the pipeline does

The pipeline resolves **soma and arbor as two separate objects** and then pairs
them, rather than segmenting the whole cell in one pass. This is what makes
soma-level and arbor-level features independently measurable on the same cell,
and it is the core of the method.

The object chain is:

```
soma candidates  ->  merged soma  ->  soma with a complete arbor  ->  paired whole cell
                                      (border-touching cells dropped)
```

Border-touching cells are discarded together with their parent soma. This is
deliberate: an arbor clipped by the edge of the field of view would otherwise
enter the dataset as a spuriously low-complexity cell and bias the
ramified-to-reactive axis.

The arbor is then converted to a binary mask, skeletonised, and measured with
the soma as the seed object, so trunks, non-trunk branches and branch endpoints
are counted outward along the skeleton from the cell body.

### Outputs

- **Feature tables**, tab-delimited, one row per object. The soma table carries
  the skeleton topology measures; the cell table carries whole-cell shape. Both
  are needed by `../Data analysis/Scripts/02_Import_Data.R`.
- **Three QC overlays per image**, described below.

### Illumination correction

Images acquired at the implant site were frequently overexposed, which
compromised segmentation. Intensity is normalised inside the pipeline before
object detection so that thresholds are comparable across the field.

![Illumination correction](https://github.com/vatsal-jari/MicroFace.github.io/assets/85255019/e1ec9c99-e89d-4c95-bbc5-d9059826d522)

---

## Quality control: inspect these before quantifying anything

The pipeline writes three overlays per image. Check all of them. Segmentation
failures are far easier to see than to detect statistically, and they distort
the derived ratios more than they distort the raw areas.

| Suffix | Content | What to look for |
|--------|---------|------------------|
| `*OIC.tiff` | Whole-cell objects over the image | Arbors neither truncated nor fused between neighbouring cells |
| `*SWS.png` | Skeleton with soma overlaid | Skeleton continuous, centred on the soma, no spurious loops |
| `*QC.png` | Cell and soma outlines on the original | Soma boundary follows the cell body, not an enlarged thresholded blob |

If the overlays disagree with the image, adjust the soma diameter range in
`IdentifyPrimaryObjects` and the threshold correction factor in
`IdentifySecondaryObjects`, then rerun. Do not proceed to the R analysis on
segmentation you have not looked at.

![Skeleton pipeline](https://github.com/vatsal-jari/MicroFace.github.io/assets/85255019/25a8ebab-e8dc-40ce-80dd-fb363d7b3bb3)

---

## Stage 3: implant-centre coordinates

**Macro:** `Fiji/Injury_Center.ijm`

Required for every spatial result in the paper: radial distance, the three
impact regions, and the spatial-zone analysis.

The macro opens each image in a folder in turn and waits for you to mark the
implant centre:

1. Run the macro and select the folder of images.
2. For each image, select the **point tool**, click **once** on the implant
   centre, then press OK.
3. When all images are done, choose a save folder.

It writes `coordinates.csv` with columns `X,Y,Image`. A reference copy for the
published dataset is in `../Data analysis/Datasheet/Injury_Center/`.

Two cautions. The coordinate is picked by hand, so it is the one subjective
step in the workflow; mark the geometric centre of the implant track
consistently across images, because radial distance is measured from this point
and a systematic offset shifts every downstream bin. The `Image` column must
match the filenames the R scripts see, or the spatial join silently drops rows.

---

## Optional: validation pipeline

**Pipeline:** `Cellprofiler/Valdidation_Pipeline.cpproj`

Produces the manual-versus-automated comparison tables used in Figure 2.
Reference outputs are in `../Data analysis/Datasheet/validation/`. Of those,
`Validation_IdentifyPrimaryObjects.csv`, `Validation_Soma_Filtered.csv` and
`Validation_Cell.csv` are the three that `Figure_2.R` actually reads; the
others are included for completeness.

---

## Optional: per-cluster cell crops

Run these **after** the R clustering, since they need cluster assignments.

- `Fiji/Cluster_Crop.ijm` prompts for crop width and height (default 50 x 50 px)
  and an image folder, then writes crops into per-cluster subfolders.
- `Fiji/Cluster_Crop_montage.ijm` does the same and additionally builds a stack
  and a montage per cluster, plus a master montage of all crops. It also asks
  for the number of montage columns (default 10).

These produce the representative single-cell panels. They are presentation
tools, not analysis: nothing downstream depends on them.

---

## Next step

Continue with **[../Data analysis/README.md](../Data%20analysis/README.md)**.
