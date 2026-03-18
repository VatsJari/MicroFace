// Ask for folder ONCE
dir = getDirectory("Choose folder with images");
files = getFileList(dir);

output = "X,Y,Image\n";

for (i = 0; i < files.length; i++) {
    open(dir + files[i]);
    title = getTitle();

    waitForUser("Use POINT TOOL, click ONE point,\nthen press OK");

    getSelectionCoordinates(xp, yp);
    x = xp[0];
    y = yp[0];

    output = output + x + "," + y + "," + title + "\n";

    close();
}

// Save (old ImageJ compatible)
saveDir = getDirectory("Choose folder to save CSV");
savePath = saveDir + "coordinates.csv";
File.saveString(output, savePath);

print("Saved to: " + savePath);
