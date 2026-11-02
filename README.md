# MicroFace: automated toolbox for microglia morphology analysis

<img width="790" height="470" alt="cover_page_2" src="https://github.com/user-attachments/assets/48b1388d-c3ac-4b75-bba3-5bd5405f47e2" />

MicroFace quantifies microglial morphology at single-cell scale from Iba1
immunofluorescence images. It segments soma and arbor as **two separate
objects**, skeletonises the arbor, extracts a multidimensional morphometric
feature set per cell, and resolves that feature space into morphological states
and their spatial organisation around a brain microinjury.

The approach reconstructed **over 250,000 microglia from more than 200 images**
in the associated publication.

---

## Start here: which folder do you want?

| Folder | For | What it is |
|--------|-----|------------|
| **[1_Toolbox](1_Toolbox/)** | "I want to run MicroFace on my own images" | The two pipeline files, nothing else. A Fiji pre-processing macro and the CellProfiler segmentation and skeletonisation pipeline. |
| **[2_Tutorial](2_Tutorial/)** | "Teach me how to use it, end to end" | A guided walkthrough on a small worked example, from raw image to clustered single-cell data. Start here if you are new. |
| **[3_Manuscript_iScience_2026](3_Manuscript_iScience_2026/)** | "I am reviewing or reproducing the paper" | The exact scripts and pipelines behind the iScience 2026 figures, frozen as the record of the publication. |

If you are not sure, go to **[2_Tutorial](2_Tutorial/)**.

The toolbox and the manuscript folder are not interchangeable. The manuscript
folder holds the parameters used for the published figures; the toolbox holds
the current, generalised pipeline. They will not give identical numbers.

---

## What MicroFace measures

Each cell yields soma-level shape, whole-cell shape, and skeleton topology,
which are then combined into derived features. The ones that carry most of the
biological signal:

| Feature | Definition | Interpretation |
|---------|------------|----------------|
| Ramification index | perimeter-to-area, normalised against a circle of equal area | arbor complexity independent of cell size; falls as cells de-ramify |
| Branch endpoints, trunks, non-trunk branches | counted outward along the skeleton from the soma | arbor topology, the most direct readout of surveillance capacity |
| Skeleton length | total skeleton length per cell | absolute process extent |
| Area ratio | whole-cell area divided by soma area | territory per unit cell body, a soma-versus-arbor rebalancing readout |
| Solidity, circularity, form factor | shape compactness descriptors | sensitive to the shift toward amoeboid morphology |
| Length-to-width and aspect ratio | Feret and axis ratios, soma and cell | elongation and polarisation, captures rod-like morphology |

Because soma and arbor are segmented independently, soma enlargement and arbor
retraction are measured separately rather than confounded in a single
whole-cell mask. That separation is what lets the method resolve intermediate
states instead of forcing cells into a ramified-versus-amoeboid dichotomy.

---

## Imaging data

This repository is **code only**. The images and feature tables are far too
large to host here (the pre-processed images and QC overlays alone exceed 6 GB).

All data for the tutorial is deposited on Zenodo:

**[10.5281/zenodo.20325902](https://doi.org/10.5281/zenodo.20325902)**

The archive uses the same seven numbered folders as
[2_Tutorial](2_Tutorial/), so a downloaded folder drops straight into the
matching one. See [2_Tutorial/README.md](2_Tutorial/README.md) for which
folders you actually need, which depends on how far through the workflow you
want to go.

Public transcriptomic datasets referenced in the paper are available through
GEO. Anything else required for reanalysis can be requested from the
corresponding author.

---

## Also available: MicroFaceV2

[**MicroFace_V2**](https://github.com/VatsJari/MicroFace_V2) is an installable
R package that wraps the analysis half of this workflow in a documented
function API, with Gaussian mixture clustering and k-selection helpers. Use it
when you want to script the analysis rather than follow it step by step. It is
a generalised reimplementation and does not reproduce the published numbers.

---

## Citation

> Jariwala, V.D., Ponnamma, S., Ravi, V.M., Beck, J., Hofmann, U.G., and
> Joseph, K. (2026). MicroFace maps microglial morphology remodeling, revealing
> spatial zones and bifurcated trajectories during brain microinjury recovery.
> *iScience* **29**, 116485.
> https://doi.org/10.1016/j.isci.2026.116485

If you use the deposited dataset, please cite it as well:

> Jariwala, V.D., Ponnamma, S., Ravi, V.M., Beck, J., Hofmann, U.G., and
> Joseph, K. (2026). MicroFace: single-cell microglial morphology pipeline,
> example dataset and analysis scripts [Data set]. *Zenodo*.
> https://doi.org/10.5281/zenodo.20325902

---

## Contact

vatsjari@gmail.com 

For problems with the code, please open an issue on this repository rather than
emailing, so the answer is visible to other users.
