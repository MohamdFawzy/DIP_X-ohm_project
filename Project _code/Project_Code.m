%Project Name : Calculating Resistance Vlaue based on Color Bands
%Team : X-ohm
%-------------
%********************Please , Read the following Notes********************
%-------------
%this code consists of 3 functions : * main function , *function to enable
%user to extract resistance body only from image by freehandDrawing
%,*function to calculate mean value of L,a,b of masked image
%-------------
%this code is for calculating resistance value of 4 bands only 
%this code DOSE NOT calculate tolerance.
%*SO ,DO NOT INCLUDE LAST RIGHT BAND (TOLERANCE BAND) while FREEHAND DRAW*
%input image should be captured properly and from a suitable short distance
%and in a good lighting .
%-------------
%main function is divided into following sections (indicating the Algorithm
%we followed) :
%1-General Initializations
%2-Image Segmentation and Applying mask on each Color Band of resistor.
%3-Color Detection of each band.
%4-Detect the order of bands.
%5-Calculate Resistance Value based on colors and its order.
%-------------
%**********OUTPUT OF THE CODE CAN BE VIEWED IN COMMAND WINDOW**************
%>>>>>>>>>>>>>>>>>>>>RESISTANCE-VALUE AND COLORS<<<<<<<<<<<<<<<<<<<<<<<<<<<

function main()    
close all;
    clear
    %%
    %*****************SECTION (1)***************
    %>>>>>>>>>>General Initializations<<<<<<<<<<
    
	fontSize = 14;
    %----
    %dimension of crop image
    width = 3 ;
    height = 3 ;
    %----
    %standard value of colors and its names , will be used in comparing
    %with output colors of bands later .
    std_colors_code_HSV = [ [0,0,0] ; [0,0.75,0.65] ; [0,1,1] ; [0.11,1,1] ; [0.17,1,1] ; [0.33,0.98,0.5] ; [0.67,1,1] ; [0.84,0.45,0.93] ; [0.83,0.02,0.51] ; [0.9,0,1] ];
    std_colors_code_names = [string('black') , string('brown') ,string('red') , string('orange') , string('yellow') ,string('green') , string('blue') , string('violet') , string('grey') , string('white')] ; 
    %----                   
	figure;
	% Maximize the figure. 
	set(gcf, 'Position', get(0, 'ScreenSize')); 
    %%
    %***************************SECTION (2)******************************
    %>>>Image Segmentation and Applying mask on each Color Band of res<<<
    %----
    % Ask user to choose resistor image from PC
	message = sprintf('choose your resistor image');
	reply2 = questdlg(message, 'Welcome', 'browse','cancel', 'Demo');
    if strcmpi(reply2, 'browse')
        originalFolder = pwd; 
		folder = fullfile(matlabroot, '\toolbox\images\imdemos');
		if ~exist(folder, 'dir') 
			folder = pwd; 
		end 
		cd(folder); 
		% Browse for the image file. 
		[baseFileName, folder] = uigetfile('*.*', 'Specify an image file'); 
		fullImageFileName = fullfile(folder, baseFileName); 
		% Set current folder back to the original one. 
		cd(originalFolder);
    end
    %----
    %Reading Image in Matlab
    [rgbImage storedColorMap] = imread(fullImageFileName); 
	[rows columns numberOfColorBands] = size(rgbImage); 
	% Display the original image.
	h1 = subplot(3, 4, 1);
	imshow(rgbImage);
	drawnow; % Make it display immediately. 
    %----
    %draw mask by FreeHand on resistance body
	mask = DrawFreehandRegion(h1, rgbImage); %calling to Function (2)
	% Apply the Mask to image.
	maskedRgbImage = bsxfun(@times, rgbImage, cast(mask, class(rgbImage)));
    %----
    %the Algorithm here is to convert the masked image to LAB color-space
    %and calculate the mean value of L,A,B for all pixels . Normally , mean
    %value will be biased towards the resistor background color because res
    %background color is the major color . so afterthat when we calculate
    %the DeltaE between mean color and every single pixel , the value of
    %DeltaE will be lowest for background color and will be larger for
    %every thing else . so, when imshow DeltaE in image the background
    %color will be dark and bands will be brighter and we can apply
    %suitable threshold to get binary image and use it to mask the original
    %RGB-image .
    
	% Convert image from RGB colorspace to lab color space.
	cform = makecform('srgb2lab');
	lab_Image = applycform(im2double(rgbImage),cform);
	
	% Extract out the color bands from the original image
	% into 3 separate 2D arrays, one for each color component.
	LChannel = lab_Image(:, :, 1); 
	aChannel = lab_Image(:, :, 2); 
	bChannel = lab_Image(:, :, 3); 
	
	% Display the lab images.
	subplot(3, 4, 2);
	imshow(LChannel, []);
	title('L Channel', 'FontSize', fontSize);
	subplot(3, 4, 3);
	imshow(aChannel, []);
	title('a Channel', 'FontSize', fontSize);
	subplot(3, 4, 4);
	imshow(bChannel, []);
	title('b Channel', 'FontSize', fontSize);
	% Get the average lab color value.(call to function (3))
	[LMean, aMean, bMean] = GetMeanLABValues(LChannel, aChannel, bChannel, mask);
	
	% Make uniform images of only that one single LAB color.
	LStandard = LMean * ones(rows, columns);
	aStandard = aMean * ones(rows, columns);
	bStandard = bMean * ones(rows, columns);
	
	% Create the delta images: delta L, delta A, and delta B.
	deltaL = LChannel - LStandard;
	deltaa = aChannel - aStandard;
	deltab = bChannel - bStandard;
	
	% Create the Delta E image.
	% This is an image that represents the color difference.
	% Delta E is the square root of the sum of the squares of the delta images.
	deltaE = sqrt(deltaL .^ 2 + deltaa .^ 2 + deltab .^ 2);
	
	% Mask it to get the Delta E in the mask region only.
	maskedDeltaE = deltaE .* mask;
	% Get the mean delta E in the mask region
 	meanMaskedDeltaE = mean(deltaE(mask));	
	
	% Display the masked Delta E image - the delta E within the masked region only.
	subplot(3, 4, 5);
	imshow(maskedDeltaE, []);
	caption = sprintf('Delta E between image within masked region\nand mean color within masked region.\n(With amplified intensity)');
	title(caption, 'FontSize', fontSize);
	% Display the Delta E image - the delta E over the entire image.
	subplot(3, 4, 6);
	imshow(deltaE, []);
	caption = sprintf('Delta E Image\n(Darker = Better Match)');
	title(caption, 'FontSize', fontSize);
    
    %----
    %Global thresholding the masked_deltaE_image to eliminate the background of
    %resistor body and leave the color bands only
    maskedDeltaE_binary = maskedDeltaE > 20 ;
    %apply erosion to eliminate undesired small spots in mask
    maskedDeltaE_binary = imerode( maskedDeltaE_binary , strel('rectangle',[20 5]));
    %apply dilation to close holes and or better regular mask
    maskedDeltaE_binary = imdilate(maskedDeltaE_binary, strel('rectangle',[10 2]));
    imshow(maskedDeltaE_binary, []);
    
    %after getting one masked image on 3 color bands , we need to separet them
    %in 3 images , each contains 1 color band .
    %use 'bwconncomp' function to detect all connected objects in the
    %binary image 
    CC = bwconncomp(maskedDeltaE_binary);
    numPixels = cellfun(@numel,CC.PixelIdxList);
    %sort the connected objects , larger connected objects will indicate
    %the mask on color bands 
    [biggest,idx] = sort(numPixels ,  'descend');

    %here we create binary image and assign it to zeros , then we use the
    %output of 'CC' to access each object and assign it to 1 so that we can
    %obtain binary image containing ones on one color band only then we do
    %the mask .
    %we repeat this 3 times to obtain 3 images each of them contains
    %diffreent single color band
    maskedDeltaE_binary = (zeros(size(rgbImage,1),size(rgbImage,2)));
    maskedDeltaE_binary(CC.PixelIdxList{idx(1,1)}) = 1 ;
    centers(1) = regionprops(maskedDeltaE_binary,'Centroid'); %this line extracts the centroid of each object (also centroid of each color band) this will be useful later to determine the order of color bands .
    subplot(3, 4, 7);
    color_bands(:,:,:,1) = bsxfun(@times, rgbImage, cast(maskedDeltaE_binary,class(rgbImage))); 
    imshow(color_bands(:,:,:,1), []);
    caption = sprintf('(Mask on color band 1)');
	title(caption, 'FontSize', fontSize);
    
    maskedDeltaE_binary = (zeros(size(rgbImage,1),size(rgbImage,2)));
    maskedDeltaE_binary(CC.PixelIdxList{idx(1,3)}) = 1 ;
    centers(2) = regionprops(maskedDeltaE_binary,'Centroid');
    color_bands(:,:,:,2) = bsxfun(@times, rgbImage, cast(maskedDeltaE_binary,class(rgbImage))); 
    subplot(3, 4, 8);
    imshow(color_bands(:,:,:,2), []);
    caption = sprintf('(Mask on color band 2)');
	title(caption, 'FontSize', fontSize);
    
    maskedDeltaE_binary = (zeros(size(rgbImage,1),size(rgbImage,2)));
    maskedDeltaE_binary(CC.PixelIdxList{idx(1,2)}) = 1 ;
    centers(3) = regionprops(maskedDeltaE_binary,'Centroid');
    color_bands(:,:,:,3) = bsxfun(@times, rgbImage, cast(maskedDeltaE_binary,class(rgbImage))); 
    subplot(3, 4, 9);
    imshow(color_bands(:,:,:,3), []);
    caption = sprintf('(Mask on color band 3)');
	title(caption, 'FontSize', fontSize);
    
    return
    
    function [mask] = DrawFreehandRegion(handleToImage, rgbImage)
try
	fontSize = 14;
	% Open a temporary full-screen figure if requested.
	enlargeForDrawing = true;
	axes(handleToImage);
	if enlargeForDrawing
		hImage = findobj(gca,'Type','image');
		numberOfImagesInside = length(hImage);
		if numberOfImagesInside > 1
			imageInside = get(hImage(1), 'CData');
		else
			imageInside = get(hImage, 'CData');
		end
		hTemp = figure;
		hImage2 = imshow(imageInside, []);
		[rows columns NumberOfColorBands] = size(imageInside);
		set(gcf, 'Position', get(0,'Screensize')); % Maximize figure.
    end
    
	
	message = sprintf('Left click and hold to begin drawing.\nSimply lift the mouse button to finish\nDO NOT INCLUDE TOLERANCE BAND');
	text(10, 40, message, 'color', 'r', 'FontSize', fontSize);
    % Prompt user to draw a region on the image.
	uiwait(msgbox(message));
	
	% Now, finally, have the user freehand draw the mask in the image.
	hFH = imfreehand();
	% Once we get here, the user has finished drawing the region.
	% Create a binary image ("mask") from the ROI object.
	mask = hFH.createMask();
	
	% Close the maximized figure because we're done with it.
	close(hTemp);
	% Display the freehand mask.
	subplot(3, 4, 5);
	imshow(mask);
	title('Binary mask of the region', 'FontSize', fontSize);
	
	% Mask the image.
	maskedRgbImage = bsxfun(@times, rgbImage, cast(mask,class(rgbImage)));
	% Display it.
	subplot(3, 4, 6);
	imshow(maskedRgbImage);
catch ME
	errorMessage = sprintf('Error running DrawFreehandRegion:\n\n\nThe error message is:\n%s', ...
		ME.message);
	WarnUser(errorMessage);
end
return; % from DrawFreehandRegion

function [LMean, aMean, bMean] = GetMeanLABValues(LChannel, aChannel, bChannel, mask)
try
	LVector = LChannel(mask); % 1D vector of only the pixels within the masked area.
	LMean = mean(LVector);
	aVector = aChannel(mask); % 1D vector of only the pixels within the masked area.
	aMean = mean(aVector);
	bVector = bChannel(mask); % 1D vector of only the pixels within the masked area.
	bMean = mean(bVector);
catch ME
	errorMessage = sprintf('Error running GetMeanLABValues:\n\n\nThe error message is:\n%s', ...
		ME.message);
	WarnUser(errorMessage);
end
return; % from GetMeanLABValues