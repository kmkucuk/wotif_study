function [EEG_topo_video] = func_topogVideo(EEG_psd_second,savePath)
    %% FREQUENCY TOPOGRAPHIC %% 

    % topographic plots for radio, podcast and spontaneous 
    cd(savePath)

    %% get power spectral density for first - middle - last (30s) 


    % initialize required freqs
    freqs = {'theta','alpha','beta','gamma'};
    ranges = {[4.5,8.5],[8.5,11.5],[15.5,30],[30,45]};
    freq_ranges = cat(1,freqs,ranges);
    % initialize frequency lists
    freqNames = {};
    freqRanges = {};
    freqIndices = {};
    allFreqs = EEG_psd_second(1).A_frequencies;
    % get index of all freqs
    for freqi = 1:4
        freqNames = cat(1,freqNames,freq_ranges(1,freqi));
        freqRanges = cat(1,freqRanges,freq_ranges(2,freqi));                

        current_range = freq_ranges{2,freqi};

        lowIndex = find(allFreqs == current_range(1));
        highIndex = find(allFreqs == current_range(2));   

        freqIndices = cat(1,freqIndices,{lowIndex:highIndex});
    end




    %% initialize group index variable %%
    % this is used for identifying participants in groups who are legible for 
    % topographical plots (i.e. channel count > 19)

    groupsIndx = struct();
    groupsIndx(1).index =[];
    groupsIndx(2).index =[];
%     groupsIndx(3).index =[];
    allGroupIndices = [];
    for pi = 1:length(EEG_psd_second)
        currentGroup = EEG_psd_second(pi).A_group;
        currentChannels = EEG_psd_second(pi).A_chanlocs;

        if ~(length(currentChannels)==18)
            % skip this participant for group averages if they have less than
            % 19 channels
            continue
        end

        groupsIndx(currentGroup).index = cat(2,groupsIndx(currentGroup).index,pi);
        groupsIndx(currentGroup).group = currentGroup;
        allGroupIndices = cat(2,allGroupIndices,pi);
    end




    %% initialize structure variable for second-by-second video data
    EEG_topo_video = struct();

    fnames = fieldnames(EEG_psd_second);
    % find subject related non-data channel indices 
    nonDataFields = regexp(fnames,'A_');
    nonDataIndx = find([nonDataFields{:}]==1);
    nonDataIndx = nonDataIndx(end);
    nonDataIndx = nonDataIndx+1; % data starts 1 field after the non-data fields.
    pindx = 0;
    
    % loop over participants 
    for pi = allGroupIndices
        pindx = pindx +1; 
        EEG_topo_video(pindx).A_subject  = EEG_psd_second(pi).A_subject;
        EEG_topo_video(pindx).A_group    = EEG_psd_second(pi).A_group;
        EEG_topo_video(pindx).A_srate    = EEG_psd_second(pi).A_srate;
        EEG_topo_video(pindx).A_chanlocs = EEG_psd_second(pi).A_chanlocs;

        fprintf('\n******PROCESSED PARTICIPANT: %s ******\n',EEG_psd_second(pi).A_subject); 

        %% start to loop from data fields (5) (first 4 are, subid, channels, group,srate)
        for fi = nonDataIndx:length(fnames)

                % get data ( dims(chan,time,trial) )
                data = EEG_psd_second(pi).(fnames{fi});

                if isempty(data)
                    continue                
                end

                fprintf('\nCondition: %s \n',fnames{fi}); 

    %             %% if there are more than 1 trials
    %             if size(data,3)> 1
    % 
    %                 % reshape data into chan x time matrix
    %                 data = reshape(data,[size(data,1),size(data,2)*size(data,3)]);
    %                 
    %             end

                % change dimensions for pwelch ( dims(time,chan) )
                data = permute(data,[3 2 1]);


                % initialize second by second data
                total_theta_data = []; %  theta freq data  

                total_alpha_data = [];%  alpha freq data  

                total_beta_data = []; %  beta freq data    (engagement)   

                total_attention_data = []; % theta/alpha data   

                theta_data = mean(data(:,:,freqIndices{1}),3);
                alpha_data = mean(data(:,:,freqIndices{2}),3);
                beta_data = mean(data(:,:,freqIndices{3}),3);       
                attention_data = abs(theta_data - alpha_data);

                % concatenate all frequency data on third dimension 
                % later it will be used for plotting
                EEG_topo_video(pindx).(fnames{fi}) = cat(3,theta_data,alpha_data,beta_data,attention_data);

        end     

        EEG_topo_video(pindx).A_dataNames = {'theta_data','alpha_data','beta_data','attention_data'};


    end
% 
%     % remove sub-46 for wotif study, most fields do not exist.
%     EEG_topo_video(35) = [];
%     % remove sub-43 for wotif study, resting state 2 does not exist 
%     EEG_topo_video(32) = [];
%     
    % order structure field names 
    EEG_topo_video = orderfields(EEG_topo_video);

     %% initialize group index variable %%
    % this is used for identifying participants in groups who are legible for 
    % topographical plots (i.e. channel count > 19)

    groupsIndx = struct();
    groupsIndx(1).index =[];
    groupsIndx(2).index =[];
%     groupsIndx(3).index =[];
    allGroupIndices = [];
    for pi = 1:length(EEG_topo_video)
        currentGroup    = EEG_topo_video(pi).A_group;
        currentChannels = EEG_topo_video(pi).A_chanlocs;

        if ~(length(currentChannels)==18)
            % skip this participant for group averages if they have less than
            % 19 channels
            continue
        end

        groupsIndx(currentGroup).index = cat(2,groupsIndx(currentGroup).index,pi);
        groupsIndx(currentGroup).group = currentGroup;
        allGroupIndices = cat(2,allGroupIndices,pi);
    end
    
    
    %% loop over fields and get average of groups %% 

    EEG_topo_video_avg    = struct();
    fieldindx = fnames(nonDataIndx);
    
    
    for fi = nonDataIndx:length(fnames)
        
        fieldindx = fnames(fi);
    
        % start of averaging loop, enable only if
        % there are groups.
        for averagei = 1:length(groupsIndx)
             
            % no groups
%             groupinterval   = allGroupIndices; 
%             groupNumber     = 1;     

            % with groups
            groupinterval   = groupsIndx(averagei).index;
            groupNumber     = groupsIndx(averagei).group;    
            

            if isempty(groupinterval)
                continue
            end
            
            
            % check if there is missing data in any of ps, skip the event
            % if so.
            parti = groupinterval(1);
            for parti = groupinterval
                parti
                
                
                % check if this field exists in this participant 
                validField = isfield( EEG_topo_video , fieldindx{:} );
                
                if ~validField 
                    continueToNextField = true;
                    break
                else
                    continueToNextField = false;
                end
                
                % check if data of this field is empty
                checkData = EEG_topo_video(parti).(fieldindx{:});

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

            groupdata = mean(cat(4,EEG_topo_video(groupinterval).(fieldindx{:})),4);

            %% histograms for screening %%
    %             for k = 1:4
    %                 figure(2)
    %                 subplot(2,2,k)
    %                 hist(groupdata(:,19,k))
    %             end        


            %% OUTLIER DETECTION AND TRANSFORM (TO MEDIAN) %% 

            % loop over data types (theta, alpha etc.)
            for dataType = 1:4
                % loop over channels for outlier detection  
                for chani = 1:size(groupdata,2)
                    group_outlier_data = groupdata(:,chani,dataType);


                    %% outlier removal %% 

                    %% there may be extreme results
                    % THerefore, this script gets all values +-3 STD around the
                    % median, and replacees them with the mean
    %                 dataMean   = mean(group_outlier_data,'all');
                    dataMedian = median(group_outlier_data);
                    dataSTD    = std(group_outlier_data,0);

                    thresholdPos = dataMedian + 3* dataSTD;
                    thresholdNeg = dataMedian - 3* dataSTD;

                    pos_outlier  = find(group_outlier_data>thresholdPos);
                    neg_outlier  = find(group_outlier_data<thresholdNeg);

                    outliers = [pos_outlier.' neg_outlier.'];

    %                 disp(outliers)
                    fprintf('\nchanged %s in channel %s value: \n',EEG_topo_video(groupinterval(1)).A_dataNames{dataType},EEG_topo_video(groupinterval(1)).A_chanlocs(chani).labels);
                    disp(cat(2,group_outlier_data(outliers),outliers.'))            

                    group_outlier_data(outliers) = dataMedian;

                    groupdata(:,chani,dataType) = group_outlier_data;
                end
                %%
            end

            % grouped data
            EEG_topo_video_avg(averagei).(fieldindx{:})       = groupdata; 
            EEG_topo_video_avg(averagei).A_group              = groupNumber;
            EEG_topo_video_avg(averagei).A_channels           = EEG_topo_video(groupinterval(1)).A_chanlocs;
            EEG_topo_video_avg(averagei).A_dataNames          = EEG_topo_video(groupinterval(1)).A_dataNames;
            
%             % no group data 
%             EEG_topo_video_avg.(fieldindx{:})       = groupdata; 
%             EEG_topo_video_avg.A_group              = groupNumber;
%             EEG_topo_video_avg.A_channels           = EEG_topo_video(groupinterval(1)).A_chanlocs;
%             EEG_topo_video_avg.A_dataNames          = EEG_topo_video(groupinterval(1)).A_dataNames;            
        end % end of averaging loop

    end
    EEG_topo_video_avg = orderfields(EEG_topo_video_avg);

    save('topog_video_avg_ads.mat','EEG_topo_video_avg');


    % eeglab
    % cd('E:\Backups\All Files\Genel\Is\2023\Tribikram\senseApp study\datasets\structures')
    % load channel info file
    % load('topog_video_avg.mat');
    % load('channelInfo.mat');

    %% GRAND AVERAGED TOPO PLOTS %% 
    fnames = fieldnames(EEG_topo_video_avg);
    % find subject related non-data channel indices 
    nonDataFields = regexp(fnames,'A_');
    nonDataIndx = find([nonDataFields{:}]==1);
    nonDataIndx = nonDataIndx(end);
    nonDataIndx = nonDataIndx+1; % data starts 1 field after the non-data fields.
    
    freqDataNames = EEG_topo_video_avg(1).A_dataNames;
    vector = [4,5,7,8,9,10,11,12,14,36,38];
    for dataindx = 4 %1:length(freqDataNames)

        % get the current frequency data name (theta, alpha, beta, attention)
        currentFreqData = freqDataNames{dataindx};



        for fi = vector
            fieldindx = fnames(fi);
             %% ONLY IF GROUPS EXIST find mean and std for plot color range 
            allgroups               = cat(4,EEG_topo_video_avg(1).(fieldindx{:}),EEG_topo_video_avg(2).(fieldindx{:}));% histData; 
            allgroupsCurrentData    = squeeze(allgroups(:,:,dataindx,:));
            allgroupsCurrentData    = reshape(allgroupsCurrentData,[size(allgroupsCurrentData,1)*size(allgroupsCurrentData,2)*size(allgroupsCurrentData,3),1]);
            

%             % no group data 
%             allgroups = EEG_topo_video_avg.(fieldindx{:});
%             allgroupsCurrentData = reshape(allgroups,[size(allgroups,1)*size(allgroups,2)*size(allgroups,3),1]);
            
            
        %     % get max value of this data (theta, alpha, 
        %     maxValue = max( allgroupsCurrentData ,[],'all'); 
        %     minValue = min( allgroupsCurrentData ,[],'all');

            currentMedian = median(allgroupsCurrentData);
            currentSTD    = std(allgroupsCurrentData,0);

            thresholdPos = currentMedian +  2*currentSTD;
            thresholdNeg = currentMedian -  2*currentSTD;

            minValue = thresholdNeg;
            maxValue = thresholdPos;
            

            subplotIndx = 0;
            for groupi = 2%1:length(groupsIndx)
                % skip if no data exists
                if isempty(EEG_topo_video_avg(groupi).(fieldindx{:}))
                    continue
                end
                % get data
                data = EEG_topo_video_avg(groupi).(fieldindx{:})(:,:,dataindx);

                % count seconds 
                howManySeconds = size(data,1);
                
                % create figure for video
                f = figure('visible','off'); 
                
                % clear figure 
                clf
                
                % create directory name 
                registeryDirectory = [savePath '\video\',currentFreqData];
                if ~exist(registeryDirectory, 'dir')
                   mkdir(registeryDirectory)
                end                
                
                % change directory for save 
                cd(registeryDirectory)   
                % get group name in string 
                currentGroup = ['Group',num2str(EEG_topo_video_avg(groupi).A_group)];
                % create video file name 
                currentVidName = [fieldindx{:},'_',currentGroup]; 
                % print a message 
                fprintf('\nPROCESSED VIDEO: %s\n%s\n%s \n',currentFreqData,fieldindx{:});  % ,currentGroup
                % initialize video writer object
                writerObj = VideoWriter(currentVidName); %// initialize the VideoWriter object
                % set frames per second t 1
                writerObj.FrameRate = 1;
                % start video object 
                open(writerObj);
                
                % loop over seconds 
                for secondi = 1:howManySeconds

                    % 3x3 plot, groups (1-2-3) by rows, time (first-mid-last) by columns
%                     subplot(3,3,subplotIndx)

                    % plot topographic 

                    topoplot(data(secondi,:),EEG_topo_video_avg(groupi).A_channels,'style','map','plotrad',0.55,'maplimits',[minValue maxValue]); % channel info retrieved from external file. 

                    % format figure 
                    set(gca,'tickdir','out','XColor',[0 0 0], 'YColor', [0 0 0],'FontSize',8,'box','off');  
                    fieldName = strrep(fieldindx{:},'_','-');
%                     if subplotIndx == 1
%                         titleText = ['G',num2str(groupi),':  ',fieldName];
                        titleText = fieldName;
%                     else
%                         titleText = ['G',num2str(groupi),' ',secondTitles{parti}];
%                     end

                    title(titleText)
                    movieFrames = getframe;
                    writeVideo(writerObj,movieFrames)
                    clf
                end
                close(writerObj);

            end

            % change and create directory for this plot's save
    %         registeryDirectory = 'E:\Backups\All Files\Genel\Is\2023\Tribikram\senseApp study\datasets\plots\frequency\grouped\';
    %         registeryDirectory = [registeryDirectory, '\',currentFreqData];

    % 
    %         % save figure
    %         saveas(f,[fieldindx{:}, '.jpg']);      
    %         clf;

        end

    end

end



% FOR GROUPED PLOTS 
% 
% for groupi = 1:3
%                 % skip if no data exists
%                 if isempty(EEG_topo_video_avg(groupi).(fieldindx{:}))
%                     continue
%                 end
%                 % get data
%                 data = EEG_topo_video_avg(groupi).(fieldindx{:})(:,:,dataindx);
% 
%                 % count seconds 
%                 howManySeconds = size(data,1);
%                 f = figure('visible','off'); 
%                 clf
%                 registeryDirectory = [savePath '\plots\video\ads\',currentFreqData];
%                 if ~exist(registeryDirectory, 'dir')
%                    mkdir(registeryDirectory)
%                 end                
%                 cd(registeryDirectory)            
%                 currentGroup = ['Group',num2str(EEG_topo_video_avg(groupi).A_group)];
%                 currentVidName = [fieldindx{:},'_',currentGroup]; 
%                 fprintf('\nPROCESSED VIDEO: %s\n%s\n%s \n',currentFreqData,fieldindx{:},currentGroup); 
%                 writerObj = VideoWriter(currentVidName); %// initialize the VideoWriter object
%                 writerObj.FrameRate = 1;
%                 open(writerObj);
%                 for secondi = 1:howManySeconds
% 
%                     % 3x3 plot, groups (1-2-3) by rows, time (first-mid-last) by columns
%     %                 subplot(3,3,subplotIndx)
% 
%                     % plot topographic 
% 
%                     topoplot(data(secondi,:),EEG_topo_video_avg(groupi).A_channels,'style','map','plotrad',0.55,'maplimits',[minValue maxValue]); % channel info retrieved from external file. 
% 
%                     % format figure 
%                     set(gca,'tickdir','out','XColor',[0 0 0], 'YColor', [0 0 0],'FontSize',8,'box','off');  
%                     fieldName = strrep(fieldindx{:},'_','-');
%     %                 if subplotIndx == 1
%                         titleText = ['G',num2str(groupi),':  ',fieldName];
%     %                 else
%     %                     titleText = ['G',num2str(groupi),' ',secondTitles{parti}];
%     %                 end
% 
%                     title(titleText)
%                     movieFrames = getframe;
%                     writeVideo(writerObj,movieFrames)
% 
%                 end
%                 close(writerObj);
% 
%             end



% 
% 
% %% SINGLE TOPO PLOTS %% 
% f = figure('visible','off'); 
% % fieldindx = averageFields(1);
% for dataindx = 1:length(freqDataNames)
%     
%     currentFreqData = freqDataNames{dataindx};
%     for fieldindx = averageFields
% 
%          %% find mean and std for plot color range
%         allgroups = cat(4,EEG_topo_video_avg(1).(fieldindx{:}),EEG_topo_video_avg(2).(fieldindx{:}),EEG_topo_video_avg(3).(fieldindx{:}));% histData; 
%         allgroupsCurrentData= allgroups(:,:,dataindx,:);
%     %     % get max value of this data (theta, alpha, 
%     %     maxValue = max( allgroupsCurrentData ,[],'all'); 
%     %     minValue = min( allgroupsCurrentData ,[],'all');
% 
%         currentMedian = mean(allgroupsCurrentData,'all');
%         currentSTD    = std(allgroupsCurrentData,0,'all');
% 
%         thresholdPos = currentMedian +  2*currentSTD;
%         thresholdNeg = currentMedian -  2*currentSTD;
% 
% 
%         minValue = thresholdNeg;
%         maxValue = thresholdPos;
% 
%         subplotIndx = 0;
%         for groupi = 1:3
% 
% 
%             for parti = 1:3
% 
%                 data = EEG_topo_video_avg(groupi).(fieldindx{:})(:,parti);
% 
% 
%                 f = figure('visible','off'); 
%                 % figure generation index 
%                 iteration = iteration+1;
%                 subplotIndx = subplotIndx+1;
% 
%                 % plot topographic 
% 
%                 topoplot(data,chanInfoFile,'style','map','plotrad',0.55,'maplimits',[minValue maxValue]); % channel info retrieved from external file. 
% 
%                 % format figure 
%                 set(gca,'tickdir','out','XColor',[0 0 0], 'YColor', [0 0 0],'FontSize',8,'box','off');  
%                 fieldName = strrep(fieldindx{:},'_','-');
% 
%                 titleText = ['G',num2str(groupi),' ',secondTitles{parti},':  ',fieldName];
% 
%                 title(titleText)
% 
%                 % change and create directory for this plot's save
%                 registeryDirectory = 'E:\Backups\All Files\Genel\Is\2023\Tribikram\senseApp study\datasets\plots\frequency\single_plots';
%                 registeryDirectory = [registeryDirectory, '\',currentFreqData,'\',fieldindx{:},'\'];
%                 if ~exist(registeryDirectory, 'dir')
%                    mkdir(registeryDirectory)
%                 end                
%                 cd(registeryDirectory)
%                 disp([registeryDirectory, '\',currentFreqData,'\',fieldindx{:},'\'])
%                 % save figure
%                 saveas(f,['group',num2str(groupi),'_',secondTitles{parti}, '.jpg']);                 
%                 clf;
%             end
% 
%         end
% 
% 
% 
% 
%     end
% end
