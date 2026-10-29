// ============================================================
// FIJI MACRO — ROBUST CROPPING + PER‑CLUSTER STACKS/MONTAGES
// Extracts crops from matched images, saves in per‑cluster folders,
// then builds per‑cluster stacks and montages (rows = #images, cols = user choice).
// Also creates a master stack and montage of all crops.
// ============================================================

// ================= SETTINGS =================
cropW = getNumber("Crop width (px)", 50);
cropH = getNumber("Crop height (px)", 50);
montCols = getNumber("Montage columns", 10);

// ================= SELECT IMAGE FOLDER =================
inputDir = getDirectory("Select image folder");
fileList = getFileList(inputDir);

imgList = newArray();
for (i = 0; i < fileList.length; i++) {
    name = fileList[i];
    if (endsWith(name, ".tif") || endsWith(name, ".tiff") ||
        endsWith(name, ".png") || endsWith(name, ".TIF") ||
        endsWith(name, ".jpeg") || endsWith(name, ".JPEG") ||
        endsWith(name, ".TIFF") || endsWith(name, ".PNG")) {
        imgList = Array.concat(imgList, name);
    }
}

if (imgList.length == 0)
    exit("No images found");

print("Images found: " + imgList.length);
montRows = imgList.length;   // one row per image in montages
print("Montage rows set to: " + montRows);

// ================= LOAD CSV =================
csvPath = File.openDialog("Select CSV");
csvText = File.openAsString(csvPath);
csvText = replace(csvText, "\r", "");
lines = split(csvText, "\n");

// ================= OUTPUT =================
baseDir = getDirectory("Select output folder");
File.makeDirectory(baseDir + "All_Clusters/");

// ================= PARSE CSV =================
csvIDarr = newArray();      // animal ID (first column)
csvClusterArr = newArray();
csvXarr = newArray();
csvYarr = newArray();
clusters = newArray();

for (r = 1; r < lines.length; r++) {          // skip header
    line = trim(lines[r]);
    if (line == "") continue;

    f = split(line, ",");
    if (f.length < 4) continue;

    animalID = replace(trim(f[0]), "\"", "");
    clusterVal = replace(trim(f[1]), "\"", "");
    x = parseFloat(replace(trim(f[2]), "\"", ""));
    y = parseFloat(replace(trim(f[3]), "\"", ""));

    csvIDarr = Array.concat(csvIDarr, animalID);
    csvClusterArr = Array.concat(csvClusterArr, clusterVal);
    csvXarr = Array.concat(csvXarr, x);
    csvYarr = Array.concat(csvYarr, y);

    // Collect unique cluster names
    found = false;
    for (k = 0; k < clusters.length; k++)
        if (clusters[k] == clusterVal) found = true;
    if (!found)
        clusters = Array.concat(clusters, clusterVal);
}

print("CSV entries parsed: " + csvIDarr.length);

// ================= MATCHING FUNCTION =================
function matches(imgName, animalID) {
    dot = lastIndexOf(imgName, ".");
    if (dot == -1) imgBase = imgName;
    else imgBase = substring(imgName, 0, dot);

    dot = lastIndexOf(animalID, ".");
    if (dot == -1) animalBase = animalID;
    else animalBase = substring(animalID, 0, dot);

    return startsWith(imgBase, animalBase);
}

// ================= PROCESS =================
setBatchMode(true);
masterCount = 0;

// Prepare per‑cluster counters and folders
clusterCropCount = newArray(clusters.length);
for (ci = 0; ci < clusters.length; ci++) {
    clusterCropCount[ci] = 0;
    File.makeDirectory(baseDir + "Cluster_" + clusters[ci] + "/");
}

// Loop over all images
for (i = 0; i < imgList.length; i++) {
    imgName = imgList[i];
    imgPath = inputDir + imgName;
    open(imgPath);
    imgTitle = getTitle();
    imgW = getWidth();
    imgH = getHeight();

    // Loop over all CSV entries
    for (j = 0; j < csvIDarr.length; j++) {
        if (!matches(imgName, csvIDarr[j]))
            continue;

        // Get cluster index
        clusterVal = csvClusterArr[j];
        ci = -1;
        for (k = 0; k < clusters.length; k++)
            if (clusters[k] == clusterVal) { ci = k; break; }
        if (ci == -1) continue; // should never happen

        x = csvXarr[j];
        y = csvYarr[j];

        // Calculate crop rectangle
        x0 = round(x - cropW / 2);
        y0 = round(y - cropH / 2);
        if (x0 < 0) x0 = 0;
        if (y0 < 0) y0 = 0;

        cropW2 = cropW;
        cropH2 = cropH;
        if (x0 + cropW2 > imgW) cropW2 = imgW - x0;
        if (y0 + cropH2 > imgH) cropH2 = imgH - y0;

        if (cropW2 <= 0 || cropH2 <= 0) {
            print("Skipping: crop out of bounds for " + imgName +
                  " at (x=" + x + ", y=" + y + ")");
            continue;
        }

        // Ensure original image is active
        selectWindow(imgTitle);
        makeRectangle(x0, y0, cropW2, cropH2);
        wait(50); // let the rectangle be drawn

        title = "crop_" + clusterVal + "_" + clusterCropCount[ci];

        // --- Primary method: Duplicate ---
        run("Duplicate...", "title=" + title);
        if (nImages() > 0) {
            selectWindow(title);
            dupW = getWidth();
            dupH = getHeight();
        } else {
            dupW = 0; dupH = 0;
        }

        // If duplicate failed (zero dimensions), try fallback method
        if (dupW <= 0 || dupH <= 0) {
            print("Warning: Duplicate failed, using copy/paste fallback for " + imgName +
                  " at (x=" + x + ", y=" + y + ")");
            selectWindow(imgTitle);
            run("Copy");
            newImage(title, "8-bit black", cropW2, cropH2, 1);
            run("Paste");
            selectWindow(title);
            dupW = getWidth();
            dupH = getHeight();
        }

        if (dupW <= 0 || dupH <= 0) {
            print("ERROR: Could not create crop for " + imgName +
                  " at (x=" + x + ", y=" + y + "). Skipping.");
            if (nImages() > 0 && windowExists(title))
                close(title);
            continue;
        }

        // Convert to RGB if needed (PNG export works best with RGB)
        if (bitDepth != 24 && bitDepth != 8) {
            run("RGB Color");
        }
        wait(50);

        // Generate filename
        dot = lastIndexOf(imgName, ".");
        if (dot == -1) baseName = imgName;
        else baseName = substring(imgName, 0, dot);

        saveName = baseName + "_Cluster_" + clusterVal +
                   "_crop_" + clusterCropCount[ci] + ".png";

        // Save to cluster folder
        clusterDir = baseDir + "Cluster_" + clusterVal + "/";
        saveAs("PNG", clusterDir + saveName);

        // Also save to master folder
        saveAs("PNG", baseDir + "All_Clusters/" + saveName);

        close(title);
        clusterCropCount[ci]++;
        masterCount++;
    }
    // Close the original image after all its crops
    close(imgTitle);
}

// ================= PER‑CLUSTER STACKS AND MONTAGES =================
print("Building per‑cluster stacks and montages...");
for (ci = 0; ci < clusters.length; ci++) {
    clusterVal = clusters[ci];
    clusterDir = baseDir + "Cluster_" + clusterVal + "/";

    // Open all PNG crops for this cluster
    cropFiles = getFileList(clusterDir);
    opened = 0;
    for (f = 0; f < cropFiles.length; f++) {
        if (endsWith(cropFiles[f], ".png")) {
            open(clusterDir + cropFiles[f]);
            opened++;
        }
    }

    if (opened > 0) {
        // Create stack (keeps all open images as a stack)
        run("Images to Stack");
        stackTitle = "Stack_" + clusterVal;
        rename(stackTitle);
        selectWindow(stackTitle);
        saveAs("Tiff", clusterDir + "Cluster_" + clusterVal + "_stack.tif");

        // Create montage with fixed rows = number of images, cols = user choice
        run("Make Montage...", "columns=" + montCols + " rows=" + montRows + " scale=1");
        montTitle = getTitle();
        saveAs("PNG", clusterDir + "Cluster_" + clusterVal + "_montage.png");
        close(montTitle);
        close(stackTitle);
    } else {
        print("No crops found for cluster " + clusterVal + ", skipping stack/montage.");
    }
    run("Close All"); // extra safety
}

// ================= MASTER STACK AND MONTAGE =================
print("Building master stack and montage...");
masterDir = baseDir + "All_Clusters/";
masterList = getFileList(masterDir);
openedMaster = 0;
for (i = 0; i < masterList.length; i++) {
    if (endsWith(masterList[i], ".png")) {
        open(masterDir + masterList[i]);
        openedMaster++;
    }
}

if (openedMaster > 0) {
    run("Images to Stack");
    rename("MASTER");
    selectWindow("MASTER");
    saveAs("Tiff", baseDir + "MASTER_stack.tif");

    // For master, use dynamic rows based on slice count
    nSlices = getNSlices();
    if (nSlices > 0) {
        rows = ceil(nSlices / montCols);
        run("Make Montage...", "columns=" + montCols + " rows=" + rows + " scale=1");
        saveAs("PNG", baseDir + "MASTER_montage.png");
        close(getTitle()); // close montage
    }
    close("MASTER");
}
run("Close All");

setBatchMode(false);

// ================= SUMMARY =================
print("=================================");
print("ALL DONE!");
print("Total crops saved: " + masterCount);
for (ci = 0; ci < clusters.length; ci++) {
    print("Cluster " + clusters[ci] + ": " + clusterCropCount[ci] + " crops");
}
print("=================================");