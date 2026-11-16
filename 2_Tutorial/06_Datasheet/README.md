# 06_Datasheet

**Contents: empty. Produced by step 4, or extracted from the Zenodo archive (25 MB once extracted).**

**Zenodo: [10.5281/zenodo.24278540](https://doi.org/10.5281/zenodo.24278540)**

This is the smallest download that still lets you do real work. If you only
want the morphometric analysis, take this folder and go straight to step 7.

Tab-delimited, one row per object.

File names begin with the prefix you set in `ExportToSpreadsheet` at step 4.
The deposited copy was exported with `Test_`.

| File | Rows | Role |
|------|------|------|
| `Test_Soma_Filtered.txt` | 18,680 | **analysis input**: soma shape + skeleton topology |
| `Test_Cell.txt` | 18,680 | **analysis input**: whole-cell shape |
| `Test_Soma_Merged.txt` | 19,373 | intermediate, provenance only |
| `Test_Soma_first.txt` | 20,446 | intermediate, provenance only |
| `Test_Image.txt` | 12 | per-image counts, thresholds, module timings |
| `Test_Experiment.txt` | 338 | run provenance, full pipeline text |
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
