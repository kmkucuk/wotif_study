function [EEG_topo_avg] = func_topoPlotMv(EEG_epoch,savePath,figureSavePath,chanInfoFile)

%% MICROVOLT TOPOGRAPHIC %% 

% topographic plots for radio, podcast and spontaneous 
cd(savePath)

%% get microvolt per for first - middle - last (30s) 
EEG_topo_mv = struct();

fnames = fieldnames(EEG_epoch);    % get header names to find comp accuracy indx
% find subject related non-data channel indices 
nonDataFields = regexp(fnames,'A_');
nonDataIndx = find([nonDataFields{:}]==1);
nonDataIndx = nonDataIndx(end);
nonDataIndx = nonDataIndx+1; % data starts 1 field after the non-data fields.   

% loop over participants 
for pi = 1:length(EEG_epoch)
    
    
    EEG_topo_mv(pi).A_subject  = EEG_epoch(pi).A_subject;
    EEG_topo_mv(pi).A_group    = EEG_epoch(pi).A_group;
    EEG_topo_mv(pi).A_srate    = EEG_epoch(pi).A_srate;
    EEG_topo_mv(pi).A_chanlocs = EEG_epoch(pi).A_chanlocs;
    
    fprintf('\n******PROCESSED PARTICIPANT: %s ******\n',EEG_epoch(pi).A_subject); 
    
    %% start to loop over data fields 
    fi = 5;
    for fi = nonDataIndx:length(fnames)
            % get data ( dims(chan,time,trial) )
            data = EEG_epoch(pi).(fnames{fi});
            

            fprintf('\nCondition: %s \n',fnames{fi}); 
            
            %% if there are more than 1 trials
            if size(data,3)> 1

                % reshape data into chan x time matrix
                data = reshape(data,[size(data,1),size(data,2)*size(data,3)]);
                
            end

            % change dimensions for plots ( dims(time,chan) )
            data = permute(data,[2 1]);
            enableParts = 0;
            % if this field is longer than 100s, get average of parts 
            if enableParts
                
                % how many seconds there are in this trial
                countSeconds = floor(size(data,1)/256);     

                midSecondIndex = ceil(size(data,1)/2); % get index of the median second data point


                % initialize seconds by which first 30 - mid 30- and last 30
                % seconds will be extracted.

                % 30 sec data point transform

                dataPoint30 = 256*30;

                first30secs = 1 : dataPoint30;

                mid30secs = midSecondIndex : (midSecondIndex)+dataPoint30-1;

                end30secs = (size(data,1)-dataPoint30): size(data,1)-1;

                % three parts in vector
                partsVector = {first30secs,mid30secs,end30secs};

                % initialize second by second data
                seconds_data = [];

                for parti = partsVector
                    currentPart = parti{:};

                    mean_data = mean(data(currentPart,:),1);

                    seconds_data = cat(3,seconds_data,mean_data);

                end

                topo_data = squeeze(seconds_data);
                
            
                
                % if this field is not something very long, get average of
                % all time points
            else
                
                topo_data = mean(data,1);
                
            end
            
            
            EEG_topo_mv(pi).(fnames{fi}) = topo_data;

    end     
            

    
end
% 
%     % remove sub-46 and sub-43 for wotif study, most fields do not exist.
%    EEG_topo_mv([38, 41]) = [];


% order structure field names 
EEG_topo_mv = orderfields(EEG_topo_mv);
cd(savePath);
topo_mv_data_fileName = 'topo_mv_data_newProcessed_intp_5.mat';
%% save EEG_psd_data 
save(topo_mv_data_fileName,'EEG_topo_mv')


%% 

%% LOAD DATA 
cd(savePath)
% load('topo_mv_data_5');
% load(topo_mv_data_fileName);


groupsIndx = struct();
groupsIndx(1).index =[];
groupsIndx(2).index =[];
allGroupIndices = [];
for pi = 1:length(EEG_topo_mv)
    currentGroup = EEG_topo_mv(pi).A_group;
    currentChannels = EEG_topo_mv(pi).A_chanlocs;
    
    if ~(length(currentChannels)==18)
        % skip this participant for group averages if they have less than
        % 18 channels
        continue
    end
    
    groupsIndx(currentGroup).index = cat(2,groupsIndx(currentGroup).index,pi);
    groupsIndx(currentGroup).group = currentGroup; 
    allGroupIndices = cat(2,allGroupIndices,pi);
end

%% loop over fields and get average of groups

fnames   = fieldnames(EEG_topo_mv);
% find subject related non-data channel indices 
nonDataFields = regexp(fnames,'A_');
nonDataIndx = find([nonDataFields{:}]==1);
nonDataIndx = nonDataIndx(end);
nonDataIndx = nonDataIndx+1; % data starts 1 field after the non-data fields.   
EEG_topo_avg    = struct();
fi = 5;
for fi = nonDataIndx:length(fnames)
    
    fieldindx = fnames(fi);
    for averagei = 1:length(groupsIndx)
        
        
        groupinterval   = groupsIndx(averagei).index;
        currGroup       = groupsIndx(averagei).group;
        
        if isempty(groupinterval)
            continue
        end
        
        % check if there is missing data in any of ps, skip the event
        % if so.
        for parti = groupinterval
            

            % check if this field exists in this participant 
            validField = isfield( EEG_topo_mv , fieldindx{:} );

            if ~validField 
                continueToNextField = true;
                break
            else
                continueToNextField = false;
            end

            % check if data of this field is empty
            checkData = EEG_topo_mv(parti).(fieldindx{:});

            if isempty(checkData)
                continueToNextField = true;
                break
            else
                continueToNextField = false;
            end
        end
        
        
        % skip this event if any participants do not have this field. 
        if continueToNextField
            continue
        end
 
        
        groupdata = mean(cat(3,EEG_topo_mv(groupinterval).(fieldindx{:})),3);
       
        group_outlier_data = groupdata;
        
        %% outlier removal %% 

        %% there may be extreme results
        % THerefore, this script gets all values +-3 STD around the
        % median, and replacees them with the mean

        dataMedian = median(group_outlier_data,'all');
        dataSTD    = std(group_outlier_data,0,'all');

        thresholdPos = dataMedian + 3* dataSTD;
        thresholdNeg = dataMedian - 3* dataSTD;

        pos_outlier  = find(group_outlier_data>thresholdPos);
        neg_outlier  = find(group_outlier_data<thresholdNeg);

        outliers = [pos_outlier.' neg_outlier.'];

        disp(outliers)
        fprintf('\nchanged attention data: value \n');
        disp(group_outlier_data(outliers))            

        group_outlier_data(outliers) = dataMedian;

        groupdata = group_outlier_data;


        
        EEG_topo_avg(averagei).(fieldindx{:})   = groupdata; 
        EEG_topo_avg(averagei).A_group          = currGroup;
        EEG_topo_avg(averagei).A_channels       = EEG_topo_mv(groupinterval(1)).A_chanlocs;
    
    end
end

% eeglab
cd(savePath)
% load channel info file
% load('channelInfo.mat')

% order structure field names 
EEG_topo_avg = orderfields(EEG_topo_avg);

% topographic plot of time avareged grand average data 
iteration = 0;


%%  SINGLE TOPO PLOTS

fnames   = fieldnames(EEG_topo_avg);
% find subject related non-data channel indices 
nonDataFields = regexp(fnames,'A_');
nonDataIndx = find([nonDataFields{:}]==1);
nonDataIndx = nonDataIndx(end);
nonDataIndx = nonDataIndx+1; % data starts 1 field after the non-data fields.   


moveToNextField = 0; 
% fieldindx = averageFields(1);
for grpi = 1:length(EEG_topo_avg)
    
    
    
    for fi = nonDataIndx:length(fnames)
        fieldindx = fnames(fi);


        % bypass topo plot if this group has no data on this field
        if isempty(EEG_topo_avg(grpi).(fieldindx{:}))
            continue
        end

        fprintf('\nPROCESSED PLOT: %s\n%s\n%s \n',fieldindx{:});  
        allgroups = cat(3,EEG_topo_avg(grpi).(fieldindx{:}));% histData; 
        allgroupsCurrentData= allgroups;

    %     % get max value of this data (theta, alpha, 
    %     maxValue = max( allgroupsCurrentData ,[],'all'); 
    %     minValue = min( allgroupsCurrentData ,[],'all');

        currentMedian = median(allgroupsCurrentData,'all');
        currentSTD    = std(allgroupsCurrentData,0,'all');

        thresholdPos = currentMedian +  2*currentSTD;
        thresholdNeg = currentMedian -  2*currentSTD;

        minValue = thresholdNeg;
        maxValue = thresholdPos;

        if fi == nonDataIndx
            f = figure('visible','off'); 
        else
            clf;
        end


        data = EEG_topo_avg(grpi).(fieldindx{:});


        % plot topographic 

        topoplot(data,chanInfoFile,'style','map','plotrad',0.55,'maplimits',[minValue maxValue]); % channel info retrieved from external file. 

        % format figure 
        set(gca,'tickdir','out','XColor',[0 0 0], 'YColor', [0 0 0],'FontSize',8,'box','off');  
        fieldName = strrep(fieldindx{:},'_','-');

        titleText = ['Microvolts: ',fieldName];


        title(titleText)


        if moveToNextField == 1
            moveToNextField = 0; 
            continue
        end
        % change and create directory for this plot's save
        registeryDirectory = [figureSavePath '\microvolts'];
    %     registeryDirectory = [registeryDirectory, '\',fieldindx{:},'\','group',num2str(groupi)];
        if ~exist(registeryDirectory, 'dir')
           mkdir(registeryDirectory)
        end                
        cd(registeryDirectory)

        % save figure
        saveas(f,[fieldindx{:},'_',num2str(grpi), '.jpg']);      
        clf;

    end
end
%% GROUPED TOPO PLOTS %% 
% 
% % fieldindx = averageFields(1);
% for fieldindx = averageFields
%     
%     allgroups = cat(3,EEG_topo_avg(1).(fieldindx{:}),EEG_topo_avg(2).(fieldindx{:}),EEG_topo_avg(3).(fieldindx{:}));% histData; 
%     allgroupsCurrentData= allgroups;
% %     % get max value of this data (theta, alpha, 
% %     maxValue = max( allgroupsCurrentData ,[],'all'); 
% %     minValue = min( allgroupsCurrentData ,[],'all');
% 
%     currentMedian = median(allgroupsCurrentData,'all');
%     currentSTD    = std(allgroupsCurrentData,0,'all');
% 
%     thresholdPos = currentMedian +  2*currentSTD;
%     thresholdNeg = currentMedian -  2*currentSTD;
% 
%     minValue = thresholdNeg;
%     maxValue = thresholdPos;
%     subplotIndx = 0;
%     for groupi = 1:3
% 
%         
%         for parti = 1:3
%             
%             data = EEG_topo_avg(groupi).(fieldindx{:})(:,parti);
%             
%             
%              f = figure('visible','off'); 
%             % figure generation index 
%             iteration = iteration+1;
%             subplotIndx = subplotIndx+1;
%             % 3x3 plot, groups (1-2-3) by rows, time (first-mid-last) by columns
% %             subplot(3,3,subplotIndx)
%             
%             % plot topographic 
%             
%             topoplot(data,chanInfoFile,'style','map','plotrad',0.55,'maplimits',[minValue maxValue]); % channel info retrieved from external file. 
%             
%             % format figure 
%             set(gca,'tickdir','out','XColor',[0 0 0], 'YColor', [0 0 0],'FontSize',8,'box','off');  
%             fieldName = strrep(fieldindx{:},'_','-');
%             
%             titleText = ['G',num2str(groupi),' ',secondTitles{parti},':  ',fieldName];
%             
%             title(titleText)
%             
%             % change and create directory for this plot's save
%             registeryDirectory = [savePath '\plots\microvolts\single_plots'];
%             registeryDirectory = [registeryDirectory, '\',fieldindx{:},'\','group',num2str(groupi)];
%             if ~exist(registeryDirectory, 'dir')
%                mkdir(registeryDirectory)
%             end                
%             cd(registeryDirectory)
% 
%             % save figure
%             saveas(f,[secondTitles{parti}, '.jpg']);                 
%             clf;
%         end
%         
%     end
%     
%  
%     
%     
% end






end