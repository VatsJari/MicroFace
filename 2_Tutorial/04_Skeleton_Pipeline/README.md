# 04_Skeleton_Pipeline

**Pipeline:** [`../../1_Toolbox/CellProfiler/Skeleton_Pipeline.cpproj`](../../1_Toolbox/CellProfiler/Skeleton_Pipeline.cpproj)

A single authoritative copy lives in `1_Toolbox`. Requires CellProfiler 4.2.x.
The pipeline has 24 modules. This is the core of the method.

1. Open the pipeline in CellProfiler.
2. Drag the contents of `03_Pre_processed_Images` into the `Images` module.
   These are the files carrying the `_Processed` suffix.
3. Set the default output folder to `05_Quality_Check_Mask_Outputs` under
   `File > Preferences`, then set `Output file location` to
   `Default Output Folder` in all four `SaveImages` modules and in
   `ExportToSpreadsheet`. They ship pointing at paths from the machine the
   pipeline was developed on, so left unchanged the overlays land beside the
   input images and the export fails after the analysis has already run.
4. In `ExportToSpreadsheet`, replace the `ADD_PREFIX_` filename prefix with your
   own. It is prepended verbatim, so keep a trailing separator; the deposited
   example used `Test_`.
5. Press `Start Test Mode` and step through one image before running all 12.
6. `Analyze Images`. Roughly an hour for 12 images.

Soma and arbor are segmented as separate objects and paired afterwards. Expect
these counts on the example data:

```
Soma_first      20,446
Soma_Merged     19,373
Soma_Filtered   18,680
Cell            18,680
```

Substantially different counts mean the soma diameter range (in **pixels**) does
not match your images.

Per image the run writes four files to `05_` (three overlays and the binary
whole-cell mask) and, for the dataset as a whole, six tab-delimited tables to
wherever `ExportToSpreadsheet` points.

Parameter reference: [`../../1_Toolbox/README.md`](../../1_Toolbox/README.md).
Guided run: [tutorial step 4](../README.md#step-4-segmentation-and-skeletonisation).

**Next:** [step 5](../05_Quality_Check_Mask_Outputs/) · [tutorial](../README.md)
