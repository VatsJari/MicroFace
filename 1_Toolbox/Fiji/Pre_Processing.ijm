// Ask user to select INPUT folder
input = getDirectory("Select INPUT folder (Raw images)");
if (input == "") {
    exit("No input folder selected. Exiting.");
}

// Ask user to select OUTPUT folder
output = getDirectory("Select OUTPUT folder (Preprocessed images)");
if (output == "") {
    exit("No output folder selected. Exiting.");
}

// Ensure proper path formatting (getDirectory already adds trailing slash, but just in case)
if (!input.endsWith("/")) {
    input = input + "/";
}
if (!output.endsWith("/")) {
    output = output + "/";
}

print("Input folder:  " + input);
print("Output folder: " + output);

list = getFileList(input);
setBatchMode(true);

for (i = 0; i < list.length; i++) {
    // Skip if it's a directory or hidden file
    if (list[i].endsWith("/") || list[i].startsWith(".")) {
        continue;
    }

    // Open the file
    open(input + list[i]);

    // Check if an image was actually opened
    if (nImages == 0) {
        print("Failed to open: " + list[i]);
        continue;
    }

    title = getTitle();
    run("Enhance Contrast...", "saturated=1.0 normalize");
    run("Subtract Background...", "rolling=50");
    run("Duplicate...", "title=background");
    run("Median...", "radius=20");
    imageCalculator("Subtract create", title, "background");

    // Save with proper extension
    saveAs("Tiff", output + list[i]);
    close("*");
}
setBatchMode(false);
print("Processing complete!");