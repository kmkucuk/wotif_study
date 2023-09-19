% this script does not load any data by itself
% make sure that you enter the correct input variables

% this is especially important for topographic plots/videos.
% make sure that you have channelInfo.mat ready, or as ws variable: chanInfoFile





% load data, preprocess and save sets 

getPath = 'E:\Backups\All Files\Genel\Is\2023\Tribikram\study Wotif\eeglabdeletedsets';
savePath = 'E:\Backups\All Files\Genel\Is\2023\Tribikram\study Wotif\processed_sets';
[ALLEEG] = func_loadData(getPath,savePath);



% segment the data
savePath = 'E:\Backups\All Files\Genel\Is\2023\Tribikram\study Wotif\data_output';
markerPath = 'E:\Backups\All Files\Genel\Is\2023\Tribikram\study Wotif';
sheetName = 'events_group'; % function will add the group number and .xlsx after (e.g. events_group1.xlsx)
groupSheet = 'participant_groups.xlsx';
[EEG_epoch] = func_segmentation_sheet_group(ALLEEG,savePath,markerPath,sheetName,groupSheet);

% 
% % input the channel spatial locations to datasets
% savePath = 'E:\Backups\All Files\Genel\Is\2023\Tribikram\study Wotif\data_output';
% [EEG_epoch] = func_inputChanloc(EEG_epoch,savePath);


% mark bad channels manually 
savePath = 'E:\Backups\All Files\Genel\Is\2023\Tribikram\study Wotif\data_output';
artifactStructure = func_markBadChans(EEG_epoch,savePath);




disp('interpolation started')
% interpolate bad channels and exclude high noise participants
studyPath = 'E:\Backups\All Files\Genel\Is\2023\Tribikram\study Wotif';
cd(studyPath)
% matlab variable with channels to interpolate 
load('badChannelInfo_alln.mat')
% ALLEEG template created by loading sets via eeglab 
load('all_eeg_template.mat')

savePath = 'E:\Backups\All Files\Genel\Is\2023\Tribikram\study Wotif\data_output';
cd(savePath)
[EEG_epoch] = func_interpolate(EEG_epoch,ALLEEG,artifactStructure,savePath);



fnames = fieldnames(EEG_epoch);
% FILTER 0.5 to 10 Hz before P300 (wotif study) 
for fi = 6:length(fnames)
    dataname = fnames{fi};
    if fi == 6 
        EEG_epoch2 = filtering_mert(EEG_epoch, 1:17,dataname,'bp', [0.5 10], 256,1,dataname);
    else
        EEG_epoch2 = filtering_mert(EEG_epoch2, 1:17,dataname,'bp', [0.5 10], 256,1,dataname);
    end
end
[EEG_epoch2.A_filterProperties] = EEG_epoch2.filterProperties; EEG_epoch2 = orderfields(EEG_epoch2,[1:40,42,41:41]); EEG_epoch2 = rmfield(EEG_epoch2,'filterProperties');
EEG_epoch2 = orderfields(EEG_epoch2);


disp('P300 sheet started')
savePath = 'E:\Backups\All Files\Genel\Is\2023\Tribikram\study Wotif\data_output';
[EEG_P300] = func_P300_sheet(EEG_epoch2,savePath);




disp('P300 plots started')
savePath = 'E:\Backups\All Files\Genel\Is\2023\Tribikram\study Wotif\figures\p300';
[EEG_P300] = func_P300_plot(EEG_P300,savePath);



disp('psd transform started')
% transform data into power spectral density
savePath = 'E:\Backups\All Files\Genel\Is\2023\Tribikram\study Wotif\data_output';
baseline = 1;
[EEG_psd_second] = func_psdSeconds(EEG_epoch,savePath,baseline);



disp('psd to sheets started')
% write psd into second by second excel sheets 
savePath = 'E:\Backups\All Files\Genel\Is\2023\Tribikram\study Wotif\data_output';
func_psdSecondsSheets(EEG_psd_second,savePath)



disp('cognitive index measures of psd data started')
% write cognitive index of psd data in seconds into sheets 
savePath = 'E:\Backups\All Files\Genel\Is\2023\Tribikram\study Wotif\data_output';
func_cognitiveSecondsSheet(EEG_psd_second,savePath)



disp('Averaged cognitive index measures of psd data started')
% write AVERAGED cognitive index of psd data into sheets 
savePath = 'E:\Backups\All Files\Genel\Is\2023\Tribikram\study Wotif\data_output';
func_cognitiveOverallSheet(EEG_psd_second,savePath)




disp('toporaphic video started')
% create topographic videos from psd data 
savePath = 'E:\Backups\All Files\Genel\Is\2023\Tribikram\study Wotif\figures';
[EEG_topo_video] = func_topogVideo(EEG_psd_second,savePath);




disp('toporaphic plots of psd data started')
% create topographic plots from psd data 
figureSavePath= 'E:\Backups\All Files\Genel\Is\2023\Tribikram\study Wotif\figures';
savePath = 'E:\Backups\All Files\Genel\Is\2023\Tribikram\study Wotif\data_output';
cd('E:\Backups\All Files\Genel\Is\2023\Tribikram\study Wotif')
load('chaninfo_18.mat')
chanInfoFile = chaninfo_18;
[EEG_topo_avg_freq] = func_topoPlotFreq(EEG_psd_second,savePath,figureSavePath,chaninfo_18);




disp('toporaphic plots of mv data started')
% create topographic plots from mv data 
figureSavePath = 'E:\Backups\All Files\Genel\Is\2023\Tribikram\study Wotif\figures';
savePath = 'E:\Backups\All Files\Genel\Is\2023\Tribikram\study Wotif\data_output';
cd('E:\Backups\All Files\Genel\Is\2023\Tribikram\study Wotif')
load('chaninfo_18.mat')
chanInfoFile = chaninfo_18;
[EEG_topo_avg_mv] = func_topoPlotMv(EEG_epoch,savePath,figureSavePath,chaninfo_18); 


