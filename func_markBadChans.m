function artifactStructure = func_markBadChans(EEG_epoch,savePath)


    cd(savePath);
    %%%%%%%%%%%%%%%%%%%%%%%%%
    %% load segmented data %% 
    %%%%%%%%%%%%%%%%%%%%%%%%%

    fnames = fieldnames(EEG_epoch);
    % find subject related non-data channel indices 
    nonDataFields = regexp(fnames,'A_');
    nonDataIndx = find([nonDataFields{:}]==1);
    nonDataIndx = nonDataIndx(end);
    nonDataIndx = nonDataIndx+1; % data starts 1 field after the non-data fields.

    % initialize artifact structure. 
    artifactStructure                   = struct();
    artifactStructure.A_subject         = [];
    artifactStructure.bad_channels      = [];
    artifactStructure.bad_channels_text = [];
    artifactStructure.exclude           = [];
    artifactStructure.description       = [];

    exitmarker = 0;
    
    
    % second round of rejection for wotif study 
    allIndices = 1:length(EEG_epoch);    
    % completed indices 
    index = [1 2 3 4 9 11 12 28 52];
    % remaining indices 
    allIndices(index) = [];
    
    
    for pi = allIndices

        fprintf('\nParticipant: %s \n',EEG_epoch(pi).A_subject);         
    %         fprintf('\nCondition: %s \n',plotFields{4});

        % initialize concatenated data
        grand_data = [];

        for fieldsi = nonDataIndx:length(fnames)
            data = EEG_epoch(pi).(fnames{fieldsi});  % EEG.data; 
            if isempty(data)

                continue

            else
                
                %% if there are more than 1 trials
                if size(data,3)> 1

                    % reshape data into chan x time matrix
                    data = reshape(data,[size(data,1),size(data,2)*size(data,3)]);

                end

                grand_data = cat(2,grand_data,data);

            end
        end

        eegplot(grand_data,'eloc_file',EEG_epoch(pi).A_chanlocs);

        hold on 
        yLims = get(gca,'ylim');
        % plot channel name
        text([0 0],[yLims(2) yLims(2)]-11,EEG_epoch(pi).A_subject,'Color','k','FontSize',9,'FontWeight','bold','HorizontalAlignment','center')        

        % Below code waits until you finish going over the data
        % whenever you finish, type in something EXCEPT 'N'
        % 'N' terminates the code. 
        reply=input('Proceed to register channels? y/n','s');
        
        
        if reply=='n'
            exitmarker=1;
            close('all');
            save('badChannelInfo_2.mat','artifactStructure');
            break   
        else
            clf;
            close('all');
        end        
        %% create a dialog box for entering bad channel information %% 
        % title of the box
        inputDialogText = [EEG_epoch(pi).A_subject];

        % headers of the box
        prompt = {'Bad Channels (e.g. Fz,F3)', 'Exclude Entirely (0=no,1=yes)', 'Description'};
        %default values of the inputs
        defaults = {'', '0', ''};
        % create box
        answer = inputdlg(prompt, inputDialogText, 2, defaults);
        % get answers
        [badChans, exclude, description] = deal(answer{:}); % all input variables are strings   
        % convert string to numeric (exclusion variable, 1= exclude, 0 =
        % don't)
        exclude = str2num(exclude);

        % create cell array from all bad chans 
        % • badChans = 'F3,'O1'
        % • badChans = {'F3','O1'};
        badChans = strsplit(badChans,',');

        % get all channel labels of this participant
        currentChanLabels   = {EEG_epoch(pi).A_chanlocs.labels};
        % match bad channels with all channels
        matchChans          = ismember(currentChanLabels,badChans);
        % get index of bad channels 
        badChanIndx         = find(matchChans);      

        artifactStructure(pi).A_subject         = EEG_epoch(pi).A_subject;
        artifactStructure(pi).bad_channels      = badChanIndx;
        artifactStructure(pi).bad_channels_text = badChans;
        artifactStructure(pi).exclude           = exclude;
        artifactStructure(pi).description       = description;

        save('badChannelInfo_2.mat','artifactStructure');

    end


