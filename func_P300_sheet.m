function [EEG_P300] = func_P300_sheet(EEG_epoch,savePath)


cd(savePath)
% load('segmented_data_1')
% load('psd_data_seconds_segmented_4')
% segmentedDataFile = 'segmented_data_newProcessed_intp_1.mat';
% load(segmentedDataFile);


EEG_P300 = struct();

fnames = fieldnames(EEG_epoch);    % get header names to find comp accuracy indx
% find subject related non-data channel indices 
nonDataFields = regexp(fnames,'A_');
nonDataIndx = find([nonDataFields{:}]==1);
nonDataIndx = nonDataIndx(end);
nonDataIndx = nonDataIndx+1; % data starts 1 field after the non-data fields.   

srate = EEG_epoch(1).A_srate;
% decide P300 time window (1 s duration, first 64 are -250 ms, remaining
% are 0 to 750ms)
timewin = 1 : srate;

% loop over participants 
for pi = 1:length(EEG_epoch)
    
    
    EEG_P300(pi).A_subject  = EEG_epoch(pi).A_subject;
    EEG_P300(pi).A_group    = EEG_epoch(pi).A_group; %EEG_epoch(pi).A_group;
    EEG_P300(pi).A_srate    = EEG_epoch(pi).A_srate;
    EEG_P300(pi).A_chanlocs = EEG_epoch(pi).A_chanlocs;
    
    fprintf('\n******PROCESSED PARTICIPANT: %s ******\n',EEG_epoch(pi).A_subject); 
    
    %% start to loop over data fields 
    fi = 5;
    for fi = nonDataIndx:length(fnames)
            % get data ( dims(chan,time,trial) )
            data = EEG_epoch(pi).(fnames{fi});
            
            % continue to next data if this is empty 
            if isempty(data)
                continue
            end
            % initialize data field for concatenation 
            EEG_P300(pi).(fnames{fi}) = [];

            fprintf('\nCondition: %s \n',fnames{fi}); 
            
            %% if there are more than 1 trials
            if size(data,3)> 1
                
                % loop over trials to get 1 s data and concatenate
                for ti = 1:size(data,3)
                    trial_data = data(:,timewin,ti);
                    trial_data = permute(trial_data,[2 1]);
                    EEG_P300(pi).(fnames{fi}) = cat(3,EEG_P300(pi).(fnames{fi}),trial_data);
                    
                end
                EEG_P300(pi).(fnames{fi}) = mean(EEG_P300(pi).(fnames{fi}),3);
            else
                % change dimensions for plots ( dims(time,chan) )
                data = permute(data,[2 1]);       
                
                % get the first 1 s 
                topo_data = data(timewin,:);            
                
                % register data 
                EEG_P300(pi).(fnames{fi}) = topo_data - nanmean(topo_data(1:64,:),1);
                
            end



    end     
            

    
end

% change dir to save path
cd(savePath);

% name of the segmented dataset variable as a file
segmentedData = 'EEG_P300_data.mat';
%% save EEG_psd_data 
save(segmentedData,'EEG_P300','-v7.3');



% get group indices


groupsIndx = struct();
% initialize group index variable
groupsIndx(1).index =[];
groupsIndx(1).group =[];
groupsIndx(2).index =[];
groupsIndx(2).group =[];


for pi = 1:length(EEG_P300)
    % get group of this participant
    currentGroup = EEG_P300(pi).A_group;
    
    % append participant to the group
    groupsIndx(currentGroup).index = cat(2,groupsIndx(currentGroup).index,pi);
    
    % indicate which group in the structure
    groupsIndx(currentGroup).group = currentGroup;
end

load('channelInfo.mat') % load chanInfoFile variable into workspace
allChannels = {chanInfoFile.labels};


times = -.250:1/256:.748;

p300_window = findIndices(times, [.300 .400]);

p300_window = p300_window(1):p300_window(2);

fnames = fieldnames(EEG_P300);
% find subject related non-data channel indices 
nonDataFields = regexp(fnames,'A_');
nonDataIndx = find([nonDataFields{:}]==1);
nonDataIndx = nonDataIndx(end);
nonDataIndx = nonDataIndx+1; % data starts 1 field after the non-data fields.


% loop over groups, each group will be written into different sheets 
for gri = 1:length(groupsIndx)
    
    currentGroupIndx    = groupsIndx(gri).index;
    currentGroup        = groupsIndx(gri).group;
    
    % new directory for the event
    registeryDirectory = [savePath '\sheets\P300'];

    % change directory
    if ~exist(registeryDirectory, 'dir')
       mkdir(registeryDirectory)
    end                
    cd(registeryDirectory)

    % current csv sheet name (subid_freq_eventName)
    current_sheet_name = ['group',num2str(currentGroup),'_p300.csv'];


    eventSheet = {};
    % create column headers for the datasheet
    eventSheet(1,1) = {'channels'};

    % iteration index for registering each of the markers on a separate row
    % of the table      
    
    fieldIndx = 1; 
    for fi = nonDataIndx:length(fnames)
        % an index variable for writing accurately to headers 
        fieldIndx = fieldIndx +1;
        
        currentField = fnames{fi};
        eventSheet(1,fieldIndx) = {currentField};
        % loop over channels 
        for chi =  1:length(allChannels)
            currentChannel = allChannels{chi}; 
            
            eventSheet(chi+1,1) = {currentChannel};
            
            channelDataBank = [];
            % loop over participants        
            for pi = currentGroupIndx

                subj_chans = {EEG_P300(pi).A_chanlocs.labels};
                % check if current channel exists in this participant 
                channelIndx = find(strcmp(subj_chans,currentChannel)); 

                % skip to next participant if this one does not have this
                % channel 
                if isempty(channelIndx) || isempty(EEG_P300(pi).(currentField))
                    continue
                end
    
                % get data of this channel 
                chandata = nanmean(EEG_P300(pi).(currentField)(p300_window,channelIndx),1);
                
                % store each participant's data into the bank for future
                % averaging
                channelDataBank = [channelDataBank, chandata];


            end
            
            % get average of this channel across participants 
            averageChannelValue = round(nanmean(channelDataBank),2); 
            % get standard deviation of this channel across participants 
            averageChannelstd   = round(std(channelDataBank,0,'omitnan'),2); 
            
            cellInput = [num2str(averageChannelValue),' (',num2str(averageChannelstd),')'];
            
            % add averaged value to the sheet 
            eventSheet(chi+1,fieldIndx) = {cellInput}; 

        end
    end
    
    % write sheet as csv     
    % get headers of the sheet 
    headers             = eventSheet(1,:);
    % remove headers for the table conversion 
    eventSheet(1,:)     = [];
    % convert sheet to table 
    eventSheet          = cell2table(eventSheet); 
    % add headers to the table 
    eventSheet.Properties.VariableNames = headers;
    % write table as csv
    writetable(eventSheet,current_sheet_name);
    
    
    
    
end

