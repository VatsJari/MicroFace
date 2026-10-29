# 01_Raw_Images

**Contents: empty. Download from Zenodo.**

Twelve raw single-channel Iba1 immunofluorescence TIFFs, about 23 MB each,
264 MB in total. Download `01_Raw_Images` from the Zenodo archive and place the
TIFFs in this folder.

**Zenodo: ZENODO_LINK_PENDING**

```
R<animal>_<timepoint>_<section>_Iba1_<image>.tif
R33_8wpi_11_Iba1_3.tif
```

Timepoints present: 4 hpi, 14 dpi, 8 wpi, 18 wpi. The animal and timepoint
fields are the only metadata the pipeline needs, and CellProfiler carries the
filename into every output table, so sample identity stays recoverable at the
single-cell level without a separate metadata join.

Skip this folder if you are starting from `03_Pre_processed_Images` or later.

**Next:** [step 2](../02_Fiji_Pre-processing_Macro/) · [tutorial](../README.md)
