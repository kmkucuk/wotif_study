function [EEG_psd_second] = func_psdSeconds(EEG_epoch,savePath,baseline)
    % baseline = 1 or 0, was there a baseline that should be omitted from PSD transformations?
    
    cd(savePath)
    
    %% second by second PSD freq_specific 
    EEG_psd_second = struct();

    fnames = fieldnames(EEG_epoch);
    % find subject related non-data channel indices 
    nonDataFields = regexp(fnames,'A_');
    nonDataIndx = find([nonDataFields{:}]==1);
    nonDataIndx = nonDataIndx(end);
    nonDataIndx = nonDataIndx+1; % data starts 1 field after the non-data fields.
    % psd parameters
    srate = 256;
    freqRes = .5;
    nfft = srate/freqRes;
    
    for pi =1:length(EEG_epoch)


        EEG_psd_second(pi).A_subject    = EEG_epoch(pi).A_subject;
        EEG_psd_second(pi).A_group      = EEG_epoch(pi).A_group;
        EEG_psd_second(pi).A_srate      = EEG_epoch(pi).A_srate;
        EEG_psd_second(pi).A_chanlocs   = EEG_epoch(pi).A_chanlocs;            
%         EEG_psd_second(pi).A_interpolatedChannels = EEG_epoch(pi).A_interpolatedChannels;
        
        
        fprintf('\n******PROCESSED PARTICIPANT: %s ******\n',EEG_epoch(pi).A_subject); 

        %% start to loop from data fields (nonDataIndx) (first nonDataIndx are, subid, channels, group,srate etc)
        for fi = nonDataIndx:length(fnames)
%                 fi = 12
                % get data ( dims(chan,time,trial) )
                data = EEG_epoch(pi).(fnames{fi});

                if isempty(data)
                    % if participant has no valid data for this field,
                    % skip to next field.
                    continue
                end

                fprintf('\nCondition: %s \n',fnames{fi}); 
%                 disp(nonDataIndx)
                %% if there are more than 1 trials
                if size(data,3)> 1
                    if baseline
                        % remove baseline period
                        data = data(:,65:end,:);
                    end
                    % reshape data into chan x time matrix
                    data = reshape(data,[size(data,1),size(data,2)*size(data,3)]);

                end
                
                if baseline
                    % remove baseline period
                    data = data(:,65:end);
                end 
                % change dimensions for pwelch ( dims(time,chan) )
                data = permute(data,[2 1]);

                % how many seconds there are in this trial
                countSeconds = floor(size(data,1)/256);     

                % initialize second by second data
                psd_second_data = [];


                %% loop over seconds in a trial

                for secondIndex = 1:countSeconds

                    %create a time index for this second
                    thisSecond = ((secondIndex-1)*256)+1 : (secondIndex * 256);

                    % get data of a second in this trial                        
                    second_data = data(thisSecond,:);

                    %% PSD %%
                    % create welch parameters
                    window = 64; % calculate psd in 250 ms windows
                    overlap = ceil(window*.2); %  20% overlap

                    % calculate psd 
                    [welch_data, freqs]= pwelch(second_data,window,overlap,nfft,srate);                    
                    psd_second_data=cat(3,psd_second_data,welch_data);

                    % when all seconds of this trial is finished
                    if secondIndex == countSeconds
                        maxFreq = find(freqs==48);

                        % remove freqs higher than 48
                        psd_second_data(maxFreq+1:end,:,:) = [];
                        freqs(maxFreq+1:end) = [];

                        % register second by second data
                        % dim(freq,chan,sec) to the unique field
                        EEG_psd_second(pi).(fnames{fi}) = psd_second_data;
                    end



                end

        % get log of psd data
        psd_second_data = 10*log10(psd_second_data);

        % register data 
        EEG_psd_second(pi).(fnames{fi}) = psd_second_data;

        end     
        %(A_ was written to place frequency field at the beginning of structure fields after ordering them)
        EEG_psd_second(pi).A_frequencies = freqs; 

    end




    % order structure field names 
    EEG_psd_second = orderfields(EEG_psd_second);

    psdSecondsDataFile = 'psd_data_seconds_segmented_newProcessed_intp_4.mat';
    %% save EEG_psd_data 
    save(psdSecondsDataFile,'EEG_psd_second')
end