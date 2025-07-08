# 📁 Image Processing Analysis

This folder contains the image processing pipelines used in the **MicroFace** project, aimed at analyzing and reconstructing microglia cells from high-resolution microscopy images. Our analysis leverages open-source image processing tools like **Fiji** and **CellProfiler** to perform essential pre-processing, illumination correction, and segmentation tasks.

---

## 📌 Overview

The image acquisition and processing workflow involved several critical steps:

- **Pre-processing** of raw microscopy images.
- **Illumination correction** to normalize image brightness.
- **Automated segmentation** to extract cellular structures.

Using this pipeline, we successfully reconstructed **over 400,000 microglia cells** from a dataset of **more than 200 images**, providing a robust basis for downstream biological analysis.

---

## 🧪 Tools Used

- [**Fiji**](https://fiji.sc/) (ImageJ distribution)
- [**CellProfiler**](https://cellprofiler.org/)

---

## 🖼️ 1. Image Pre-processing (Fiji)

Pre-processing of microscopy images was performed in **Fiji**, following the steps below:

### 🔧 Brightness and Contrast Adjustment

- Used **"Auto" mode** to adjust brightness and contrast.
- This mode automatically scales the pixel intensity range to ensure a balanced distribution.

### 🧼 Background Subtraction

- Applied the **Rolling Ball algorithm** with a **radius of 50 pixels**.
- This method removes uneven background illumination and enhances image clarity.

### 🎨 Contrast Enhancement

- Employed the **saturation pixel method**:
  - Adjusts the image contrast by clipping the top and bottom **1%** of pixel intensity values.
  - This converts the darkest pixels to black and brightest to white, improving visual contrast.

![Untitled (17)](https://github.com/vatsal-jari/MicroFace.github.io/assets/85255019/ff531a23-6052-4ece-b216-12beff3a4824)


---

## 💡 2. Illumination Correction (CellProfiler)

Microscopy images often suffered from **overexposure at the injury site**, which compromised segmentation accuracy. To correct this, we used the **Illumination Correction** module in **CellProfiler**:

- Balances uneven lighting across the image.
- Normalizes cell intensities, making downstream segmentation more accurate.

> **Explanation:** Illumination correction works like applying a filter that evens out the brightness in a photo—making it easier to see and identify individual cells.

![Untitled (9)](https://github.com/vatsal-jari/MicroFace.github.io/assets/85255019/e1ec9c99-e89d-4c95-bbc5-d9059826d522)

---

## 🧬 3. Segmentation and Skeleton Pipeline

Following illumination correction, we applied **automated segmentation** and **skeletonization** techniques to reconstruct cellular morphology:

- The **Skeleton Pipeline** is designed to:
  - Identify and trace individual microglia structures.
  - Produce skeletonized representations of cells for morphological analysis.

Details of this pipeline are included in the `Skeleton_Pipeline.cppipe` and associated scripts within this folder.

![Untitled (18)](https://github.com/vatsal-jari/MicroFace.github.io/assets/85255019/25a8ebab-e8dc-40ce-80dd-fb363d7b3bb3)

---

## 📁 Folder Structure

Image Processing Analysis/
├── Fiji_Preprocessing_Steps.md
├── CellProfiler_Illumination_Correction.cppipe
├── Skeleton_Pipeline.cppipe
├── Example_Images/
│ ├── Before_Preprocessing/
│ └── After_Preprocessing/
├── Figures/
│ ├── pre_processing_workflow.png
│ └── illumination_correction_example.png
└── README.md


---

## 📌 How to Use

1. Open images in **Fiji** and follow the steps in `Fiji_Preprocessing_Steps.md`.
2. Run `CellProfiler_Illumination_Correction.cppipe` on the pre-processed images.
3. Use the `Skeleton_Pipeline.cppipe` to segment and extract skeletal features of microglia.
4. Output files will include:
   - Processed and corrected images.
   - Cell masks and skeleton data.







