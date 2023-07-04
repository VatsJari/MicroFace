![image](https://user-images.githubusercontent.com/85255019/226131956-84d1a69f-b6c7-4e44-b58d-b28e923d4456.png)

## Abstract

The implantation of flexible neural probes induces traumatic brain injury (TBI) and triggers neuroinflammation, affecting probe performance. Microglia, the brain's resident immune cells, play a critical role in initiating and sustaining neuroinflammation. Activated microglia undergo morphological changes, transitioning from a resting, highly branched state to an amoeboid shape, indicative of specific functions in neuroinflammation. However, microglia can also exhibit intermediate forms between amoeboid and branched states, with morphology and function varying during processes such as migration, phagocytosis, and process extension/retraction. Traditional methods for measuring microglial morphology can be labor-intensive and prone to errors, making automated image analysis a valuable alternative.

To address these challenges, we developed an automated image analysis approach using Iba1-immunostained microglial images from a TBI rat model implanted with flexible neural probes. The methodology involved multiple stages, including preprocessing, illumination correction, skeleton reconstruction, and data clustering. This technique enabled the quantification of microglial morphology from microscopy images, yielding up to 79 morphological parameters for over 400,000 microglia.

The spatiotemporal distribution analysis revealed an increase in microglia cell density after acute injury at 1-, 2-, and 8-weeks post-implantation (WPI), indicating microglial proliferation toward the injury site. Hierarchical clustering analysis demonstrated a 95% similarity in morphology parameters between microglial cells near and far from the injury site at 2 WPI, suggesting a state of homeostasis. However, this homeostatic phase was disrupted at 8- and 18-WPI, potentially indicating chronic inflammation. Principal component analysis (PCA) of individual microglial cells identified 14 distinct morphotypes, grouped into four major phenotypes: amoeboid, highly branched, transitional, and rod-like microglia. The occurrence frequency of these phenotypes revealed three spatial distribution zones related to TBI: activated, intermediate, and homeostatic zones.

In summary, our automated tool for classifying microglial morphological phenotypes provides a time-efficient and objective method for characterizing microglial changes in the TBI rat model and potentially in human brain samples. Furthermore, this tool is not limited to microglia and can be applied to various cell types.




## Experimental Design 

In this project, a rat model of neuroinflammation was used to develop an automated workflow for quantifying microglia morphology over an extended implantation period. The effects of flexible neural probe implantation on microglial morphology were investigated, aiming to identify features sensitive to different activation states. Animals were sacrificed at various time points (0-18WPI), and brain sections were subjected to immunohistochemistry. Microscopic images from the cortex region were processed using Fiji for brightness and contrast adjustment, followed by analysis using a CellProfiler pipeline. This pipeline corrected illumination inconsistencies and generated a skeleton representation of microglia, allowing measurement of parameters related to their shape and size. The resulting data were then subjected to analysis using techniques such as PCA, hierarchical clustering, and statistical analysis in R Studio. The workflow provided valuable insights into the structure and spatiotemporal distribution of microglia.

![Copy of Untitled (6)](https://github.com/vatsal-jari/MicroFace.github.io/assets/85255019/ec2c58c0-ea53-408d-bb5e-21f7f61fd9cc)

## Imaging Analysis

The acquisition of image data involved several steps, including pre-processing, illumination correction, and automated segmentation. Through these processes, we were able to successfully reconstruct over 400,000 microglia cells from a dataset comprising more than 200 images.

### Image Pre-processing

In our study, we utilized Fiji software for the preprocessing of images, following the workflow depicted in Figure below, The initial step involved adjusting the brightness and contrast of the images using the "AUTO" mode in Fiji. This automated feature calculates the minimum and maximum intensity values in the image and scales the pixel values accordingly, resulting in a balanced distribution of pixel intensities across the image.

Next, we applied the rolling ball method with a radius of 50 pixels to subtract the image background. This technique effectively removes the background, enhancing the clarity of the image for further analysis. By placing a ball of the chosen radius over each pixel and calculating the average intensity within the ball, we obtained a background intensity map, which was subtracted from the original image.

To enhance image contrast, we employed the saturation pixel method, which sets a small percentage (1%) of the brightest and darkest pixels in the image to pure white and black, respectively [97]. This further improved the visibility of image features.

The workflow steps are visually represented in Appendix Figure 1. In rare cases where the background quality was particularly poor, manual pixel subtraction was performed as needed.
