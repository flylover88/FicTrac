%This code is for Paul's rig. It will monitor a user selected zone for
%light turn on and then use that info pluse an empirically defined delay to
%determine when red light turns on. Will then plot Speed and Curvature show
%periods of light off in black and periods of light on in red.
clear; close all
%find the folder we are in, this should be where the videos are
currFolder = pwd;

plotName='';

fLndx = [];
fTimeStamps = [];
fM = [];

%enter how many flies will be ran in this (should change to read how many
%flies are in folder)
numFlies = 1;

%enter paramters ran for testing. All videos have to have the same values
%for all these
tB = 4; %time before pulses begin seconds
period = 8; %length of the period in seconds (light_on_time + light_off_time)
lighton = 3; %time the light will be on in each period
numReps = 5; %how many periods happen in a trial

efps=50;%expected fps


for z = 1:numFlies
   
    fN = z;
    %Find all of the videos in the  current folder
    pVids = dir([currFolder, '\Fly' int2str(fN) '-Video*.avi']);
    %find the debug videos so that we can ignore them
    debugs = dir([currFolder, '\Fly' int2str(fN) '-Video*debug.avi']);
    zzz=1;
    rr=1;
    clear Vids
    %This loop goes through all of the videos in the folder and leaves out
    %the debug videos
    while zzz<=length(pVids)-length(debugs)
        for r=1:length(pVids)
            if strcmp(pVids(r).name(end-8:end),'debug.avi') %filter out any debug.avi videos
                continue
            elseif strcmp(pVids(r).name,['Fly' int2str(fN) '-Video' int2str(rr) '.avi'])
                Vids(zzz)=pVids(r);
                zzz=zzz+1;
                continue
            end
        end
         rr=rr+1;
    end
    clear debugs pVids rr r zzz
    
    
    
    vc=0; %counter for videos
    fly=[];
    for c = 1:length(Vids)
         
        if ~strcmp(Vids(c).name(end-8:end),'debug.avi') %double check for debugs
            %try to find the .mat file for the video, if not found skip the
            %video
            try 
                load([currFolder, '/', Vids(c).name(1:end-4) '.mat'])
            catch
                warning([Vids(c).name(1:end-4) '.mat is not found in the current folder. Skipping this trial'])
                continue
            end
            %try to find the .dat file for the video, if not found skip the
            %video (in x direction are the different kinematics; in y
            %direction is the seperate frames)
            try 
                clear M
                M = csvread([currFolder, '/', Vids(c).name(1:end-4) '.dat']);
                numFrames = length(M);
            catch
                warning([Vids(c).name(1:end-4) '.dat is not found in the current folder. Skipping this trial'])
                continue
            end

            
        else
            continue
        end

        clear fps Lndx LTmean
        
        fps = s.FPS;
        %make sure the FPS is near what it should be
        if fps < efps*.995 || fps > efps*1.005 
            warning([Vids(c).name(1:end-4) ' had an fps of ' int2str(fps) '. This is too far from expected fps of ' num2str(efps) '. Video skipped.']);
            continue
        end
            
        %find the minimum expected number of frames in the video
        minFrames = (tB + period*numReps)*fps*.9;
        
        %if the frames of the video is less than the minimum skip the video
        if numFrames < minFrames
           continue
        end
        clear minFrames

        
%         pCP = s.CamPulse;
%         
%         ppLndx = s.Lndx;
%         pLndx = ppLndx([0 find(diff(pCP)==1)]+1);
%         Lndx = pLndx([1:3:length(pLndx)]);

        %find when the light is on
        Lndx = s.Lndx;
        
        %find when light turns on/off
        frameOn = find(diff(Lndx) == 1);
        frameOff = find(diff(Lndx) ==-1); 

        clear cc 
        
        minFrames = floor(period*efps*.995);
        %seperate kinematics matrix with light ndx based on pulses,
        %centered on the light on portion. Put in diffent cells
        for cc = 1:length(frameOn)
            fly{vc*numReps + cc,1} = horzcat(M(frameOn(cc)-floor(fps*(period-lighton)/2):frameOff(cc)+floor(fps*(period-lighton)/2),:),...
                              Lndx(frameOn(cc)-floor(fps*(period-lighton)/2):frameOff(cc)+floor(fps*(period-lighton)/2)));
            if length(fly{vc*numReps + cc,1}) < minFrames
                fly{vc*numReps + cc,1} = [];
            end
        end
        vc = vc+1;
        
    end
    
    %save the data for an individual fly
    save([currFolder '\Fly' int2str(fN) 'Data.mat'],'fly')%,'s','fullFly')
    clear cc
    %move the cells for individual fly into a cell matrix for all flies (y
    %direction has different pulses, x direction has the different flies)
    for cc = 1:length(fly)
        flies{cc,z} = fly(cc);
    end
        
end
%save the data of all the flies in single .dat
save([currFolder '\AllFlyData.mat'],'flies')
% flyFiles = dir([currFolder '\Fly*Data.mat']);

%max number of pulses shown on figure (all will be processed
maxDispRuns = 20;

[mostRuns,numFlies] = size(flies);
clear z
vertAvg = cell(1,mostRuns);
for ii = 1:length(vertAvg)
    vertAvg{ii} = nan(minFrames,25); %25 is the number a parameters in M plus 1 for light ndx
end

%loop trought flies to plot subplots
for z=1:numFlies
   clear c 
   vercat = [];
   horAvg = nan(minFrames,25);
   runCount = 0;
   for  c=1:mostRuns%min([mostRuns maxDispRuns])
       currRun = cell2mat(flies{c,z});
       if isempty(currRun)
           continue
       end
       runCount = runCount+1;
       %vertically concatonate the pulses (this acts to create a pulse
       %train for a fly)
       vercat = vertcat(vercat,currRun(1:minFrames,:));
       
       %makes a 3d matrix to store pulses in a cell. each cell hold c_th
       %pulse. will be used to average across flies
       vertAvg{c} = cat(3,vertAvg{c},currRun(1:minFrames,:));
       
       %makes a 3d matrix to store pulses in this run will be to average
       %for this fly
       horAvg = cat(3,horAvg,currRun(1:minFrames,:));
   end
   
   %plot individual stats
   xlimit = [0 min(maxDispRuns,runCount)*minFrames]./fps;
   
   %light index and other kinematics for this fly
   L = vercat(:,25);
   spd = smooth(vercat(:,19)).*fps.*3;
   heading = vercat(:,17);
   mvmtDir = vercat(:,18);
   
   %find curvature
   theta = heading + mvmtDir;
   curve = [0;diff(unwrap(theta))];
   
   %This is for plotting light on as red and light off as black
   x=[1:1:length(vercat)]./fps;
   dx=x; dx(L==1) = nan;
   
   %this is to average over the pulses for the fly
   horAvg = mean(horAvg,3,'omitnan');
   sL = mean(horAvg(:,25),3,'omitnan');
   sspd = smooth(mean(horAvg(:,19),3,'omitnan')).*fps.*3;
   sheading = mean(horAvg(:,17),3,'omitnan');
   smvmtDir = mean(horAvg(:,18),3,'omitnan');
   
   %find average curvature for pulses for the fly
   stheta = sheading + smvmtDir;
   scurve = [0;diff(unwrap(stheta))];
   
   %This is for plotting light on as red and light off as black for the fly
   %averaged
   sx=[1:1:mean(length(horAvg),3,'omitnan')]./fps;
   sdx=sx; sdx(sL==1) = nan;
   
   %speed
   subplot(2*numFlies+2,5,10*z-9:10*z-6)
   plot(x,spd,'r')
   hold on
   plot(dx,spd,'k')
   hold off
   xlim(xlimit)
   ylabel('spd')
   
   subplot(2*numFlies+2,5,10*z-5)
   plot(sx,sspd,'r')
   hold on
   plot(sdx,sspd,'k')
   hold off
   xlim([0 max(sx)])
   
   
   %curve
   subplot(2*numFlies+2,5,10*z-4:10*z-1)
   plot(x,curve,'r')
   hold on
   plot(dx,curve,'k')
   hold off
   ylabel('curve')
   xlim(xlimit)
   
   subplot(2*numFlies+2,5,10*z)
   plot(sx,scurve,'r')
   hold on
   plot(sdx,scurve,'k')
   hold off
   
end

%this is for the average of all flies
clear c
avgCat = [];
avgAvg = nan(minFrames,25);
for c = 1:mostRuns %concatonate and average, vertically averaged data
    avgCat = vertcat(avgCat,mean(vertAvg{c},3,'omitnan'));
    avgAvg = cat(3,avgAvg,mean(vertAvg{c},3,'omitnan'));
end
   avgAvg = mean(avgAvg,3,'omitnan');
%plot Averaged stats
   L = avgCat(:,25);
   spd = smooth(avgCat(:,19)).*fps.*3;
   heading = avgCat(:,17);
   mvmtDir = avgCat(:,18);

   theta = heading + mvmtDir;
   curve = [0;diff(unwrap(theta))];
   
   x=[1:1:length(avgCat)]./efps;
   dx=x; dx(L==1) = nan;
   
   sL = avgAvg(:,25);
   sspd = smooth(avgAvg(:,19)).*fps.*3;
   sheading = avgAvg(:,17);
   smvmtDir = avgAvg(:,18);

   stheta = sheading + smvmtDir;
   scurve = [0;diff(unwrap(stheta))];
   
   sx=[1:1:length(avgAvg)]./fps;
   sdx=sx; sdx(sL==1) = nan;
   
   %speed
   subplot(2*numFlies+2,5,10*z+1:10*z+4)
   plot(x,spd,'r')
   hold on
   plot(dx,spd,'k')
   hold off
   xlim(xlimit)
   ylabel('AVG spd')
   
   
   subplot(2*numFlies+2,5,10*z+5)
   plot(sx,sspd,'r')
   hold on
   plot(sdx,sspd,'k')
   hold off
   xlim([0 max(sx)])
   
   
   %curve
   subplot(2*numFlies+2,5,10*z+6:10*z+9)
   plot(x,curve,'r')
   hold on
   plot(dx,curve,'k')
   hold off
   ylabel('AVG curve')
   xlim(xlimit)
   
   subplot(2*numFlies+2,5,10*z+10)
   plot(sx,scurve,'r')
   hold on
   plot(sdx,scurve,'k')
   hold off
    
   
   print(plotName,'-dpdf','-fillpage')
            
   
   
       
       
       
    
    
