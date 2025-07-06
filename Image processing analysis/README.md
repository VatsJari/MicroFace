

*******
## Imaging Analysis

The acquisition of image data involved several steps, including pre-processing, illumination correction, and automated segmentation. Through these processes, we were able to successfully reconstruct over 400,000 microglia cells from a dataset comprising more than 200 images.


*******

### Image Pre-processing

In our study, we utilized Fiji software for the preprocessing of images, following the workflow depicted in Figure below, The initial step involved adjusting the brightness and contrast of the images using the "AUTO" mode in Fiji. This automated feature calculates the minimum and maximum intensity values in the image and scales the pixel values accordingly, resulting in a balanced distribution of pixel intensities across the image. Next, we applied the rolling ball method with a radius of 50 pixels to subtract the image background. This technique effectively removes the background, enhancing the clarity of the image for further analysis. To enhance image contrast, we employed the saturation pixel method, which sets a small percentage (1%) of the brightest and darkest pixels in the image to pure white and black, respectively.

![Untitled (17)](https://github.com/vatsal-jari/MicroFace.github.io/assets/85255019/ff531a23-6052-4ece-b216-12beff3a4824)


*******

### Illumination Correction 

The images we obtained had very high light intensity at the injury site, which could result in poor segmentation. To address this issue, we utilized the illumination correction module in CellProfiler. This module helped us remove the uneven background illumination from the microscope images, resulting in normalized and equalized cell intensities. This correction made it much easier to identify and accurately segment individual cells.

Illumination correction is a process used to fix lighting issues in images. Imagine taking a photo where some parts are too bright and others are too dark. Illumination correction helps balance the lighting across the image, so it looks more natural and easier to see. It adjusts the brightness and contrast to make sure all the details are clear and visible. 

![Untitled (9)](https://github.com/vatsal-jari/MicroFace.github.io/assets/85255019/e1ec9c99-e89d-4c95-bbc5-d9059826d522)


*******
### The Skeleton Pipeline

![Untitled (18)](https://github.com/vatsal-jari/MicroFace.github.io/assets/85255019/25a8ebab-e8dc-40ce-80dd-fb363d7b3bb3)


*******
