function func_cognitiveSecondsSheet(EEG_psd_second,savePath)
    cd(savePath)

    % loads > EEG_psd_second:  contains data segmented by each second for each event 
    % load('psd_data_seconds_segmented_4.mat');  
%     psdSecondsDataFile = 'psd_data_seconds_segmented_newProcessed_intp_4.mat';
    % load(psdSecondsDataFile);  
    %  new preprocessing parameters 
    %%  COGNITIVE INDEX CALCULATION  

    %% initialize cognitive index structure 

    cognitiveIndex = struct();

    % attitude (log right - log left)
    cognitiveIndex(1).process = 'attitude';
    cognitiveIndex(1).channels = {{'F4','F8'},{'F3','F7'}};

    %retrieval 
    cognitiveIndex(2).process = 'retrieval';
    cognitiveIndex(2).channels = {'F4','F8'};

    %encoding 
    cognitiveIndex(3).process = 'encoding';
    cognitiveIndex(3).channels = {'F3','F7'};

    %engagement 
    cognitiveIndex(4).process = 'engagement';
    cognitiveIndex(4).channels = {'FP1','FP2', 'F3', 'F4', 'F7', 'F8', 'Fz'};


    % attention 
    cognitiveIndex(5).process = 'attention';
    cognitiveIndex(5).channels = {'P3','P4'};  % legacy attention 

    % attention 2 
    cognitiveIndex(6).process = 'attention2';
    cognitiveIndex(6).channels = {'FP1','FP2', 'F3', 'F4', 'F7', 'F8', 'Fz','C3', 'Cz','C4','P3','P4','Pz'}; % new attention metric for 19/03/2023 request by Thapa

    %trust 
    cognitiveIndex(7).process = 'trust';
    cognitiveIndex(7).channels = {'F3', 'Fz', 'C3', 'Cz'};

    % sensory  
    cognitiveIndex(8).process = 'sensory';
    cognitiveIndex(8).channels = {'P3', 'Pz', 'P4'};

    % visual 
    cognitiveIndex(9).process = 'visual';
    cognitiveIndex(9).channels = {'O1', 'O2'};
    
    % emotional valence
    cognitiveIndex(10).process = 'emotional_valence';
    cognitiveIndex(10).channels = {{'F3','C3'},{'F4','C4'}};    
    %% psd second frequency specific

    freqs = {'delta','theta','alpha','sigma','beta','gamma'};
    ranges = {[0.5, 4.5],[4.5,8.5],[8.5,11.5],[11.5,15.5],[15.5,30],[30,45]};
    freq_ranges = cat(1,freqs,ranges);

    fnames = fieldnames(EEG_psd_second);
    % find subject related non-data channel indices 
    nonDataFields = regexp(fnames,'A_');
    nonDataIndx = find([nonDataFields{:}]==1);
    nonDataIndx = nonDataIndx(end);
    nonDataIndx = nonDataIndx+1; % data starts 1 field after the non-data fields.

    cognitiveIndices = {'attitude','retrieval','encoding','engagement','attention','attention2','trust','sensory','visual','emotional_valence'};

    for pi = 1:length(EEG_psd_second)


        allFreqs = EEG_psd_second(pi).A_frequencies;
        fprintf('\n******PROCESSED PARTICIPANT: %s ******\n',EEG_psd_second(pi).A_subject); 

        % get channel labels for this participant 
        channels = {EEG_psd_second(pi).A_chanlocs(:).labels};
        subject = EEG_psd_second(pi).A_subject;
        group = 'study';  % EEG_psd_second(pi).A_group;
        %% change data file name for eeglab sets
        underScoreIndex = strfind(subject,'_'); %  find the '_eeg' in subject ID name and remove that part
        subject(underScoreIndex:end)=[]; % remove _eeg from subject id
        subject = {subject}; % convert to cell type for later processing


        %% start to loop from data fields (start from nonDataIndx th field) 
            for fi = nonDataIndx:length(fnames)            

                % if there is no such field for this participant, skip to next
                % field
                if ~isfield(EEG_psd_second(pi),fnames{fi})
                    continue                 
                end

                % current field name
                current_field = fnames{fi};         
                % previous field name (reqiured for creating new sheets for
                % each of the different events) 
                previous_field = fnames{fi-1};

                appendToSheet = strcmp(current_field,previous_field);

                if appendToSheet        

                    % do nothing, continue estimations

                else
                    % if this is a new type of event we are registering, save
                    % previous event sheet as csv.  and continue to next one 

                    % check if eventSheet was created, if not, there is no need
                    % to register it yet; this is the first time it'll be
                    % created
                    if exist('eventSheet','var') && size(eventSheet,1)>=2
                        cd(registeryDirectory)
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
%                         writecell(eventSheet,current_sheet_name)
                    end

                    % new directory for the event
                    registeryDirectory = [savePath '\sheets\participant_level\'];

                    % add participant name and SECONDS to directory 
                    registeryDirectory = [registeryDirectory,subject{:},'\seconds'];

                    % add frequency range name to directory
                    registeryDirectory = [registeryDirectory,'\','cognitiveIndex'];

                    % change directory
                   if ~exist(registeryDirectory, 'dir')
                       mkdir(registeryDirectory)
                    end                
                    cd(registeryDirectory)

                    % current csv sheet name (subid_freq_eventName)
                    current_sheet_name = [subject{:},'_cognitiveIndex_',current_field,'.csv'];


                    eventSheet = {};
                    % create column headers for the datasheet
                    eventSheet(1,:) = cat(2,{'subject'},{'group'},{'event_name'},{'timeStamp'},cognitiveIndices);

                    % iteration index for registering each of the markers on a separate row
                    % of the table

                    sheetIteration = 1;                
                end

                % get indices of frequencies to calculate cognitive process
                % indices                       

                % initialize lists
                freqNames = {};
                freqRanges = {};
                freqIndices = {};

                % 2 3 4 are indices of theta, alpha, and beta
                for freqi = [2 3 4 6] 
                    freqNames = cat(1,freqNames,freq_ranges(1,freqi));
                    freqRanges = cat(1,freqRanges,freq_ranges(2,freqi));                

                    current_range = freq_ranges{2,freqi};

                    lowIndex = find(allFreqs == current_range(1));
                    highIndex = find(allFreqs == current_range(2));   

                    freqIndices = cat(1,freqIndices,{lowIndex:highIndex});
                end


                % get data
                data = EEG_psd_second(pi).(fnames{fi});

                % if there are no seconds (3rd dim) in the data (or basically its empty)
                % proceed to next data field
                if length(size(data)) < 3
                    continue 
                end
                % get how many seconds in the data
                loopOverSeconds = size(data,3);                


                    % loop over each second for this event 
                    for secondIndx = 1:loopOverSeconds

                        % move one row below for appending data
                        sheetIteration = sheetIteration+1;

                        % register id, event name_no, and time stamp
                        eventSheet{sheetIteration,1} = subject{:};
                        eventSheet{sheetIteration,2} = group;
                        eventSheet{sheetIteration,3} = current_field;
                        eventSheet{sheetIteration,4} = secondIndx;

                        % how many headers are there before the data cells
                        occupiedHeaders = 4;

                        % get data of this second 

                        inputData = data(:,:,secondIndx);

                        % get the mean of this frequency range 
                        theta_data = mean(inputData(freqIndices{1},:),1);
                        alpha_data = mean(inputData(freqIndices{2},:),1);
                        beta_data = mean(inputData(freqIndices{3},:),1); 
                        gamma_data = mean(inputData(freqIndices{4},:),1); 

                        % loop over cognitive indices                        
                        for cogi = 1:length(cognitiveIndex)

                                processName = cognitiveIndex(cogi).process;
                                cogChannels = cognitiveIndex(cogi).channels;

                                % ATTITUDE            
                                if strcmp(processName,'attitude')

                                    % get right (1) and left (2) channels
                                    cogChannels1 = cogChannels{1};
                                    cogChannels2 = cogChannels{2};

                                    % check if participants at least one of
                                    % these channels 
                                    existIndx1 = ismember(channels,cogChannels1);
                                    existIndx2 = ismember(channels,cogChannels2);

                                    % get existing channel indices
                                    chanIndx1 = find(existIndx1==1);
                                    chanIndx2 = find(existIndx2==1);

                                    % if any of the channel pairs are completely
                                    % non-existent, skip attitude calculation.
                                    if isempty(chanIndx1) || isempty(chanIndx2)

                                        continue

                                    else

                                        % get channel data for right and left
                                        % pairs
                                        rightChans = mean(alpha_data(chanIndx1));
                                        leftChans = mean(alpha_data(chanIndx2));

                                        % log subtraction for attitude
                                        indexInput = rightChans-leftChans;

                                        % register data to sheet
                                        eventSheet{sheetIteration,occupiedHeaders+cogi} = indexInput;

                                    end


                                elseif strcmp(processName,'retrieval')

                                    existIndx =  ismember(channels,cogChannels);
                                    chanIndx = find(existIndx==1);


                                    % skip to next process if there is no
                                    % viable channels to compute                                
                                    if isempty(chanIndx)                                    
                                        continue                                    
                                    end


                                    % calculate register data to sheet
                                    indexInput = mean(theta_data(chanIndx));
                                    eventSheet{sheetIteration,occupiedHeaders+cogi} = indexInput;


                                elseif  strcmp(processName,'encoding')

                                    existIndx =  ismember(channels,cogChannels);
                                    chanIndx = find(existIndx==1);

                                    % skip to next process if there is no
                                    % viable channels to compute
                                    if isempty(chanIndx)                                    
                                        continue                                    
                                    end

                                    % calculate register data to sheet                                
                                    indexInput = mean(theta_data(chanIndx));
                                    eventSheet{sheetIteration,occupiedHeaders+cogi} = indexInput;
                                elseif  strcmp(processName,'engagement')

                                    existIndx =  ismember(channels,cogChannels);
                                    chanIndx = find(existIndx==1);    

                                    % skip to next process if there is no
                                    % viable channels to compute                                
                                    if isempty(chanIndx)                                    
                                        continue                                    
                                    end

                                    indexInput = mean(beta_data(chanIndx));
                                    eventSheet{sheetIteration,occupiedHeaders+cogi} = indexInput;


                                elseif  strcmp(processName,'attention') || strcmp(processName,'attention2')

                                    existIndx =  ismember(channels,cogChannels);
                                    chanIndx = find(existIndx==1);   

                                    % skip to next process if there is no
                                    % viable channels to compute                                
                                    if isempty(chanIndx)                                    
                                        continue                                    
                                    end                

                                    averagedThetaData = mean(theta_data(chanIndx));
                                    averagedAlphaData = mean(alpha_data(chanIndx));

                                    % calculate register data to sheet
                                    indexInput = averagedThetaData / averagedAlphaData;   
                                    eventSheet{sheetIteration,occupiedHeaders+cogi} = indexInput;

                                elseif  strcmp(processName,'trust')

                                    existIndx =  ismember(channels,cogChannels);
                                    chanIndx = find(existIndx==1);

                                    % skip to next process if there is no
                                    % viable channels to compute                                
                                    if isempty(chanIndx)                                    
                                        continue                                    
                                    end                                

                                    % calculate register data to sheet
                                    indexInput = mean(beta_data(chanIndx));
                                    eventSheet{sheetIteration,occupiedHeaders+cogi} = indexInput;

                                elseif  strcmp(processName,'sensory')

                                    existIndx =  ismember(channels,cogChannels);
                                    chanIndx = find(existIndx==1);

                                    % skip to next process if there is no
                                    % viable channels to compute                                
                                    if isempty(chanIndx)                                    
                                        continue                                    
                                    end                                

                                    % calculate register data to sheet
                                    indexInput = mean(alpha_data(chanIndx));
                                    eventSheet{sheetIteration,occupiedHeaders+cogi} = indexInput;       

                                elseif  strcmp(processName,'visual')

                                    existIndx =  ismember(channels,cogChannels);
                                    chanIndx = find(existIndx==1);

                                    % skip to next process if there is no
                                    % viable channels to compute                                
                                    if isempty(chanIndx)                                    
                                        continue                                    
                                    end                                

                                    % calculate register data to sheet
                                    indexInput = mean(alpha_data(chanIndx));
                                    eventSheet{sheetIteration,occupiedHeaders+cogi} = indexInput;   
                                    
                                elseif strcmp(processName,'emotional_valence')

                                    % get right (1) and left (2) channels
                                    cogChannels1 = cogChannels{1};
                                    cogChannels2 = cogChannels{2};

                                    % check if participants at least one of
                                    % these channels 
                                    existIndx1 = ismember(channels,cogChannels1);
                                    existIndx2 = ismember(channels,cogChannels2);

                                    % get existing channel indices
                                    chanIndx1 = find(existIndx1==1);
                                    chanIndx2 = find(existIndx2==1);

                                    % if any of the channel pairs are completely
                                    % non-existent, skip attitude calculation.
                                    if isempty(chanIndx1) || isempty(chanIndx2)

                                        continue

                                    else

                                        % get channel data for right and left
                                        % pairs
                                        rightChans = mean(gamma_data(chanIndx1));
                                        leftChans = mean(gamma_data(chanIndx2));

                                        % get ratio of gamma 
                                        indexInput = (rightChans - leftChans) - sum(gamma_data(chanIndx1));

                                        % register data to sheet
                                        eventSheet{sheetIteration,occupiedHeaders+cogi} = indexInput;

                                    end

                                end


                         end         

                    end
            end






    end
end
    % plot(freqs,psd_data)
    % xlabel('Frequency (Hz)')
    % ylabel('PSD (dB/Hz)')         