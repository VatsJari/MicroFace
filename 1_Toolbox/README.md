# 1_Toolbox

The MicroFace pipeline, as two files you can drop into your own project. No
example data, no analysis scripts, no figure code. If you want to be walked
through it on a worked example first, go to
**[../2_Tutorial](../2_Tutorial/)**.

```
1_Toolbox/
├── Fiji/Pre_Processing.ijm                 stage 1: image pre-processing
└── CellProfiler/Skeleton_Pipeline.cpproj   stage 2: segmentation + skeletonisation
```

Run them in that order. Stage 2 expects the output of stage 1.

| | Requirement |
|---|---|
| Stage 1 | Fiji / ImageJ 1.53 or later |
| Stage 2 | CellProfiler 4.2.x |

What comes out: one tab-delimited feature table per object class, plus three QC
overlays per image. What you do with those tables is up to you; the tutorial
shows one route through R, and
[MicroFace_V2](https://github.com/VatsJari/MicroFace_V2) packages another.

---

## Stage 1: `Fiji/Pre_Processing.ijm`

In Fiji, `Plugins > Macros > Run...`, select the macro. It prompts for an input
folder and an output folder, then processes every file in the input folder in
batch mode.

Per image, in order:

1. `Enhance Contrast` with `saturated=1.0 normalize`, equalising dynamic range
   across sections stained and imaged in different sessions.
2. `Subtract Background` with `rolling=50`, removing the low-frequency
   autofluorescence pedestal.
3. Duplicate the image, apply a `Median` filter of **radius 20** to the
   duplicate, and subtract that median-filtered copy from the original.

**Step 3 is the one that matters, and the one to tune first.** The radius-20
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
| `ExportToSpreadsheet` | Filename prefix | `_ADD_PREFIX` | Set to your own run identifier before every run. |

The soma diameter range and the secondary threshold correction factor are the
two that decide whether the output is usable. Everything else is secondary.

### Quality control, which is not optional

Three overlays are written per image. Look at all of them before you quantify
anything.

| Suffix | Content | What a failure looks like |
|--------|---------|---------------------------|
| `*OIC.tiff` | whole-cell objects over the image | arbors fused between neighbouring cells, or truncated |
| `*SWS.png` | skeleton with soma overlaid | discontinuous skeleton, spurious loops, skeleton off-centre from the soma |
| `*QC.png` | cell and soma outlines on the original | soma mask inflated into proximal processes |

Segmentation failure is far easier to see than to detect statistically, and it
distorts the **derived ratios** (`area_ratio`, cytoplasmic area) more than the
raw areas, because errors in soma and cell area push the ratio in opposite
directions. A dataset that looks plausible in summary statistics can still be
built on bad masks. Fix the overlays, then analyse.

---

## Reporting

If you publish results produced with this toolbox, report the soma diameter
range, both threshold settings, the median filter radius, and your pixel size.
Those five numbers are what make a MicroFace result comparable between labs.
Please also cite the paper, as given in
**[../README.md](../README.md)**.
