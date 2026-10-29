// Batch process TIF/TIFF images

inputDir = getDirectory("Choose input folder");
outputDir = getDirectory("Choose output folder");

list = getFileList(inputDir);

setBatchMode(true); // speeds up processing

for (i = 0; i < list.length; i++) {
    name = list[i];
    
    if (endsWith(name, ".tif") || endsWith(name, ".tiff")) {
        open(inputDir + name);
        
        // Convert to 16-bit
        run("16-bit");
        
        // Background subtraction (rolling ball radius = 50)
        run("Subtract Background...", "rolling=50");
        
        // Enhance contrast: 0.35% saturated, normalized
        run("Enhance Contrast...", "saturated=0.35 normalize");
        
        // Save to output folder
        saveAs("Tiff", outputDir + name);
        
        close();
    }
}

setBatchMode(false);
print("Done!");
