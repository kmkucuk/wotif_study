function [ALLEEG] = func_loadData(getPath,savePath)

% getPath = directory where the raw data files are located
% % savePath = directory where you'll save output files
% savePath = ['E:\Backups\All Files\Genel\Is\2023\Tribikram\study Validation and Mood\processed_sets'];
% getPath = ['E:\Backups\All Files\Genel\Is\2023\Tribikram\study Validation and Mood\raw_sets'];
%     clear all % clear all variables
cd('E:\Backups\Matlab Directory\eeglab')
eeglab % run eeglab
filePath=getPath; % specify dir of data files 
cd(filePath); % change dir 
fileList = ls; % create a list of each dataset name in the dir
fileList(1:2,:)=[]; % remove the first two rows because they  consist of dots 

ALLEEG = struct();  
EEG_epoch = struct(); % initialize epoched data structre
lengthTotal = size(fileList,1); % get total number of datasets
CURRENTSET = 0;

for k = 1:size(fileList,1)
    
    
    %% get data file name
    datasetName = fileList(k,:); % get dataset name from the file list 
    cd(getPath);
    %% get the directory of dataset
    filedir = [filePath,'\',datasetName]; % get the current dataset name 
    EEG = pop_loadset(filedir);
%         EEG = pop_biosig(filedir); % load .edf file 

    %% change data file name for eeglab sets
    % remove by underscores
    undScorInd = strfind(datasetName,'_');
    datasetName(undScorInd(2):end) = [];
    
    % remove by file extensions (by dot index)
%     dotIndex = strfind(datasetName,'.'); %  find the '.' in file name and remove that part for dataset name registry in eeglab
%     datasetName(dotIndex:end)=[]; % remove .edf from set name
    disp(datasetName)

    % register set name
    EEG.setname = datasetName; % change dataset name     
    eeglabSetName = datasetName;
    EEG = eeg_checkset( EEG ); % check consistency 


    % import channel location info !!!!!!!!!(CHANGE DIRECTORY BELOW ACCORDING TO YOURS)!!!!!!!
    EEG = pop_chanedit(EEG, 'lookup','E:\Backups\EEGLAB14_2b\plugins\dipfit2.2\standard_BEM\elec\standard_1020.elc');
    EEG = eeg_checkset( EEG );

    % if there is no channel info, move on to the next participant.
    if isempty(EEG.chanlocs)
        disp('*** skipping this participant ***');
        continue
    end
    CURRENTSET = CURRENTSET +1; 
    %re-reference
    EEG = pop_reref( EEG, {'A1','A2'} );
    EEG = eeg_checkset( EEG );


    % pass band filter .3 to 48
    EEG = pop_eegfiltnew(EEG, 0.3,48);
    EEG = eeg_checkset( EEG );   

    fprintf('\n******CURRENT PARTICIPANT: %s ******\n',eeglabSetName); 
    fprintf('\n*PROGRESS %d of %d *\n',k,lengthTotal); 


    % run ica (disabled)
%     EEG = pop_runica( EEG, 'icatype', 'runica' );
%     EEG = eeg_checkset( EEG );    

    EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion','off','ChannelCriterion','off','LineNoiseCriterion','off','Highpass','off','BurstCriterion',5,'WindowCriterion','off','BurstRejection','off','Distance','Euclidian');
    eeglabSetName = [eeglabSetName,'_auto_artifact']; %#ok<AGROW>

    % change dir for data save
%         artfDataDir = savePath; % directory that you want to save eeglab data files 
    cd(savePath);    

    % save artifact free dataset 
    ALLEEG = pop_newset(ALLEEG, EEG, CURRENTSET,'setname', datasetName,'savenew',eeglabSetName); 
   

end

assignin('base','ALLEEG',ALLEEG)
% redraw EEGLAB GUI
eeglab redraw
    
    
% end