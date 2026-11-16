# 05_Quality_Check_Mask_Outputs

**Contents: empty. Produced by step 4, or extracted from the Zenodo archive to compare
against ours (3.3 GB).**

**Zenodo: [10.5281/zenodo.24278540](https://doi.org/10.5281/zenodo.24278540)**

Four files per image, 48 for 12 images: three overlays to look at, and the
binary mask they were built from. **Look at all three overlays before
quantifying anything.**

| Suffix | Shows | Failure looks like |
|--------|-------|--------------------|
| `*OIC.tiff` | whole-cell objects over the image | arbors fused between neighbours, or truncated |
| `*SWS.png` | skeleton with soma overlaid | broken skeleton, spurious loops, skeleton off-centre |
| `*QC.png` | cell and soma outlines on the original | soma mask inflated into proximal processes |
| `*MASK.png` | the binary whole-cell mask itself | not an overlay, and not an analysis input |

File names carry the `_Processed` suffix of the image they came from, for
example `R33_8wpi_11_Iba1_3_Processed_QC.png`.

`*MASK.png` is kept so that the exact segmented foreground underlying the
feature tables travels with them. It is what lets a segmentation be re-measured
later, compared against another method on the same fields, or taken into other
software without rerunning the pipeline, and it is the image to open when an
overlay looks wrong and it is unclear whether the fault is in the mask or in the
object assignment built on top of it.

This folder exists because segmentation failure is far easier to see than to
detect statistically, and because it distorts the derived ratios more than the
raw measurements: an inflated soma mask shrinks the arbor estimate at the same
time, so `area_ratio` and cytoplasmic area move in opposite directions. A
dataset can look entirely reasonable in summary statistics and still rest on
bad masks.

If the overlays disagree with the images, adjust the soma diameter range and the
secondary threshold correction factor, then rerun step 4.

**Next:** [step 6](../06_Datasheet/) · [tutorial](../README.md)
