function func_psdSecondsSheets(EEG_psd_second,savePath)
    cd(savePath)
    % 
    % % % loads =EEG_psd_second:  contains data segmented by each second for each event 
    % psdSecondsDataFile = 'psd_data_seconds_segmented_newProcessed_intp_4.mat';
    % load(psdSecondsDataFile);  
    % 

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% for each participant and each trigger, create second by second csv sheets %%

    freqs = {'delta','theta','alpha','sigma','beta','gamma'};
    ranges = {[0.5, 4.5],[4.5,8.5],[8.5,11.5],[11.5,15.5],[15.5,30],[30,45]};
    freq_ranges = cat(1,freqs,ranges);

    fnames = fieldnames(EEG_psd_second);
    % find subject related non-data channel indices 
    nonDataFields = regexp(fnames,'A_');
    nonDataIndx = find([nonDataFields{:}]==1);
    nonDataIndx = nonDataIndx(end);
    nonDataIndx = nonDataIndx+1; % data starts 1 field after the non-data fields.

    for pi = 1:length(EEG_psd_second)


        allFreqs = EEG_psd_second(pi).A_frequencies;
        fprintf('\n******PROCESSED PARTICIPANT: %s ******\n',EEG_psd_second(pi).A_subject); 

        % get channel labels for this participant 
        channels = {EEG_psd_second(pi).A_chanlocs(:).labels};
        subject = EEG_psd_second(pi).A_subject;
%         group = EEG_psd_second(pi).A_group;
        group = 'study'; % dummy group variable
        %% change data file name for eeglab sets
        underScoreIndex = strfind(subject,'_'); %  find the '_eeg' in subject ID name and remove that part
        subject(underScoreIndex:end)=[]; % remove _eeg from subject id
        subject = {subject}; % conver to cell type for later processing

        %% start to loop over frequencies    
        for freqs = 1:length(freq_ranges)
            current_freq = freq_ranges{1,freqs};
            current_range = freq_ranges{2,freqs};
            lowIndex = find(allFreqs == current_range(1));
            highIndex = find(allFreqs == current_range(2));

            %% start to loop over data fields (nonDataIndx) (first nonDataIndx are, subid, channels, group,srate etc)
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
                    % created. Check if there is any registered data in the
                    % sheet (means you'll have >=2 rows in the sheet)
                    if exist('eventSheet','var') && size(eventSheet,1)>=2
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
                    registeryDirectory = [registeryDirectory,'\',current_freq];

                    % change directory
                    if ~exist(registeryDirectory, 'dir')
                       mkdir(registeryDirectory)
                    end                
                    cd(registeryDirectory)

                    % current csv sheet name (subid_freq_eventName)
                    current_sheet_name = [subject{:},'_',current_freq,'_',current_field,'.csv'];


                    eventSheet = {};
                    % create column headers for the datasheet
                    eventSheet(1,:) = cat(2,{'subject'},{'group'},{'event_name'},{'timeStamp'},channels);

                    % iteration index for registering each of the markers on a separate row
                    % of the table

                    sheetIteration = 1;                
                end

                % get data
                data = EEG_psd_second(pi).(fnames{fi});

                % if there are no seconds (3rd dim) in the data (or basically its empty)
                % proceed to next data field
                if length(size(data)) < 3  || isempty(data)
                    continue 
                end
                % get how many seconds in the data
                loopOverSeconds = size(data,3);

                % get the mean of this frequency range 
                current_data = squeeze(mean(data(lowIndex:highIndex,:,:),1));

                    % loop over each second for this event 
                    for secondIndx = 1:loopOverSeconds
                        
                        % move one row below for appending data
                        sheetIteration = sheetIteration+1;

                        % register id, event name_no, and time stamp
                        eventSheet{sheetIteration,1} = subject{:};
                        eventSheet{sheetIteration,2} = group;
                        eventSheet{sheetIteration,3} = current_field;
                        eventSheet{sheetIteration,4} = secondIndx;

                        % get data of this second 
                        inputData = current_data(:,secondIndx);

                        % loop over each channel
                        for chans = 1:size(current_data,1)

                            % register each channel's data to the sheet 
                            eventSheet{sheetIteration,4+chans} = inputData(chans);

                        end


                    end
            end


        end



    end
    % close all open csv's
    fclose('all')
end