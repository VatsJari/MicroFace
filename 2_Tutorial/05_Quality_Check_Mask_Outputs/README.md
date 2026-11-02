# 05_Quality_Check_Mask_Outputs

**Contents: empty. Produced by step 4, or download from Zenodo to compare
against ours (3.3 GB).**

**Zenodo: [10.5281/zenodo.20325902](https://doi.org/10.5281/zenodo.20325902)**

Three overlays per image, 36 files for 12 images. **Look at all of them before
quantifying anything.**

| Suffix | Shows | Failure looks like |
|--------|-------|--------------------|
| `*OIC.tiff` | whole-cell objects over the image | arbors fused between neighbours, or truncated |
| `*SWS.png` | skeleton with soma overlaid | broken skeleton, spurious loops, skeleton off-centre |
| `*QC.png` | cell and soma outlines on the original | soma mask inflated into proximal processes |

This folder exists because segmentation failure is far easier to see than to
detect statistically, and because it distorts the derived ratios more than the
raw measurements: an inflated soma mask shrinks the arbor estimate at the same
time, so `area_ratio` and cytoplasmic area move in opposite directions. A
dataset can look entirely reasonable in summary statistics and still rest on
bad masks.

If the overlays disagree with the images, adjust the soma diameter range and the
secondary threshold correction factor, then rerun step 4.

**Next:** [step 6](../06_Datasheet/) · [tutorial](../README.md)
