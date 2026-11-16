# 03_Pre_processed_Images

**Contents: empty. Either produce them in step 2, or extract them from the Zenodo archive.**

The 12 pre-processed TIFFs from step 2, 8-bit, written under their original
filenames with **`_Processed`** appended:

```
R33_8wpi_11_Iba1_3.tif   ->   R33_8wpi_11_Iba1_3_Processed.tif
```

The deposited copy is 264 MB. If you can run step 2 yourself, do that instead of
downloading.

**Zenodo: [10.5281/zenodo.24278540](https://doi.org/10.5281/zenodo.24278540)**

These are the input to CellProfiler in step 4. Do not feed the raw images from
`01_Raw_Images` to step 4; the pipeline's thresholds assume pre-processed input.

One thing to get right when you run step 4 yourself: the `SaveImages` modules
ship set to `Same folder as image`, which writes the overlays back into this
folder and means the next run loads them as input. Set the output folder to
`05_Quality_Check_Mask_Outputs` in all four `SaveImages` modules, as step 4
describes. The deposited copy of this folder holds the 12 processed images and
nothing else.

**Next:** [step 4](../04_Skeleton_Pipeline/) · [tutorial](../README.md)
