    
function [EEG_epoch] = func_inputChanloc(EEG_epoch,savePath)
    %% input channel info to EEG_epoch %% 
    cd('E:\Backups\All Files\Genel\Is\2023\Tribikram\study Validation and Mood')
    % load channel info file
    load('channelInfo.mat')

    %% add reference electrodes to channel info file
    % for k = 1:length(chanInfoFile)
    %     chanInfoFile(k).ref = EEG_epoch(1).A_chanlocs(1).ref;
    %     
    % end
    % save('channelInfo.mat','chanInfoFile')


    allChanLabels = {chanInfoFile.labels};

    for k = 1:length(EEG_epoch)

        currentChans = EEG_epoch(k).A_chanlocs;
        currentChans = {currentChans.labels};

        matchChans  = ismember(allChanLabels,currentChans);
        chanIndx    = find(matchChans);
        EEG_epoch(k).A_chanlocs    = chanInfoFile(chanIndx);

    end

    cd(savePath)
    save('seg_data.mat','EEG_epoch','-v7.3')
end