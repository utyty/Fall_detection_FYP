function FALL = fall_detector ( viedoname, mode ) 

% close all; 
% clear all;


vid = VideoReader(viedoname);

% settings for MHI and blob detection
blob = vision.BlobAnalysis(...
    'CentroidOutputPort', true, 'AreaOutputPort', true, ...
    'BoundingBoxOutputPort', true, ...
    'MinimumBlobAreaSource', 'Property', 'MinimumBlobArea', 900);

detector = vision.ForegroundDetector(...
    'NumTrainingFrames',25,'NumGaussians',5,...
    'MinimumBackgroundRatio', 0.7, 'LearningRate',0.0002);


%% start algorithm 
% variables for statistical data 
speed_array = zeros(1,vid.NumberOfFrames);    % SPEED 
height_array_vision = zeros(1,vid.NumberOfFrames);   % HEIGH_V
width_array_vision = zeros(1,vid.NumberOfFrames);    % WIDTH_V
ratio_array_vision = zeros(1,vid.NumberOfFrames);  % RATIO VISON 
fall_array = zeros(1,vid.NumberOfFrames);          

% movement 
avg_ratio = zeros(1,vid.NumberOfFrames);
delta_ratio = zeros(1,vid.NumberOfFrames);
avg_speed = zeros(1,vid.NumberOfFrames);
delta_speed = zeros(1,vid.NumberOfFrames);
avg_centroid = zeros(1,vid.NumberOfFrames);
delta_centroid = zeros(1,vid.NumberOfFrames);

temp1 = zeros(1,vid.NumberOfFrames);
temp2 = zeros(1,vid.NumberOfFrames);
temp3 = zeros(1,vid.NumberOfFrames);

centroid_array = zeros(1,vid.NumberOfFrames);
%centroid_array_vision = zeros(1,vid.NumberOfFrames);

%FLAGS
no_movment_check=0; 
time_to_ratio=0;


%MHI variables
tmhi = 15;
email_flag=true;
mhi_flag=false;
avg_tresh = 10;    % treshold for smootging effect
frame_to_send=0;

i=0;
 while i<vid.NumberOfFrames+1 
% flag_1 = false;
 
  

  pause(0.00000);
       % get backround frame 
    if vid.CurrentTime==0
        i=i+1;
        baseImage= read(vid,i);
        mhimage = zeros(size(baseImage,1),size(baseImage,2));
    end 
    frame =  read(vid,i); % get frame 
       
   
  
 %% enhancment 
  if mode==1  
  enhanced_frame= imadjust(frame,stretchlim(frame));
  K = imadjust(enhanced_frame,[0.1 0.8],[]);
%         % K = imadjust(enhanced_frame,[0.2 0.7],[]);
%   frame=decorrstretch(enhanced_frame, 'Tol', 0.4);
 frame=decorrstretch(K, 'Tol', 0.1);
 
        % hsvImage1 = rgb2hsv(testImage1);
   end
    
   

%%  PROCESSING 2   - vision box
  
    se=strel('square',10); % strelType  strelSize
    se2=strel('cube',10);

    fgMask = step(detector,frame);      
    fgMask_holes=imfill(fgMask, 'holes');
    fgMaks=imclose(fgMask_holes,se2); 
    
    
    % get max bounding box 
    [area,centroid,box] = step(blob,fgMask);
    pos = find(area==max(area));
    
    filter=600;
    dynamic_filter = max(area)/2.5;
    if(~isempty(dynamic_filter)) 
        filter=double(dynamic_filter); 
    end 
     
    % FIXED DYNAMIC FILTER  
    fgMask = bwareaopen(fgMask,filter);
    
    [area,centroid,box] = step(blob,fgMask);
    pos = find(area==max(area));
    centroid = centroid(pos,:);
    box = box(pos,:);
    
    % get ratio for vison method 
    if  (~isempty(box))  
        height_array_vision(i) = double(box(4));   % HEIGH_V
        width_array_vision(i) = double(box(3));    % WIDTH_V
        ratio_array_vision(i) = double(box(4))/double(box(3));
        centroid_array(i) = sqrt( (centroid(1)^2)+(centroid(2)^2));
    end   
    
    
    %clear false allarm
    if ( ratio_array_vision(i)> 0.9) 
    no_movment_check=0;
    end 
    
    
    if ( ratio_array_vision(i)< 0.65&& ratio_array_vision(i)>0.2)    % RATIO_2 WEIGHT 2
        fall_array(i)= fall_array(i) + 3;   % add 2
        no_movment_check=no_movment_check+1;
        frame_to_send=i;
        
        if (no_movment_check > 30 )
        ms = [ 'OBJECT IS NOT MOVING: ' num2str(i,'%02d') '  FLAG=', num2str(fall_array(i),'%02d')];
        disp(ms)
%         mhi_flag=false;
%         email_flag=true;
        frame_to_send=i;
        end   
    end 
    

     FmaskBW=fgMask;
    % mask inside the box !!!!
    if ~isempty(box)
        FmaskBW(:,1:box(1)-1) = 0;
        FmaskBW(:,box(1)+box(3)+1:end) = 0;
        FmaskBW(1:box(2)-1,:) = 0;
        FmaskBW(box(2)+box(4)+1:end,:) = 0;
        
        mhimage = max(zeros(size(mhimage)),mhimage-1);
       
        mhimage(FmaskBW==true) = tmhi;
        
        %calculate speed
        speed_array(i) = sum(sum(mhimage))/(sum(sum(FmaskBW))*tmhi);    
    end
    
    
        % GET SMOOTHING EFFECT  
    if i<3 
        temp1(i)=temp1(1)+ratio_array_vision(i);
        temp2(i)=temp2(1)+speed_array(i);
        temp3(i)=temp3(1)+centroid_array(i);
    end 
    if i>2 && i< avg_tresh+1
        temp1(i) = temp1(i-1) + ratio_array_vision(i);
        temp2(i) = temp2(i-1) + speed_array(i);
        temp3(i) = temp3(i-1) + centroid_array(i);
    end
    if i>avg_tresh
        temp1(i) = temp1(i-1) +ratio_array_vision(i) -ratio_array_vision(i-avg_tresh);
        avg_ratio(i) = temp1(i)/avg_tresh;
        
        temp2(i) = temp2(i-1) +speed_array(i) -speed_array(i-avg_tresh);
        avg_speed(i) = temp2(i)/avg_tresh;
        
        temp3(i) = temp3(i-1) + centroid_array(i) -centroid_array(i-avg_tresh);
        avg_centroid(i) = temp3(i)/avg_tresh;
        
    end
    if i>2
        delta_ratio(i) = abs(avg_ratio(i)-avg_ratio(i-1));
        delta_speed(i) =abs( avg_speed(i)-avg_speed(i-1));
        delta_centroid(i) = abs(avg_centroid(i)-avg_centroid(i-1));
    end
  
  %% FAll detection  
 
     % might not need it!!!! here
  if ( speed_array(i) > 1.85)    % SPEED WEIGTH 7 
    mhi_flag=true;
    fall_array(i)= fall_array(i) + 7;   % add 7    array for tesitn purposes
    ms = [ 'MOTION Fall detection at frame: ' num2str(i,'%02d') '  FLAG=', num2str(fall_array(i),'%02d')];
    disp(ms)
    time_to_ratio=time_to_ratio +1;
  end ;

  % time to acitave ratio set to 20 frames 
 if time_to_ratio==20
     mhi_flag=false;
     time_to_ratio=0;
 end
    
  if (mhi_flag)
      if ( ratio_array_vision(i)< 0.65 && ratio_array_vision(i)> 0.2) 
      ms = [ 'RATIO Fall detection at frame: ' num2str(i,'%02d') '  FLAG=', num2str(fall_array(i),'%02d')];
      disp(ms)
      email_flag=true;
      end 
  end
     
%%  PLOTS processing 2-Vsion box anaylysis 

     figure(1);
     subplot(2,2,1);
     imshow(frame);
     title(sprintf('Frame num  %d', i));
     
     subplot(2,2,2);
     imshow(uint8((mhimage*255)/tmhi));
     title(sprintf('BBOX - FILTER:%.2f',dynamic_filter));
     hold on;
     if (~isempty(box)) 
         rectangle('Position', box,'EdgeColor','r', 'LineWidth', 3)  
     end 
     hold off; 
     
     
     subplot(2,2,3);
     plot(ratio_array_vision);grid on;
     title(sprintf('ratio -%.2f',ratio_array_vision(i)));
     xlabel('Frame Number') ;
     ylabel('ratio') ;

     subplot(2,2,4);
     plot(speed_array);grid on;
     title(sprintf('MOTION %.2f',speed_array(i)));
     xlabel('Frame Number') ;
     ylabel('motion'); 
     
%      %% stats plots 
%      
%      figure(2);
%      subplot(2,2,1);
%      plot(ratio_array_vision);grid on;
%      title(sprintf('ratio -%.2f',ratio_array_vision(i)));
%     
%      
%      subplot(2,2,2);
%      %imshow(FmaskBW);
%      plot(centroid_array ) ;grid on;
%      title(sprintf('centroid  -%.2f',centroid_array(i)));
%    
%    
%             
%      subplot(2,2,3);
%      plot(speed_array); grid on;
%     title(sprintf('speed -%.2f',speed_array(i)));
%    
% %      imshow(uint8((mhimage*255)/tmhi));
% %     title(sprintf('mhimage'));
% 
%      subplot(2,2,4);
%      imshow(frame);
%      title(sprintf('VIdeo num  %d', p));
   
     
         %% stats plots 
     
%      figure(3);
%      subplot(2,2,1);
%      plot(delta_ratio);grid on;
%      title(sprintf(' DeltaRatio -%d',i));
%    
%      subplot(2,2,2);
%      %imshow(FmaskBW);
%      plot(delta_centroid ) ;grid on;
%      title(sprintf(' delta_centroid -%d',i));
%             
%      subplot(2,2,3);
%      plot(delta_speed); grid on;
%      title(sprintf(' delta_speed -%d',i));
% 
%      subplot(2,2,4);
%      plot(avg_centroid);grid on;
%      title(sprintf('avg_centroid  %.2f', i));
%      
     
        
 i=i+1 ;
 end
 

figure(3)
plot(ratio_array_vision,'b'); grid on;
x1=0;x2=length(ratio_array_vision);
hold on; 
plot(speed_array,'r');
y=1.85;
% line([x1,x2],[y,y]);
plot([x1,x2],[y,y],'--.r');
y=0.65;
plot([x1,x2],[y,y],'--.b');

hold off;
title('Ratio / Motion ');
xlabel('Frame Number');
ylabel('Amplitude');
legend('blue(ratio)', 'red(motion)');
 

%% Creating multiple excle sheet - all videos testing
% create name for excel spreedshet
p=1;  
fileName='Results';
fileName2 =[ 'Vid_' num2str(p,'%02d'),'.xlsx'];


MOTION   = num2cell(speed_array);
HEIGHT_V = num2cell(height_array_vision);
WIDTH_V  = num2cell(width_array_vision);
RATIO_V  = num2cell(ratio_array_vision);
FALL_T   = num2cell(fall_array);
MOVMENT  = num2cell(avg_ratio);
MOVMENT2 = num2cell(avg_speed);
D_RATIO  = num2cell(delta_ratio);
D_SPEED  = num2cell(delta_speed);
CENTROID = num2cell(centroid_array);
DELT_CEN = num2cell(delta_centroid);

C1  = ['HEIGHT_2,' HEIGHT_V];
C2  = ['WIDTH_2',WIDTH_V];
C3  = ['RATIO',RATIO_V];
C4  = ['RAT_av10',MOVMENT];
C5  = ['MOTION', MOTION];
C6  = ['SP_avg10',MOVMENT2];
C7  = ['FA_FLAGS', FALL_T];
C8  = ['DELTA_RAT', D_RATIO];
C9  = ['DELTA_SPEED', D_SPEED];
C10 = ['CENTROID',CENTROID];
C11 = ['DELT_CEN_10avg',DELT_CEN];

B= [C1',C2',C3',C4',C5',C6',C7',C8',C9',C10',C11'];

%write excel
xlswrite(fileName,B,fileName2);


%% SENDING EMAIL/NOTIFICaTION :

if(email_flag)
%---------------------
%      % REMEMBER DO DISABLE ANTYVIRUS
id='j.jakubowicz11@gmail.com';
subject = 'FALL DETECTION SYSTEM';
% %     %subject = [ "FALL DETECTION", "MOVMENT DETECTION", "VIDEO FRAME", "PHOTO FRAME" ];
% file= 'C:\\Users\JaroslawJ\Desktop\MATALB_ImageTesting\Recived\Me1_house.jpg';

frames = read(vid,frame_to_send);
file_to_send= ([ int2str(frame_to_send),'.jpg']);
imwrite(frames ,file_to_send);


messeage= ' Fall detected, please check video attached! ';
% send_mail_message(id,subject, messeage,file_to_send);
send_mail_message(id,subject, messeage,viedoname);

    ms = ('FALL DETECTED');
    disp('EMAIL SENT'); 
    msgbox(ms, 'WARN','Warn');

end 



end