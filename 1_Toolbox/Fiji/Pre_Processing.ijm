/*
 * Fiji / ImageJ Macro
 * Batch pre-processing of raw images:
 *   - open image
 *   - convert to 8-bit
 *   - enhance contrast (normalize, 1% saturated)
 *   - subtract background (rolling ball, radius 50)
 *   - subtract median-filtered background (radius 20)
 *   - ensure output is 8-bit
 *   - save as TIFF to OUTPUT folder with "_Processed" suffix
 */

// ---------- 1. Choose folders ----------
inputDir = getDirectory("Select INPUT folder (Raw images)");
if (inputDir == "") exit("No input folder selected. Exiting.");

outputDir = getDirectory("Select OUTPUT folder (Preprocessed images)");
if (outputDir == "") exit("No output folder selected. Exiting.");

// Normalise trailing slashes
if (!endsWith(inputDir,  "/")) inputDir  = inputDir  + "/";
if (!endsWith(outputDir, "/")) outputDir = outputDir + "/";

print("Input folder : " + inputDir);
print("Output folder: " + outputDir);

// ---------- 2. Collect files ----------
fileList = getFileList(inputDir);
if (fileList.length == 0) exit("No files found in input folder.");

// Image extensions we will attempt to open (lower-case)
validExt = newArray(".tif", ".tiff", ".png", ".jpg", ".jpeg", ".bmp", ".gif", ".pgm", ".pnm", ".raw", ".czi", ".nd2", ".lif", ".oib", ".oif");

setBatchMode(true);

processed = 0;
skipped   = 0;

// ---------- 3. Process each file ----------
for (i = 0; i < fileList.length; i++) {

    name = fileList[i];

    // Skip hidden files and directories
    if (startsWith(name, ".") || endsWith(name, "/")) {
        skipped++;
        continue;
    }

    // Skip non-image extensions
    lowerName = toLowerCase(name);
    isImage = false;
    for (e = 0; e < validExt.length; e++) {
        if (endsWith(lowerName, validExt[e])) {
            isImage = true;
            break;
        }
    }
    if (!isImage) {
        print("Skipping non-image file: " + name);
        skipped++;
        continue;
    }

    // Open
    open(inputDir + name);

    if (nImages == 0) {
        print("Failed to open: " + name);
        skipped++;
        continue;
    }

    title = getTitle();

    // ---------- 3a. Convert to 8-bit BEFORE processing ----------
    if (bitDepth() != 8) {
        run("8-bit");
    }

    // ---------- 3b. Pipeline ----------
    run("Enhance Contrast...", "saturated=1.0 normalize");
    run("Subtract Background...", "rolling=50");

    // Duplicate, median-blur, subtract to remove residual low-frequency background
    run("Duplicate...", "title=background");
    run("Median...", "radius=20");
    imageCalculator("Subtract create", title, "background");

    // ---------- 3c. Ensure output is 8-bit ----------
    if (bitDepth() != 8) {
        run("8-bit");
    }

    // ---------- 3d. Build output filename with _Processed suffix ----------
    baseName = name;
    dotIdx = lastIndexOf(baseName, ".");
    if (dotIdx > 0) baseName = substring(baseName, 0, dotIdx);
    outName = baseName + "_Processed.tif";
    outPath = outputDir + outName;

    // ---------- 3e. Save ----------
    saveAs("Tiff", outPath);

    // Clean up all images from this iteration
    while (nImages > 0) close();

    processed++;
    print("Processed (" + processed + "): " + name + "  ->  " + outName);
}

// ---------- 4. Done ----------
setBatchMode(false);

print("--------------------------------------------------");
print("Processing complete.");
print("Processed: " + processed);
print("Skipped  : " + skipped);
print("--------------------------------------------------");