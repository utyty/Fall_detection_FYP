close all; 
clear all;


% set background frame  manual 
BaseImage = imread('C:\\Users\JaroslawJ\Desktop\MATALB_ImageTesting\2_IMAGE\1.jpg');


blob = vision.BlobAnalysis(...
    'CentroidOutputPort', true, 'AreaOutputPort', true, ...
    'BoundingBoxOutputPort', true, ...
    'MinimumBlobAreaSource', 'Property', 'MinimumBlobArea', 500);

detector = vision.ForegroundDetector(...
    'NumTrainingFrames',10,'NumGaussians',5,...
    'MinimumBackgroundRatio', 0.7, 'LearningRate',0.0002);

detector2 = vision.ForegroundDetector(...
    'NumTrainingFrames',10,'NumGaussians',5,...
    'MinimumBackgroundRatio', 0.7,'InitialVariance',900,... 
    'LearningRate',0.0002);


  vid = VideoReader( 'C:\\Users\JaroslawJ\Desktop\MATALB_ImageTesting\Recived\Tester_video.mp4' ); 
  
stats_array = zeros(1,vid.NumberOfFrames); 
stats_array2 = zeros(1,vid.NumberOfFrames); 
stats_array3 = zeros(1,vid.NumberOfFrames); 


i=0;

 while i<vid.NumberOfFrames 

  pause(0.00000);
       % get backround frame 
    if vid.CurrentTime==0
        i=i+1;
        BaseImage= read(vid,i);

    end 

    stats_array2(i)= vid.CurrentTime*100;
    frame =  read(vid,i);
   

    
    imgDiff1 = abs(BaseImage - frame);
    
%     maxDiff = max(max(imgDiff1));
%     [iRow,iCol] = find(imgDiff1 == maxDiff);   
%     imshow(imgDiff1)
%     hold on
%     plot(iCol,iRow,'b*')
%     test1=regionprops(imgDiff1);


    imageBW = im2bw(imgDiff1,0.25);
    test1=regionprops(imageBW);
    
    imgBW = bwareaopen(imageBW, 1200);
    BW=imfill(imgBW, 'holes');
    imgStats1=regionprops(imgBW);
    
 %%   Ratio plot 
    if  (~isempty([imgStats1.BoundingBox])) 
        width= imgStats1.BoundingBox(3);
        height= imgStats1.BoundingBox(4);
        stats_array3(i) = height/width;
    end
   
    if ( stats_array3(i)< 0.45)
        temp= stats_array3(i);
    end 
 %%   
%     imgStats2=regionprops(imgBW,'MajorAxisLength')
%     imgStats3=regionprops(imgBW,'MinorAxisLength')
    
    
%     x = imread('coins.png')>100;
%     bb = regionprops(x,'BoundingBox')
% width= imgStats1.BoundingBox(3);
% height= imgStats1.BoundingBox(4);
% %     bbMatrix = vertcat(imgStats1(:).BoundingBox);
%     
% %     test=(int)imgStats2
% 
% stats_array3(i) = height/width;

     
 %% 4 plot display     
    figure(1);
     subplot(2,2,1);
     imshow(imgDiff1);
     title(sprintf('Original Video - %d',i));
     
     subplot(2,2,2);
     imshow(imageBW);
     title(sprintf('BW video'));

     subplot(2,2,3);
     imshow(imgBW);
     title(sprintf('BW filter'));
     if (~isempty([imgStats1.BoundingBox])) 
     hold on 
     rectangle('Position', [imgStats1.BoundingBox],'EdgeColor','r', 'LineWidth', 3)
     hold off
     end

      subplot(2,2,4);
      plot(stats_array3), grid on;
      title(sprintf('%.2f',stats_array3(i)));
      
% %%  Vsion box anaylysis 

     fgMask = step(detector,frame);
     fgMask=imfill(fgMask, 'holes');
     fgMask2 = step(detector2,frame);
      
     [area,centroid,box] = step(blob,fgMask);
     pos = find(area==max(area));
     box = box(pos,:);
      
      
     figure(2);
     subplot(2,2,1);
     imshow(frame);
     title(sprintf('frame - %d',i));
     
     subplot(2,2,2);
     imshow(fgMask);
     title(sprintf('detector'));
      
     
     subplot(2,2,3);
     imshow(fgMask2);
     title(sprintf('detector2'));
      
     
     subplot(2,2,4);
     imshow(fgMask2);
     title(sprintf('Blob'));
     if (~isempty(box)) 
     hold on 
     rectangle('Position', box,'EdgeColor','r', 'LineWidth', 3)
     hold off
     end 
     
     
     
    
 i=i+1 ;
 end
% figure(3)
%  plot(stats_array3),grid on;
%  xlabel('Frame number (10ms-frame)'), ylabel('Ratio height/width');
%  title('Ratio plot');
%  


