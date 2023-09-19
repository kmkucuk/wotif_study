function [EEG_epoch] = func_segmentation_sheet_group(ALLEEG,savePath,markerPath,sheetName,groupSheet)

% savePath = 'E:\Backups\All Files\Genel\Is\2023\Tribikram\study Validation and Mood\data_output';
% markerPath = "none";
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT VARIABLES 
%
% ALLEEG = datasets loaded into EEGLAB's ALLEEG variable
% 
% savePath = directory in which you are going to save the segmented data
% variable (EEG_epoch) 
%
% markerPath = directory in which you'll load the event sheet. Type in
% "none" if you are not using an external data sheet. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




% initialize the storage for segmented datasets. 
EEG_epoch = struct();



% if there is valid path for the external event sheet 
if ~strcmp(markerPath,"none")
    
    % change dir to marker sheet's directory 
    cd(markerPath)
    
    % read event sheet as table for group 1
    markerSheet_g1 = readtable([sheetName,'1.xlsx']);
    markerSheet_g1 = table2cell(markerSheet_g1);
    % read event sheet as table for group 2
    markerSheet_g2 = readtable([sheetName,'2.xlsx']);
    markerSheet_g2 = table2cell(markerSheet_g2);
    
    % read participant group sheet 
    participantGroupSheet = readtable(groupSheet);
    participantGroupSheet = table2cell(participantGroupSheet);
    pNames = participantGroupSheet(:,1);
    pGroups = participantGroupSheet(:,2);
    
    

%     
%     markerSheet = readtable(sheetName);
%     % transform table to cell for efficient processing 
%     markerSheet = table2cell(markerSheet);    
%     
% %     % create duplicate of event type and latency 
%     event_list_subj         = markerSheet(:,2);
%     eeg_event_list_code     = markerSheet(:,4);
%     event_list_tags         = markerSheet(:,5);
%     
%     % convert all to strings
%     event_list_subj         = cellfun(@num2str,event_list_subj,'un',0);
%     event_list_code         = cellfun(@num2str,eeg_event_list_code,'un',0);
%     event_list_tags         = cellfun(@num2str,event_list_tags,'un',0);
    

end


% this variable is used for storing each of the event marker letters. once
% a letter has been stored (markerName_event_1), same letters that come after it will change the
% data field name as markerName_event2, markerName_event3... etc.)

for pi = 1:length(ALLEEG)
    storeEvents = struct();
    fprintf('\n******CURRENT PARTICIPANT: %s ******\n',ALLEEG(pi).setname); 
    fprintf('\n******PROGRESS %d of %d ******\n',pi,length(ALLEEG));     
    
    
    % get index of participants from the group sheet 
    grIndx = find(strcmp(pNames,ALLEEG(pi).setname));
    % get the group of participant 
    group = pGroups{grIndx};
    
    
    % INITIALIZE THE EPOCHED DATA STRUCTURE
    EEG_epoch(pi).A_subject  = ALLEEG(pi).setname;
    EEG_epoch(pi).A_group    = group;
    EEG_epoch(pi).A_srate    = ALLEEG(pi).srate;
    EEG_epoch(pi).A_chanlocs = ALLEEG(pi).chanlocs;
    samplingrate             = ALLEEG(pi).srate;
    
   
    
    % get event sheet according to group
    if group == 1
        markerSheet = markerSheet_g1;
    else
        markerSheet = markerSheet_g2;
    end
    
    
    % this variable is used for storing each of the event marker letters. once
    % a letter has been stored (markerName_event_1), same letters that come after it will change the
    % data field name as markerName_event2, markerName_event3... etc.)    
    storeEvents = struct(); 
    storeEvents(1).info = "count";  % how many of this event are there 
    storeEvents(2).info = "detail";  % what is the explanation of this event
    
    % count and loop over all events 
    howManyEvents = length(ALLEEG(pi).urevent);
   
    % initialize code match iteration index 
    matchi = 0;
    for eventi = 1:howManyEvents
        % register previous event for OHH segmentation correction
        if eventi > 1 
            previousEvent = currentEvent; 
        end
        
        
        % a logical variable used for skipping to next markers if there is
        % no valid match
        skipToNextMarker = 0;
        
        % get current event, time point of the event, and its order on the
        % list
        currentEvent = ALLEEG(pi).urevent(eventi).type;
        currentLatency = ALLEEG(pi).urevent(eventi).latency;
        
%         % if there was a bad data removal next to this code, get latency
%         % and duration of boundary
%         if eventi < howManyEvents
%             nextEvent = ALLEEG(pi).urevent(eventi+1).type;
%             if strcmp('boundary',nextEvent)
%                boundaryLatency  =  round(ALLEEG(pi).urevent(eventi+1).latency);
%                boundaryDuration =  ALLEEG(pi).urevent(eventi+1).duration;
%             end
%         end
        % check if this event has the valid event codes (RS232)
        isEvent     = ~isempty(strfind(currentEvent,'Trigger')) && ~isempty(strfind(currentEvent,'RS232'));  %#ok<*STREMP>  
        
         
        % if this is not a viable event, proceed to next event
        if ~isEvent
            disp('skipping, not an event')
            disp(currentEvent)
            continue
        else
            % CHECK IF EVENT EXISTS IN EXTERNAL SHEET 
            % extract the letter of event        
            apostropheIndex     = strfind(currentEvent,''''); %  find the first ' in event name and get the letter after it because events are named = 'RS232 Trigger: 98('b')'
            currentEvent        = currentEvent(apostropheIndex(1)+1);
            currentEvent        = lower( currentEvent ); 

            % check if this current event is also included in external events sheet.  
            isEvent2    = ~isempty(find(strcmp(markerSheet(:,1),currentEvent)));
            
            if ~isEvent2
                % skip if does not exists 
                disp('event did not match with the sheet')
                disp(currentEvent)
                continue
            end
            
        end
        

%         for matchi = 1:length(markerSheet)
        while matchi < length(markerSheet)
            
            
            % decide if you should move another row in the external event
            % sheet. Some events are repetitive some are not. We shouldn't
            % move forward in repetitive events like 'OHH'
            isRepetitiveEvent = strcmp('i',currentEvent) || strcmp('k',currentEvent) || strcmp('l',currentEvent) || strcmp('u',currentEvent) || strcmp('v',currentEvent) || strcmp('x',currentEvent);
            if isRepetitiveEvent && strcmp(previousEvent,currentEvent)
                % do not move one row below if this is OHH marker

            else
                % move one row below if this is another marker
                % (Restingstate, radio_ads etc.)
                % increase iteration index when there is a match 
                matchi = matchi + 1; 
            end
            
            
            %get letter code from external sheet 
            markerIdentifier = markerSheet{matchi,1};
            
            
            % match the current marker with the markers in markerSheet
            if strcmp(currentEvent,markerIdentifier)                

                
                segmentLength = markerSheet{matchi,6} * (ALLEEG(pi).srate);  % multiply with sampling rate to get the time point necessary for epoch
                
%                 % if boundary (data removal) is within the segment duration
%                 if (boundaryLatency - currentLatency) < segmentLength
%                     
%                     if (boundaryLatency + boundaryDuration) <= (currentLatency + segmentLength)
%                         % if the whole boundary window is within the segment 
%                         segmentLength = segmentLength - boundaryDuration;
%                     else
%                         % if some of boundary window exceeds the segment 
%                         segmentLength = boundaryLatency - currentLatency;                         
%                     end                        
%                     
%                 end
                
                % get how many epochs there are for this condition, 
                % floor the decimal number (240s segment length, 180s epoch
                % length, 1.33 total epoch are rounded to 1 epoch)
                segmentCount = 1; % there is only one epoch for all events in wotif study 
                
                % get the file name 
                markerDetails       = markerSheet{matchi,3};
                % get the event name
                currentEventName    = markerSheet{matchi,2};
                
                % remove the file extension dot from file name
                dotindx = strfind(markerDetails,'.');                
                if ~isempty(dotindx)
                    markerDetails(dotindx:end) = [];
                else
                    % remove spaces from the details becauase structure
                    % fields do not accept it 
                    markerDetails = regexprep(markerDetails,' ','_');
                end
                
                
                % if this marker appears more than once, start to name the
                % data field as markerName_event2, markerName_event3 etc.
                if isfield(storeEvents,currentEventName)
                    storeEvents(1).(currentEventName) = storeEvents(1).(currentEventName)+1;
                    storeEvents(2).(currentEventName) = cat(2,storeEvents(2).(currentEventName),{markerDetails});
                else
                    storeEvents(1).(currentEventName) = 1;
                    storeEvents(2).(currentEventName) = {markerDetails}; % what is the event (Loreal, SocialMedia, Neuro Podcast etc.)                     
                end                
                if isempty(markerSheet{matchi,3})
                    % if there is no details as to what this is
                    % only record the event name (e.g. RestingState etc.)
                    conditionName = currentEventName;
                else
                    % type in the marker details for podcast and radio ads 
                    % events (e.g. Radio_Ads2_ToyotA_Radio 
                    conditionName = cat(2,currentEventName,'_',markerDetails); 
                end
                fprintf('\ncondition name: %s\n',conditionName)
                skipToNextMarker = 0;
                
                
                break
            % skip to next event if (i) no more markers to check remain
            elseif matchi==length(markerSheet)
                skipToNextMarker = 1;
            end

        end
        
        % skip to next marker if there was no match in markers 
        if skipToNextMarker
            disp('skipping, no match was found')
            disp(currentEvent)
            disp(skipToNextMarker)
            continue
        end
        
        
        currentData = [];
        preStimWindow = floor(ALLEEG(pi).srate / 4); % get a window of 250 ms 
        % initiate segmentation for the current marker 
        for epochi = 1:segmentCount
            timeInterval = currentLatency+(((segmentLength*(epochi-1))-preStimWindow):((segmentLength*epochi)-1)); % get the time interval for the epoch 

            % print marker onset and time window to command window
            if max(timeInterval) > size(ALLEEG(pi).data,2)

                % abort segmentation if epochs are not bound within limits
                fprintf('\nepoch limit exceeds data length, aborting this segmentation!\n');
                break

            else
                %continue segmentation
                fprintf('\ncurrent marker: %s \n',conditionName);
                fprintf('current latency: %d \n',currentLatency);            
                fprintf('current time interval: %d to %d\n',min(timeInterval),max(timeInterval));

                % concatenate epochs on 3rd dimension 
                currentData = cat(3,ALLEEG(pi).data(:,timeInterval),currentData);        
            end

        end        

        if isfield(EEG_epoch,conditionName)
            % if this condition had a previously registered data,
            % concatenate the new one
            EEG_epoch(pi).(conditionName)=cat(3,EEG_epoch(pi).(conditionName),currentData);            
        else
            % if there is no prior registry, create this condition
            EEG_epoch(pi).(conditionName)= currentData;
        end

    end
end
EEG_epoch = orderfields(EEG_epoch);


% order field names for the 
EEG_epoch = orderfields(EEG_epoch);

% change dir to save path
cd(savePath);

% name of the segmented dataset variable as a file
segmentedData = 'seg_data.mat';
%% save EEG_psd_data 
save(segmentedData,'EEG_epoch','-v7.3');

% %% remove events below, most participants do not have these. 
% EEG_epoch = rmfield(EEG_epoch, 'write_audio_trigger_control_event_7');
% EEG_epoch = rmfield(EEG_epoch, 'podcast_1_pre_roll_trigger_event_2');


