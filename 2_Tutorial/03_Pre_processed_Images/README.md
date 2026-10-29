# 03_Pre_processed_Images

**Contents: empty. Either produce them in step 2, or download from Zenodo.**

The 12 pre-processed TIFFs from step 2, written under their original filenames.
The deposited copy is 3.5 GB, so if you can run step 2 yourself, do that
instead of downloading.

**Zenodo: ZENODO_LINK_PENDING**

These are the input to CellProfiler in step 4. Do not feed the raw images from
`01_Raw_Images` to step 4; the pipeline's thresholds assume pre-processed input.

One note on the deposited copy: it also contains the three CellProfiler QC
overlays per image (`*OIC.tiff`, `*SWS.png`, `*QC.png`), because the original
run wrote its output back into its own input directory. Those are duplicates of
`05_Quality_Check_Mask_Outputs` and are **not** pipeline inputs. When you run
step 4 yourself, point the output folder at `05_` to keep the two separate.

**Next:** [step 4](../04_Skeleton_Pipeline/) · [tutorial](../README.md)
