function func_cognitiveOverallSheet(EEG_psd_second,savePath)
    cd(savePath)
    % 
    % % loads > EEG_psd_second:  contains data segmented by each second for each event 
    psdSecondsDataFile = 'psd_data_seconds_segmented_newProcessed_intp_4.mat';
    % load(psdSecondsDataFile);  

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

    %sensory 
    cognitiveIndex(8).process = 'sensory';
    cognitiveIndex(8).channels = {'P3', 'Pz', 'P4'};

    %visual
    cognitiveIndex(9).process = 'visual';
    cognitiveIndex(9).channels = {'O1', 'O2'};
    
    % emotional valence
    cognitiveIndex(10).process = 'emotional_valence';
    cognitiveIndex(10).channels = {{'F3','C3'},{'F4','C4'}};    


    %% psd second frequency specific

    freqs = {'delta','theta','alpha','sigma','beta','gamma'};
    ranges = {[0.5, 4.5],[4.5,8.5],[8.5,11.5],[11.5,15.5],[15.5,30],[30,45]};
    freq_ranges = cat(1,freqs,ranges);
    allFreqs = EEG_psd_second(1).A_frequencies;

    fnames = fieldnames(EEG_psd_second);
    % find subject related non-data channel indices 
    nonDataFields = regexp(fnames,'A_');
    nonDataIndx = find([nonDataFields{:}]==1);
    nonDataIndx = nonDataIndx(end);
    nonDataIndx = nonDataIndx+1; % data starts 1 field after the non-data fields.

    cognitiveIndices = {'attitude','retrieval','encoding','engagement','attention','attention2','trust','sensory','visual','emotional_valence'};



    % loop over cognitive indices 
    for cogi = 1:length(cognitiveIndex)

        processName = cognitiveIndex(cogi).process;
        fprintf('\n******PROCESSED COGNITION: %s ******\n',processName); 
        fprintf('PROCESSED PARTICIPANT:\t'); 


        %% loop over data fields (start from 6th field)     
        for fi = nonDataIndx:length(fnames)

            % current field name
            current_field = fnames{fi};         
            % previous field name (reqiured for creating new sheets for
            % each of the different events) 
            previous_field = fnames{fi-1};
            fprintf('\n***Processed Field: %s ***\n',current_field); 


            % new directory for the event
            registeryDirectory = [savePath '\sheets\overall\seconds'];


            % add frequency range name to directory
            registeryDirectory = [registeryDirectory,'\',processName];

            % change directory
           if ~exist(registeryDirectory, 'dir')
               mkdir(registeryDirectory)
            end                
            cd(registeryDirectory)

            % current csv sheet name (subid_freq_eventName)
            current_sheet_name = ['overall_',processName,'_',current_field,'.csv'];

            eventSheet = {};

            % initialize headers for the datasheet
            eventSheet(1,1) = {'subject'};
            eventSheet(1,2) = {'group'};
            % loop over participants 
            sheetIteration = 0;

             for pi = 1:length(EEG_psd_second)

                subject = EEG_psd_second(pi).A_subject;
                group   =  EEG_psd_second(pi).A_group; %EEG_psd_second(pi).A_group;
                channels = {EEG_psd_second(pi).A_chanlocs(:).labels};

    %             fprintf('%s \t',EEG_psd_second(pi).A_subject); 

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
                if isempty(data)
                    % skip if participant does not have valid data this field 
                    continue
                end            
                % add one to the datasheet iteration (it doesn't update when
                % data is skiipp
                sheetIteration = sheetIteration+1;

                % iterate through seconds to get all column header names for
                % this data field (event)
                countSeconds = size(data,3);
                for secondIndx = 1:countSeconds

                    % write per second column headers
                    eventSheet{1,secondIndx+2} = [fnames{fi},'_s',num2str(secondIndx)];

                     % get the mean of this frequency range 
                    theta_data = mean(data(freqIndices{1},:,secondIndx),1);
                    alpha_data = mean(data(freqIndices{2},:,secondIndx),1);
                    beta_data = mean(data(freqIndices{3},:,secondIndx),1);  
                    gamma_data = mean(data(freqIndices{4},:,secondIndx),1);  



                    %% calculate cognitive indices %%


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


                    elseif  strcmp(processName,'engagement')

                        existIndx =  ismember(channels,cogChannels);
                        chanIndx = find(existIndx==1);    

                        % skip to next process if there is no
                        % viable channels to compute                                
                        if isempty(chanIndx)                                    
                            continue                                    
                        end

                        indexInput = mean(beta_data(chanIndx));


                    elseif  strcmp(processName,'attention') ||  strcmp(processName,'attention2')

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
%                         eventSheet{sheetIteration,occupiedHeaders+cogi} = indexInput;       

                    elseif  strcmp(processName,'visual')

                        existIndx =  ismember(channels,cogChannels);
                        chanIndx = find(existIndx==1);

                        % skip to next process if there is no
                        % viable channels to compute                                
                        if isempty(chanIndx)                                    
                            continue                                    
                        end                                

                        % register calculated data to sheet
                        indexInput = mean(alpha_data(chanIndx));
%                         eventSheet{sheetIteration,occupiedHeaders+cogi} = indexInput;     
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

                        end

                    end

                                

                    % register id, event name_no, and index data 
                    eventSheet{sheetIteration+1,1} = subject;
                    eventSheet{sheetIteration+1,2} = group;

                    % write cognitive index data 
                    eventSheet{sheetIteration+1,secondIndx+2} = indexInput;                



                end                


             end

                %% ONCE THE DATA FIELD IS FINISHED, STORE IT IN CSVs %%
                disp(current_sheet_name)
                % check if eventSheet was created and store it
                if exist('eventSheet','var')
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
%                     writecell(eventSheet,current_sheet_name)
                end  

        end



    end
end