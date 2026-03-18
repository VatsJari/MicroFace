

![image](https://user-images.githubusercontent.com/85255019/226131956-84d1a69f-b6c7-4e44-b58d-b28e923d4456.png)

# Microglial Morphology Analysis Pipeline

This repository provides a complete, reproducible R workflow for analyzing microglial morphology from high‑content imaging data. The pipeline processes raw CellProfiler output (soma and cell feature tables), performs rigorous quality control, and applies advanced dimensionality reduction (PCA, UMAP, PHATE) and clustering to identify distinct morphological states. It generates all figures used in the associated publication, including radial distribution plots, validation scatter plots, feature correlation heatmaps, NMF‑based program discovery, and phenotype‑specific visualizations. Designed for clarity and reproducibility, the code is modular and well‑documented, enabling easy adaptation to similar neuroinflammation or cell morphology studies.
*******

## Experimental Design 

In this project, a rat model of neuroinflammation was used to develop an automated workflow for quantifying microglia morphology over an extended implantation period. The effects of flexible neural probe implantation on microglial morphology were investigated, aiming to identify features sensitive to different activation states. Animals were sacrificed at various time points (0-18WPI), and brain sections were subjected to immunohistochemistry. Microscopic images from the cortex region were processed using Fiji for brightness and contrast adjustment, followed by analysis using a CellProfiler pipeline. This pipeline corrected illumination inconsistencies and generated a skeleton representation of microglia, allowing measurement of parameters related to their shape and size. The resulting data were then subjected to analysis using techniques such as PCA, hierarchical clustering, and statistical analysis in R Studio. The workflow provided valuable insights into the structure and spatiotemporal distribution of microglia.

![Copy of Untitled (6)](https://github.com/vatsal-jari/MicroFace.github.io/assets/85255019/ec2c58c0-ea53-408d-bb5e-21f7f61fd9cc)




