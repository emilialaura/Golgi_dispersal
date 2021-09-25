//Emilia Laura Munteanu 2021-07-01;
//update 2021-09-16: set background; detect Golgi object; manual adjust Golgi objects;
//save images and data for each cell; save log; 

//// parameters to beset by user /////////////////////////////
threshold = "Intermodes";   // thereshold method to determine Golgi
GolgiChannel = 2;         // channel to be analyzed for Golgi
//////////////////////////////////////////////////////////////

dir = getDirectory("image");
title = getTitle(); print(title);
dotIndex = lastIndexOf(title, ".");
if (isNaN(dotIndex) ) { basename = title; }
else {basename = substring(title, 0, dotIndex); }


roiManager("reset");
setBackgroundColor(0, 0, 0);
run("Z Project...", "projection=[Max Intensity]");
id = getImageID();

Stack.setChannel(1); run("Blue");
Stack.setChannel(2); run("Green");
Stack.setChannel(3); run("Red");

run("Duplicate...", "duplicate channels="+GolgiChannel);
run("Gaussian Blur...", "sigma=2 slice");
run("Threshold...");
setAutoThreshold("Mean dark");

run("Create Mask");
run("Options...", "iterations=3 count=3 black pad edm=8-bit do=Close");
run("Fill Holes");
run("Options...", "iterations=3 count=3 black pad edm=8-bit do=Erode");

run("Analyze Particles...", "size=100-Infinity add");
close("mask");
close();

selectImage(id);
run("Make Composite");
roiManager("Show All with labels");

setTool("freehand");
waitForUser("Remove or add cell objects. Click OK to continue in the dialog box");

print ("cell"+"\t"+"Golgi area"+"\t"+"convex hull area"+"\t"+"dispersion number"+"\t"+"# Golgi obj"+"\t"+"Max area Golgi obj"+"\t"+"Mean area Golgi obj"+"\t"+"mean Intens Golgi obj");

Nobj = roiManager("count");

// save cells ROIs
roiManager("save", dir+File.separator+basename+"_cellsROIs.zip");


// cel by cell analysis
for(i=0; i < Nobj; i++)
	{
// duplicate one cell Golgi channel, magnify, clear ourside cell
selectImage(id);
roiManager("Select", i);
run("Enlarge...", "enlarge=5 pixel");
run("Duplicate...", "duplicate channels="+GolgiChannel);
run("Clear Outside");
getLocationAndSize(x, y, width, height);
setLocation(x, y, width*3, height*3);

// threshold for Golgi objects
run("Threshold...");
wait(100);
setAutoThreshold(threshold+" dark");

// determine Golgi "objects", that is areas of the Golgi organelle
// that can be identified as separate, continous areas
roiManager("reset");
run("Clear Results");
run("Analyze Particles...", "size=6-Infinity pixel exclude include add");

run("Select None");
roiManager("Show All without labels");
resetThreshold();
waitForUser("Adjust Golgi objects, i.e. area occupied by Golgi, if appropriate");

// save Golgi channel image with objects overlay
roiManager("Show All without labels");
resetThreshold();
wait(100);
run("Flatten");
saveAs("tiff", dir+File.separator+basename+"_cell"+i+1+"_overlay");
close();

// get number of Golgi objects
NGolgi = roiManager("count");

// measure and save each Golgi object
run("Set Measurements...", "area mean centroid integrated limit redirect=None decimal=2");
area = newArray(NGolgi);
intensity = newArray(NGolgi);
totalAreaGolgi = 0;

run("Threshold...");
wait(100);
setAutoThreshold(threshold+" dark");

for(j=0; j < NGolgi; j++)
		{ 
		roiManager("Select", j);
		run("Measure");
		area[j] =  getResult("Area");
		intensity[j] = getResult("RawIntDen");
		totalAreaGolgi = totalAreaGolgi+getResult("Area");
		}
Array.getStatistics(area, min, max, mean, std);
meanAreaGolgi = mean;
maxAreaGolgi = max;
Array.getStatistics(intensity, min, max, mean, std);
meanIntensityGolgi = mean;

// save Golgi objects measuremets for each cells: area, mean intens, total intens, center(x,y)
selectWindow("Results");
saveAs("txt", dir+File.separator+basename+"_cell"+i+1+"_results");

// measure area occupied by Golgi objects, i.e. the convex hull
IndGolgi = Array.getSequence(NGolgi);
roiManager("Select", IndGolgi);
roiManager("Combine");
roiManager("Add");
roiManager("Select", NGolgi);

resetThreshold();
wait(100);
run("Convex Hull");
run("Measure");
areaCnvx = getResult("Area");

// calculate dispersion
dispersion = areaCnvx / totalAreaGolgi ;

close();

print ((i+1)+"\t"+totalAreaGolgi+"\t"+areaCnvx+"\t"+dispersion+"\t"+NGolgi+"\t"+maxAreaGolgi+"\t"+meanAreaGolgi+"\t"+meanIntensityGolgi);

// open in ROI manager the cells ROIs
roiManager("reset");
roiManager("Open", dir+File.separator+basename+"_cellsROIs.zip");
run("Clear Results");

	}

selectWindow("Log");
saveAs("txt", dir+File.separator+basename+"_ResultsLog");

selectImage(id);
run("Stack to RGB");
roiManager("Show All with labels");
run("Flatten");
saveAs("tiff", dir+File.separator+basename+"_overlay");
close();
close();
