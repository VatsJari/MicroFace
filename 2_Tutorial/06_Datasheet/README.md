# 06_Datasheet

**Contents: empty. Produced by step 4, or download from Zenodo (23 MB).**

**Zenodo: ZENODO_LINK_PENDING**

This is the smallest download that still lets you do real work. If you only
want the morphometric analysis, take this folder and go straight to step 7.

Tab-delimited, one row per object.

| File | Rows | Role |
|------|------|------|
| `_TestSoma_Filtered.txt` | 18,680 | **analysis input**: soma shape + skeleton topology |
| `_TestCell.txt` | 18,680 | **analysis input**: whole-cell shape |
| `_TestSoma_Merged.txt` | 19,373 | intermediate, provenance only |
| `_TestSoma_first.txt` | 20,446 | intermediate, provenance only |
| `_TestImage.txt` | 12 | per-image counts, thresholds, module timings |
| `_TestExperiment.txt` | 318 | run provenance, full pipeline text |
| `Injury_Center.csv` | 291 | implant centre coordinates |

Only the first two are read by the R scripts. Soma pairs to cell on
`Parent_Soma_Merged`.

The skeleton measures sit in the **soma** table, not the cell table, because
`MeasureObjectSkeleton` is seeded on `Soma_Filtered`: trunks, non-trunk
branches and endpoints are counted outward from the cell body along the arbor.

`Injury_Center.csv` covers the full published cohort and uses the study's
`*_FilteredSubtracted.tif` filenames, so it does not key directly onto these 12
images. Match on animal and section fields if you adapt it.

**Next:** [step 7](../07_RStudio_Analysis_Scripts/) · [tutorial](../README.md)
