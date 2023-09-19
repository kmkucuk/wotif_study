function [EEG_topo_avg] = func_topoPlotFreq(EEG_psd_second,savePath,figureSavePath,chanInfoFile)
    %% FREQUENCY TOPOGRAPHIC %% 

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


    % initialize structure variable for first-mid-last psd
    EEG_topo_freq = struct();


    fnames = fieldnames(EEG_psd_second);    % get header names to find comp accuracy indx
    % find subject related non-data channel indices 
    nonDataFields = regexp(fnames,'A_');
    nonDataIndx = find([nonDataFields{:}]==1);
    nonDataIndx = nonDataIndx(end);
    nonDataIndx = nonDataIndx+1; % data starts 1 field after the non-data fields.    

    % loop over participants 
    for pi = 1:length(EEG_psd_second)


        EEG_topo_freq(pi).A_subject  = EEG_psd_second(pi).A_subject;
        EEG_topo_freq(pi).A_group    = EEG_psd_second(pi).A_group;
        EEG_topo_freq(pi).A_srate    = EEG_psd_second(pi).A_srate;
        EEG_topo_freq(pi).A_chanlocs = EEG_psd_second(pi).A_chanlocs;

        fprintf('\n******PROCESSED PARTICIPANT: %s ******\n',EEG_psd_second(pi).A_subject); 

        %% start to loop from data fields (5) (first 4 are, subid, channels, group,srate)
        for fi = nonDataIndx:length(fnames)

                % get data ( dims(chan,time,trial) )
                data = EEG_psd_second(pi).(fnames{fi});
                if isempty(data)
                    % skip if participant does not have valid data this field 
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
                
                % change dimensions for plots ( dims(time,chan) )
                data = permute(data,[3 2 1]);
                % initialize second by data matrices
                total_theta_data = []; %  theta freq data  

                total_alpha_data = [];%  alpha freq data  

                total_beta_data = []; %  beta freq data    (engagement)   

                total_attention_data = []; % theta/alpha data  
                
                if size(data,1)>100
                    disp('part averaging')
                    % how many seconds there are in this trial
                    countSeconds = size(data,1);     

                    midSecondIndex = ceil(size(data,1)/2); % get index of the median second data point


                    % initialize seconds by which first 30 - mid 30- and last 30
                    % seconds will be extracted.

                    % 30 sec data point transform

                    first30secs = 1 : 30;

                    mid30secs = midSecondIndex : (midSecondIndex)+30-1;

                    end30secs = (size(data,1)-30): size(data,1)-1;

                    % three parts in vector
                    partsVector = {first30secs,mid30secs,end30secs};


                    % average across frequencies 
                    theta_data = mean(data(:,:,freqIndices{1}),3);
                    alpha_data = mean(data(:,:,freqIndices{2}),3);
                    beta_data = mean(data(:,:,freqIndices{3}),3);              
  

%                     parti = partsVector(2); % initialize index variable for debugging,
                    for parti = partsVector
                        currentPart = parti{:};
                        % average across this window's time points 
                        avg_beta_data = mean(beta_data(currentPart,:),1);

                        avg_theta_data  = mean(theta_data(currentPart,:),1);
                        avg_alpha_data  = mean(alpha_data(currentPart,:),1);

                        % absolute ratio (theta/alpha)
                        current_attention_data  = abs(avg_theta_data ./ avg_alpha_data);

                        % concat theta
                        total_theta_data        = cat(3,total_theta_data,avg_theta_data);
                        % concat alpha
                        total_alpha_data        = cat(3,total_alpha_data,avg_alpha_data);
                        % concat beta 
                        total_beta_data         = cat(3,total_beta_data,avg_beta_data);
                        % concat attention (theta/alpha)
                        total_attention_data    = cat(3,total_attention_data,current_attention_data);

                    end
                        % squeeze concatenated data to eliminate single dimensions
                        total_theta_data        = squeeze(total_theta_data);
                        total_alpha_data        = squeeze(total_alpha_data);
                        total_beta_data         = squeeze(total_beta_data);
                        total_attention_data    = squeeze(total_attention_data);
                else
                    
                    % if this condition was shorter than 100 s (radio ads
                    % etc.) grand average instad of part average
                    
                    % average across frequencies
                    disp('grand averaging')
                    theta_data = mean(data(:,:,freqIndices{1}),3);
                    alpha_data = mean(data(:,:,freqIndices{2}),3);
                    beta_data = mean(data(:,:,freqIndices{3}),3);
  
                    
                    % average across all time points 
                                      
                    total_theta_data = mean(theta_data,1);
                    total_alpha_data = mean(alpha_data,1);
                    total_beta_data = mean(beta_data,1);
                    total_attention_data  = abs(total_theta_data ./ total_alpha_data);  
                    
                    total_theta_data = permute(total_theta_data,[2 1]);
                    total_alpha_data = permute(total_alpha_data,[2 1]);
                    total_beta_data = permute(total_beta_data,[2 1]);
                    total_attention_data = permute(total_attention_data,[2 1]);
                    
                    
                end
                



                % concatenate all frequency data on third dimension 
                % later it will be used for plotting
                EEG_topo_freq(pi).(fnames{fi}) = cat(3,total_theta_data,total_alpha_data,total_beta_data,total_attention_data);
                
%                 disp('size of data')
%                 disp(size(EEG_topo_freq(pi).(fnames{fi})))

        end     

        EEG_topo_freq(pi).A_dataNames = {'theta_data','alpha_data','beta_data','attention_data'};


    end


    % order structure field names 
    EEG_topo_freq = orderfields(EEG_topo_freq);

    %% save EEG_psd_data 
    cd(savePath)
    % save('topo_freq_data','EEG_topo_freq')
    topo_freq_data_fileName = 'topo_freq_data_newProcessed_intp.mat';
    %% save EEG_psd_data 
    save(topo_freq_data_fileName,'EEG_topo_freq')


    cd(savePath)
 
    groupsIndx = struct();
    % initialize group index variable
    % this is used for identifying participants in groups who are legible for 
    % topographical plots (i.e. channel count > 19)
    groupsIndx(1).index =[];
    groupsIndx(2).index =[];
    allGroupIndices = [];

    for pi = 1:length(EEG_topo_freq)
        currentGroup = EEG_topo_freq(pi).A_group;
        currentChannels = EEG_topo_freq(pi).A_chanlocs;

        if ~(length(currentChannels)==18)
            % skip this participant for group averages if they have less than
            % 19 channels
            continue
        end

        groupsIndx(currentGroup).index = cat(2,groupsIndx(currentGroup).index,pi);
        groupsIndx(currentGroup).group = currentGroup;
        allGroupIndices = cat(2,allGroupIndices,pi);
    end

    %% loop over fields and get average of groups
    
    EEG_topo_avg    = struct();
    
    
    %% averaging and outlier removal     
    
    for fi = nonDataIndx:length(fnames)
        
        fieldindx = fnames(fi);
        
        for averagei = 1:length(groupsIndx)
                
            groupinterval   =  groupsIndx(averagei).index;
            groupNumber     =  groupsIndx(averagei).group;

            if isempty(groupinterval)
                continue
            end


            % check if there is missing data in any of ps, skip the event
            % if so.
            for parti = groupinterval
                

                % check if this field exists in this participant 
                validField = isfield( EEG_topo_freq , fieldindx{:} );

                if ~validField 

                    continueToNextField = true;

                    break

                else

                    continueToNextField = false;

                end

                % check if data of this field is empty
                checkData = EEG_topo_freq(parti).(fieldindx{:});

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

            groupdata = mean(cat(4,EEG_topo_freq(groupinterval).(fieldindx{:})),4);
            
            
            for dataType = 1:4
                
                group_outlier_data = groupdata(:,:,dataType);



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

                groupdata(:,:,dataType) = group_outlier_data;

                %%
            end

%              USED FOR GROUPS
            EEG_topo_avg(averagei).(fieldindx{:})       = groupdata; 
            EEG_topo_avg(averagei).A_group              = groupNumber;
            EEG_topo_avg(averagei).A_chanlocs           = EEG_topo_freq(groupinterval(1)).A_chanlocs;
            EEG_topo_avg(averagei).A_dataNames          = EEG_topo_freq(groupinterval(1)).A_dataNames;

%             EEG_topo_avg.(fieldindx{:})       = groupdata; 
%             EEG_topo_avg.A_group              = groupNumber;
%             EEG_topo_avg.A_channels           = EEG_topo_freq(groupinterval(1)).A_chanlocs;
%             EEG_topo_avg.A_dataNames          = EEG_topo_freq(groupinterval(1)).A_dataNames;


        end
    end
    
    EEG_topo_avg = orderfields(EEG_topo_avg);

    cd(savePath);
    
    save('topog_freq_avg.mat','EEG_topo_avg');
    

     %% GRAND AVERAGED TOPO PLOTS %% 
    fnames = fieldnames(EEG_topo_avg);
    % find subject related non-data channel indices 
    nonDataFields = regexp(fnames,'A_');
    nonDataIndx = find([nonDataFields{:}]==1);
    nonDataIndx = nonDataIndx(end);
    nonDataIndx = nonDataIndx+1; % data starts 1 field after the non-data fields.
    
    
    freqDataNames = EEG_topo_avg(1).A_dataNames;
    
    
    f = figure('visible','off'); 
    % fieldindx = averageFields(1);
    for dataindx = 1:length(freqDataNames)

        currentFreqData = freqDataNames{dataindx};
        
        fi = 5;
        for fi = nonDataIndx:length(fnames)
            
            fieldindx = fnames(fi);
            
             % find mean and std for plot color range
            allgroups = cat(4,EEG_topo_avg(1).(fieldindx{:}),EEG_topo_avg(2).(fieldindx{:}));% histData; 
            allgroupsCurrentData= allgroups(:,:,dataindx,:);
        %     % get max value of this data (theta, alpha, 
        %     maxValue = max( allgroupsCurrentData ,[],'all'); 
        %     minValue = min( allgroupsCurrentData ,[],'all');

            currentMedian = mean(allgroupsCurrentData,'all');
            currentSTD    = std(allgroupsCurrentData,0,'all');

            thresholdPos = currentMedian +  2*currentSTD;
            thresholdNeg = currentMedian -  2*currentSTD;


            minValue = thresholdNeg;
            maxValue = thresholdPos;

            subplotIndx = 0;
            for groupi = 1:length(EEG_topo_avg)               
                
                % bypass topo plot of parts if this is only ads (no parts data)
                % or if this group has no data on this field
                if isempty(EEG_topo_avg(groupi).(fieldindx{:}))
                    continue
                end
                data = mean(EEG_topo_avg(groupi).(fieldindx{:})(:,:,dataindx),2);


                f = figure('visible','off'); 

                % plot topographic 

                topoplot(data,chanInfoFile,'style','map','plotrad',0.55,'maplimits',[minValue maxValue]); % channel info retrieved from external file. 

                % format figure 
                set(gca,'tickdir','out','XColor',[0 0 0], 'YColor', [0 0 0],'FontSize',8,'box','off');  
                fieldName = strrep(fieldindx{:},'_','-');

                titleText = ['G',num2str(groupi),' GA',':  ',fieldName];

                title(titleText)

                % change and create directory for this plot's save
                registeryDirectory = [figureSavePath '\frequency'];
                registeryDirectory = [registeryDirectory, '\',currentFreqData,'\',fieldindx{:},'\'];
                if ~exist(registeryDirectory, 'dir')
                   mkdir(registeryDirectory)
                end                
                cd(registeryDirectory)
                disp([registeryDirectory, '\',currentFreqData,'\',fieldindx{:},'\'])
                % save figure
                saveas(f,['group',num2str(groupi),'_grandAvg', '.jpg']);                 
                clf;
                

            end



        end
    end   
    
    
    
    
    
%     
%     %% GROUP PLOTS %% GRAND AVERAGE %% 
%     for dataindx = 1:length(freqDataNames)
% 
%         % get the current frequency data name (theta, alpha, beta, attention)
%         currentFreqData = freqDataNames{dataindx};
%   
%             
%             for fi = nonDataIndx:length(fnames)
%                 fieldindx = fnames(fi);
%                  %% find mean and std for plot color range
%                 allgroups = cat(4,EEG_topo_avg(1).(fieldindx{:}),EEG_topo_avg(2).(fieldindx{:}));% histData; 
%                 allgroupsCurrentData= allgroups(:,:,dataindx,:);
% 
%                 % no group data 
%     %             allgroups = EEG_topo_avg.(fieldindx{:});
%     %             allgroupsCurrentData = reshape(allgroups,[size(allgroups,1)*size(allgroups,2)*size(allgroups,3),1]);
%     %                        
% 
%                 currentMedian = median(allgroupsCurrentData,'all');
%                 currentSTD    = std(allgroupsCurrentData,0,'all');
% 
%                 thresholdPos = currentMedian +  2*currentSTD;
%                 thresholdNeg = currentMedian -  2*currentSTD;
% 
%                 minValue = thresholdNeg;
%                 maxValue = thresholdPos;
% 
%                 if fi == nonDataIndx
%                     f = figure('visible','off'); 
%                 else
%                     clf;
%                 end
% 
% 
%                 subplotIndx = 0;
% 
%                 % bypass topo plot if this group has no data on this field
%                 if isempty(EEG_topo_avg.(fieldindx{:}))
%                     continue
%                 end
% 
%                 fprintf('\nPROCESSED PLOT: %s\n%s\n%s \n',currentFreqData,fieldindx{:});  
%                 % average across time 
%                 data = mean(EEG_topo_avg.(fieldindx{:})(:,:,dataindx),2);
% 
% 
%                 % plot topographic 
%                 topoplot(data,EEG_topo_avg.A_channels,'style','map','plotrad',0.55,'maplimits',[minValue maxValue]); % channel info retrieved from external file. 
% 
%                 % format figure 
%                 set(gca,'tickdir','out','XColor',[0 0 0], 'YColor', [0 0 0],'FontSize',8,'box','off');  
% 
%                 fieldName = strrep(fieldindx{:},'_','-');
% 
%                 titleText = ['GA',':  ',fieldName];
% 
%                 title(titleText)
% 
% 
%                 % change and create directory for this plot's save
%                 registeryDirectory = [savePath '\plots\frequency\grouped\'];
%                 registeryDirectory = [registeryDirectory, '\',currentFreqData];
%                 if ~exist(registeryDirectory, 'dir')
%                    mkdir(registeryDirectory)
%                 end                
%                 cd(registeryDirectory)
% 
%                 % save figure
%                 saveas(f,[fieldindx{:}, '_GA.jpg']);      
%                 clf;
% 
%             end
%         end
% 
%     end

%             % IF THERE ARE GROUPS
%         fieldindx = averageFields
% 
%         checkData = EEG_topo_video(parti).(fieldindx{:});
%         % start of averaging loop, enable only if there are groups.
% 
% 
%         for averagei = 1:3
%             groupinterval   = groupsIndx(averagei).index;
%             groupNumber     = groupsIndx(averagei).group;
% 
%             groupdata = mean(cat(4,EEG_topo_freq(groupinterval).(fieldindx{:})),4);
% 
% %             % skip if this group does not have valid data in this field
% 
%            if isempty(groupdata)
%                 continue
%             end
%         end
    
%    %% GROUPED TOPO PLOTS %% 
%     % topographic plot of 30s averaged data (first-middle_last) by groups 
% 
%     secondTitles = {'Start', 'Middle','End'};
%     iteration = 0;
% 
%     freqDataNames = EEG_topo_avg(1).A_dataNames;
%     fieldindx = averageFields(1); % initialzie data field name for debugging.
%     for dataindx = 1:length(freqDataNames)
% 
%         % get the current frequency data name (theta, alpha, beta, attention)
%         currentFreqData = freqDataNames{dataindx};
% 
% 
%         moveToNextField = 0;
%         for fieldindx = averageFields
%              %% find mean and std for plot color range
%             allgroups = cat(4,EEG_topo_avg(1).(fieldindx{:}),EEG_topo_avg(2).(fieldindx{:}),EEG_topo_avg(3).(fieldindx{:}));% histData; 
%             allgroupsCurrentData= allgroups(:,:,dataindx,:);
%         %     % get max value of this data (theta, alpha, 
%         %     maxValue = max( allgroupsCurrentData ,[],'all'); 
%         %     minValue = min( allgroupsCurrentData ,[],'all');
% 
%             currentMedian = median(allgroupsCurrentData,'all');
%             currentSTD    = std(allgroupsCurrentData,0,'all');
% 
%             thresholdPos = currentMedian +  2*currentSTD;
%             thresholdNeg = currentMedian -  2*currentSTD;
% 
%             minValue = thresholdNeg;
%             maxValue = thresholdPos;
% 
%             f = figure('visible','off'); 
% 
%             subplotIndx = 0;                                                                
% 
% 
%             data = EEG_topo_avg(groupi).(fieldindx{:})(:,parti,dataindx);
% 
% 
% 
%             % figure generation index 
%             iteration = iteration+1;
%             subplotIndx = subplotIndx+1;
%             % 3x3 plot, groups (1-2-3) by rows, time (first-mid-last) by columns
%             subplot(3,3,subplotIndx)
% 
%             % plot topographic 
% 
%             topoplot(data,chanInfoFile,'style','map','plotrad',0.55,'maplimits',[minValue maxValue]); % channel info retrieved from external file. 
% 
%             % format figure 
%             set(gca,'tickdir','out','XColor',[0 0 0], 'YColor', [0 0 0],'FontSize',8,'box','off');  
%             fieldName = strrep(fieldindx{:},'_','-');
%             if subplotIndx == 1
%                 titleText = ['G',num2str(groupi),' ',secondTitles{parti},':  ',fieldName];
%             else
%                 titleText = ['G',num2str(groupi),' ',secondTitles{parti}];
%             end
% 
%             title(titleText)
% 
% 
% 
%             
%             if moveToNextField == 1
%                 moveToNextField = 0; 
%                 continue
%             end
%             
%             % change and create directory for this plot's save
%             registeryDirectory = [savePath '\plots\frequency\grouped\'];
%             registeryDirectory = [registeryDirectory, '\',currentFreqData];
%             if ~exist(registeryDirectory, 'dir')
%                mkdir(registeryDirectory)
%             end                
%             cd(registeryDirectory)
% 
%             % save figure
%             saveas(f,[fieldindx{:}, '.jpg']);      
%             clf;
% 
%         end
% 
%     end

    
% 
%     %% SINGLE TOPO PLOTS %% 
%     f = figure('visible','off'); 
%     % fieldindx = averageFields(1);
%     for dataindx = 1:length(freqDataNames)
% 
%         currentFreqData = freqDataNames{dataindx};
%         for fieldindx = averageFields
% 
%              %% find mean and std for plot color range
%             allgroups = cat(4,EEG_topo_avg(1).(fieldindx{:}),EEG_topo_avg(2).(fieldindx{:}),EEG_topo_avg(3).(fieldindx{:}));% histData; 
%             allgroupsCurrentData= allgroups(:,:,dataindx,:);
%         %     % get max value of this data (theta, alpha, 
%         %     maxValue = max( allgroupsCurrentData ,[],'all'); 
%         %     minValue = min( allgroupsCurrentData ,[],'all');
% 
%             currentMedian = mean(allgroupsCurrentData,'all');
%             currentSTD    = std(allgroupsCurrentData,0,'all');
% 
%             thresholdPos = currentMedian +  2*currentSTD;
%             thresholdNeg = currentMedian -  2*currentSTD;
% 
% 
%             minValue = thresholdNeg;
%             maxValue = thresholdPos;
% 
%             subplotIndx = 0;
% 
%             
%             for groupi = 1:3
%                 
%             % bypass topo plot of parts if this is only ads (no parts data)
%             % or if this group has no data on this field
%             if size(EEG_topo_avg(groupi).(fieldindx{:}),2)<3 || isempty(EEG_topo_avg(groupi).(fieldindx{:}))
%                 continue
%             end
% 
%                 for parti = 1:3
% 
%                     data = EEG_topo_avg(groupi).(fieldindx{:})(:,parti,dataindx);
% 
% 
%                     f = figure('visible','off'); 
%                     % figure generation index 
%                     iteration = iteration+1;
%                     subplotIndx = subplotIndx+1;
% 
%                     % plot topographic 
% 
%                     topoplot(data,chanInfoFile,'style','map','plotrad',0.55,'maplimits',[minValue maxValue]); % channel info retrieved from external file. 
% 
%                     % format figure 
%                     set(gca,'tickdir','out','XColor',[0 0 0], 'YColor', [0 0 0],'FontSize',8,'box','off');  
%                     fieldName = strrep(fieldindx{:},'_','-');
% 
%                     titleText = ['G',num2str(groupi),' ',secondTitles{parti},':  ',fieldName];
% 
%                     title(titleText)
% 
%                     % change and create directory for this plot's save
%                     registeryDirectory = [savePath '\plots\frequency\single_plots'];
%                     registeryDirectory = [registeryDirectory, '\',currentFreqData,'\',fieldindx{:},'\'];
%                     if ~exist(registeryDirectory, 'dir')
%                        mkdir(registeryDirectory)
%                     end                
%                     cd(registeryDirectory)
%                     disp([registeryDirectory, '\',currentFreqData,'\',fieldindx{:},'\'])
%                     % save figure
%                     saveas(f,['group',num2str(groupi),'_',secondTitles{parti}, '.jpg']);                 
%                     clf;
%                 end
% 
%             end
%         end
%     end
% 
%             
            
    %% SINGLE TOPO PLOTS %%  GRAND AVERAGE %% 
    
    % GRAND AVERAGED TOPO PLOTS %% 
    fnames = fieldnames(EEG_topo_avg);
    % find subject related non-data channel indices 
    nonDataFields = regexp(fnames,'A_');
    nonDataIndx = find([nonDataFields{:}]==1);
    nonDataIndx = nonDataIndx(end);
    nonDataIndx = nonDataIndx+1; % data starts 1 field after the non-data fields.
    
    
    freqDataNames = EEG_topo_avg(1).A_dataNames;    
    
    
%     f = figure('visible','off'); 
%     % fieldindx = averageFields(1);
%     for dataindx = 1:length(freqDataNames)
% 
%         currentFreqData = freqDataNames{dataindx};
%         for fieldindx = averageFields
% 
%              %% find mean and std for plot color range
%             allgroups = cat(4,EEG_topo_avg(1).(fieldindx{:}),EEG_topo_avg(2).(fieldindx{:}),EEG_topo_avg(3).(fieldindx{:}));% histData; 
%             allgroupsCurrentData= allgroups(:,:,dataindx,:);
%         %     % get max value of this data (theta, alpha, 
%         %     maxValue = max( allgroupsCurrentData ,[],'all'); 
%         %     minValue = min( allgroupsCurrentData ,[],'all');
% 
%             currentMedian = mean(allgroupsCurrentData,'all');
%             currentSTD    = std(allgroupsCurrentData,0,'all');
% 
%             thresholdPos = currentMedian +  2*currentSTD;
%             thresholdNeg = currentMedian -  2*currentSTD;
% 
% 
%             minValue = thresholdNeg;
%             maxValue = thresholdPos;
% 
%             subplotIndx = 0;
%             for groupi = 1:length(group               
%                 
%                     % bypass topo plot of parts if this is only ads (no parts data)
%                     % or if this group has no data on this field
%                     if isempty(EEG_topo_avg(groupi).(fieldindx{:}))
%                         continue
%                     end
%                     data = mean(EEG_topo_avg(groupi).(fieldindx{:})(:,:,dataindx),2);
% 
% 
%                     f = figure('visible','off'); 
%                     % figure generation index 
%                     iteration = iteration+1;
%                     subplotIndx = subplotIndx+1;
% 
%                     % plot topographic 
% 
%                     topoplot(data,chanInfoFile,'style','map','plotrad',0.55,'maplimits',[minValue maxValue]); % channel info retrieved from external file. 
% 
%                     % format figure 
%                     set(gca,'tickdir','out','XColor',[0 0 0], 'YColor', [0 0 0],'FontSize',8,'box','off');  
%                     fieldName = strrep(fieldindx{:},'_','-');
% 
%                     titleText = ['G',num2str(groupi),' GA',':  ',fieldName];
% 
%                     title(titleText)
% 
%                     % change and create directory for this plot's save
%                     registeryDirectory = [savePath '\plots\frequency\single_plots'];
%                     registeryDirectory = [registeryDirectory, '\',currentFreqData,'\',fieldindx{:},'\'];
%                     if ~exist(registeryDirectory, 'dir')
%                        mkdir(registeryDirectory)
%                     end                
%                     cd(registeryDirectory)
%                     disp([registeryDirectory, '\',currentFreqData,'\',fieldindx{:},'\'])
%                     % save figure
%                     saveas(f,['group',num2str(groupi),'_grandAvg', '.jpg']);                 
%                     clf;
%                 
% 
%             end
% 
% 
% 
%         end
%     end
    
    
    
    
end