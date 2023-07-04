# MicroFace

## Abstract

The implantation of flexible neural probes induces traumatic brain injury (TBI) and triggers neuroinflammation, affecting probe performance. Microglia, the brain's resident immune cells, play a critical role in initiating and sustaining neuroinflammation. Activated microglia undergo morphological changes, transitioning from a resting, highly branched state to an amoeboid shape, indicative of specific functions in neuroinflammation. However, microglia can also exhibit intermediate forms between amoeboid and branched states, with morphology and function varying during processes such as migration, phagocytosis, and process extension/retraction. Traditional methods for measuring microglial morphology can be labor-intensive and prone to errors, making automated image analysis a valuable alternative.

To address these challenges, we developed an automated image analysis approach using Iba1-immunostained microglial images from a TBI rat model implanted with flexible neural probes. The methodology involved multiple stages, including preprocessing, illumination correction, skeleton reconstruction, and data clustering. This technique enabled the quantification of microglial morphology from microscopy images, yielding up to 79 morphological parameters for over 400,000 microglia.

The spatiotemporal distribution analysis revealed an increase in microglia cell density after acute injury at 1-, 2-, and 8-weeks post-implantation (WPI), indicating microglial proliferation toward the injury site. Hierarchical clustering analysis demonstrated a 95% similarity in morphology parameters between microglial cells near and far from the injury site at 2 WPI, suggesting a state of homeostasis. However, this homeostatic phase was disrupted at 8- and 18-WPI, potentially indicating chronic inflammation. Principal component analysis (PCA) of individual microglial cells identified 14 distinct morphotypes, grouped into four major phenotypes: amoeboid, highly branched, transitional, and rod-like microglia. The occurrence frequency of these phenotypes revealed three spatial distribution zones related to TBI: activated, intermediate, and homeostatic zones.

In summary, our automated tool for classifying microglial morphological phenotypes provides a time-efficient and objective method for characterizing microglial changes in the TBI rat model and potentially in human brain samples. Furthermore, this tool is not limited to microglia and can be applied to various cell types.


![image](https://user-images.githubusercontent.com/85255019/226131956-84d1a69f-b6c7-4e44-b58d-b28e923d4456.png)
