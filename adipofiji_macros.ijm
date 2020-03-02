//If set to true, it is much faster as it does not need to display the images in real time, however if you want to see the image set to false (will take much longer)
setBatchMode(true) ;

input_directory = getDirectory("Choose an Input Directory ");
output_directory = getDirectory("Choose an Output Directory ");


allfiles = getFileList(input_directory);
files = newArray(0) ;

for (i=0; i < allfiles.length ; i++){
	if (endsWith(allfiles[i],'.tif')){
		files = Array.concat(files,newArray(allfiles[i])) ;
	}
}

print(files.length);

for (i=0 ; i < files.length ; i ++){
	print("Index");
	print(i);
	//identify the file -- will be different in directory implementation
	filepath= input_directory + files[i] ;
	print("FILEPATH") ;
	print(filepath) ;
	
	open(filepath) ;
	pathparts = split(filepath,File.separator) ;
	
	//the window title will be the file name without the rest of the path
	windowtitle = pathparts[pathparts.length-1] ;
	// TODO : find/replace the name of global prefix to something more appropriate
	img_path_str = "";
	for (j=0;j<pathparts.length-1;j++){
		img_path_str = img_path_str + File.separator + pathparts[j] ;
	}

	// Obtain Output File Path as a String
	output_file_path = output_directory + files[i] ;
	output_pathparts = split(output_file_path,File.separator) ;
	output_path_str = "";
	for (j=0;j<pathparts.length-1;j++){
		output_path_str = output_path_str + File.separator + output_pathparts[j] ;
	}
	
	//get rid of non-green channels
	selectWindow(windowtitle); 
	run("Split Channels");
	//This may be changed if the images have a differnt ending when fiji splits them into 3 colors
	selectWindow("C3-"+windowtitle); close();
	selectWindow("C1-"+windowtitle); close();
	selectWindow("C2-"+windowtitle);
	
	//the goods
	run("Smooth");
	run("Smooth");
	run("Smooth");
	run("Gaussian Blur...", "sigma=1");
	//CJCJ rolling ball is probably in pixels, reset it for the largest bright object
	run("Subtract Background...", "rolling=10");
	run("Smooth");
	run("Smooth");
	run("Smooth");
	run("Gaussian Blur...", "sigma=1");
	run("Find Edges");
	run("Smooth");
	run("Smooth");
	run("Smooth");
	run("Gaussian Blur...", "sigma=1");
	setAutoThreshold("Default dark");
	//run("Threshold...");
	//CJCJ only change the first number of the threshold, lowering makes the filter more permissive, 255 isn't to be changed
	//For some reson this image does not use (0,255) but it uses a threshold of (0,65535) 
	setThreshold(180, 65535);
	setOption("BlackBackground", false);
	run("Convert to Mask");
	run("Invert");
	run("Erode");
	run("Fill Holes");
	run("Erode");
	run("Erode");
	run("Erode");
	run("Erode");
	run("Invert");
	run("Skeletonize");
	run("Dilate");
	//CJCJ this is the scale for the 20x air on the Keyence, however, if you stitch it WILL change the scale! 
	run("Set Scale...", "distance=1 known=0.37744 pixel=1 unit=micron");
	run("Invert");
	//CJCJ Two things to change here, Size (in microns) and circularity (1=circle)
	run("Analyze Particles...", "size=1100-70000 circularity=0.33-1.00 display exclude add in_situ");
	
	
    //Replacing all spaces to underscores in the file names
	prefix_this_window = replace(substring(windowtitle,0,lengthOf(windowtitle)-4)," ", "_"); 

	File.makeDirectory(output_path_str + File.separator + prefix_this_window) ;
	//save rois as individual images
	
	ct=roiManager("count");

	for (j=0; j < ct ; j++){
	//for (i=0; i < 11 ; i++){
		roiManager("Select",j);
		roi_window_title = prefix_this_window+"_roi_"+j+".tif" ; 
		future_roi_path = output_path_str + File.separator + prefix_this_window+File.separator+prefix_this_window+"_roi_"+j+".tif" ;
		run("Duplicate...","title="+roi_window_title) ;
		selectWindow(roi_window_title) ;
		save(future_roi_path); 
		close() ;
		selectWindow("C2-"+windowtitle);
		showProgress(j,ct) ;
	}


	//saves roi
	run("Flatten") ;
	save(output_path_str + File.separator+prefix_this_window+File.separator+prefix_this_window+"_ROIoverlay.tif") ;
	close() ;
	// Reset ROI Manager
	roiManager("reset");

}

saveAs("Results", output_path_str + File.separator +"all_data.csv" );
Table.deleteRows(0, ct) ;
selectWindow("Results") ;
run("Close") ;


print("CODE COMPLETE! :D")

