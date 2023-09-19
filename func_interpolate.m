function [EEG_epoch] = func_interpolate(EEG_epoch,ALLEEG,artifactStructure,savePath)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% interpolate channels and exclude participants %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    cd(savePath)
    % load('segmented_data_newProcessed_1.mat')
%     load('badChannelInfo_2.mat')
%     load('all_eeg_template.mat')
    % get all subject names from ALLEEG template (used for EEGLAB functions)
    alleeg_subjects ={ALLEEG.setname};
    % get all subject names from channel interpolation info variable
    artf_subjects = {artifactStructure.A_subject};
    % get all data field names from segmented data
    plotFields = fieldnames(EEG_epoch);
    % find subject related non-data channel indices 
    nonDataFields = regexp(plotFields,'A_');
    nonDataIndx = find([nonDataFields{:}]==1);
    nonDataIndx = nonDataIndx(end);
    nonDataIndx = nonDataIndx+1; % data starts 1 field after the non-data fields.
    
    
    EEG_epoch_intp = EEG_epoch;

    excludeIndex = 0;
    reshapeData  = 0;
    excludedParticipantIndex = [];
    for pi = 1:length(EEG_epoch_intp)
        % get sub id
        subID   = EEG_epoch_intp(pi).A_subject;
        % match id with artifact - chan info data
        matchSub = ismember(artf_subjects,subID);
        % find p index in chan info data
        subIndx = find(matchSub);
        if isempty(subIndx)
            % EXCLUDE
            % if channel info data does not have the participant
            excludedParticipantIndex = [excludedParticipantIndex,pi];
            continue
        end
        % match id with template ALLEEG, this is used for channel
        % interpolationg function (pop_interp)    
        matchSubALLEEG = ismember(artf_subjects,subID);  

        subIDmatch  = regexp(alleeg_subjects,subID);
        alleegIndx  = find(~cellfun(@isempty,subIDmatch));

        % get exclusion info (1=yes exclude,0=no don't)
        
        
        excludeParticipant = artifactStructure(subIndx).exclude;
%         assignin('base','subIndx',pi)
%         assignin('base','excludeParticipant',excludeParticipant)
        if excludeParticipant == 1
            % increase exclude index by one so that You'll see how many ps were
            % excluded 
            excludeIndex = excludeIndex+1;

            fprintf('%s. Subject %s excluded.\n',num2str(excludeIndex),subID);
            % remove participant from data
            excludedParticipantIndex = [excludedParticipantIndex, pi];

        end

        % get bad channels that'll be interpolated
        badChans = artifactStructure(subIndx).bad_channels;

        % print interpolation info
        fprintf('Subject %s, interpolated channels: %s\n',subID,artifactStructure(subIndx).bad_channels_text{:});

        EEG = ALLEEG(alleegIndx);


        % interpolate each data field one at a time

            for fieldsi = nonDataIndx:length(plotFields)
%                 fieldsi = 11;
                % get data of this field (e.g. RS_1, Pod_P1 etc.)
                data = EEG_epoch_intp(pi).(plotFields{fieldsi});  % EEG.data; 

                %% if there are more than 1 trials
                if size(data,3)> 1
                    
                    reshapeData = 1;
                    
                    dim1 = size(data,1);
                    dim2 = size(data,2);
                    dim3 = size(data,3);
                    
                    % reshape data into chan x time matrix
                    data = reshape(data,[dim1,dim2*dim3]);

                end

                if isempty(data) || isempty(badChans)

                    continue

                else

                    % trasnfer data to EEG structure for interpolation
                    EEG.data = data;
                    EEG.chanlocs = EEG_epoch_intp(pi).A_chanlocs;
                    % interpolate data
                    EEG = pop_interp(EEG, badChans, 'spherical');
                    disp(subIndx)
                    fprintf('\nConditions: %s\t',plotFields{fieldsi});
                    
                    if reshapeData == 1
                        reshapeData = 0;
                        EEG.data = reshape(EEG.data,[dim1,dim2,dim3]);
                    end                    
                    
                    % move interpolated data into segmented data structure
                    EEG_epoch_intp(pi).(plotFields{fieldsi}) = EEG.data;

                    disp(subIndx)
                end
            end

        % register interpolated channels in segmented data structure. 
        EEG_epoch_intp(pi).A_interpolatedChannels = artifactStructure(subIndx).bad_channels_text;




    end
    % remove excluded participants from the data
    EEG_epoch_intp(excludedParticipantIndex) = [];
    EEG_epoch = EEG_epoch_intp;
    EEG_epoch = orderfields(EEG_epoch);
    cd(savePath)
    save('segmented_data_newProcessed_intp_1.mat','EEG_epoch','-v7.3')
end