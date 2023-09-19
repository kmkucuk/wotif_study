function [EEG_P300] = func_P300_plot(EEG_P300,savePath)


cd(savePath)

% get group indices
groupsIndx = struct();
% initialize group index variable
groupsIndx(1).index =[];
groupsIndx(1).group =[];
groupsIndx(2).index =[];
groupsIndx(2).group =[];


for pi = 1:length(EEG_P300)
    % get group of this participant
    currentGroup = EEG_P300(pi).A_group;
    
    % append participant to the group
    groupsIndx(currentGroup).index = cat(2,groupsIndx(currentGroup).index,pi);
    
    % indicate which group in the structure
    groupsIndx(currentGroup).group = currentGroup;
end



% initialize structure for plotting 

EEG_P300_plot = struct(); 

load('channelInfo.mat') % load chanInfoFile variable into workspace

allChannels = {chanInfoFile.labels};

times = -.250:1/256:.748;

p300_window = findIndices(times, [.300 .400]);


fnames = fieldnames(EEG_P300);
% find subject related non-data channel indices 
nonDataFields = regexp(fnames,'A_');
nonDataIndx = find([nonDataFields{:}]==1);
nonDataIndx = nonDataIndx(end);
nonDataIndx = nonDataIndx+1; % data starts 1 field after the non-data fields.


% loop over groups, each group will be written into different sheets 
for gri = 1:length(groupsIndx)
    
    currentGroupIndx    = groupsIndx(gri).index;
    currentGroup        = groupsIndx(gri).group;
    % register group 
    EEG_P300_plot(gri).A_group      = currentGroup; 
    EEG_P300_plot(gri).A_chanlocs   = chanInfoFile;
    % iteration index for registering each of the markers on a separate row
    % of the table      
    
    fieldIndx = 1; 
    for fi = nonDataIndx:length(fnames)
        % an index variable for writing accurately to headers 
        fieldIndx = fieldIndx +1;
        
        currentField = fnames{fi};
        
        %initialize this field in the structure
        EEG_P300_plot(gri).(currentField) = [];
        
        % loop over channels 
        for chi =  1:length(allChannels)
            currentChannel = allChannels{chi}; 
            
            eventSheet(chi+1,1) = {currentChannel};
            
            channelDataBank = [];
            % loop over participants        
            for pi = currentGroupIndx

                subj_chans = {EEG_P300(pi).A_chanlocs.labels};
                % check if current channel exists in this participant 
                channelIndx = find(strcmp(subj_chans,currentChannel)); 

                % skip to next participant if this one does not have this
                % channel 
                if isempty(channelIndx) || isempty(EEG_P300(pi).(currentField))
                    continue
                end
    
                % get data of this channel 
                chandata = EEG_P300(pi).(currentField)(:,channelIndx);
                
                % store each participant's data into the bank for future
                % averaging
                channelDataBank = [channelDataBank, chandata];


            end
            
            % 
            if isempty(channelDataBank)
                
                channelDataBank = nan(256,1);                                            
                
            end
            
            % get average of this channel across participants 
            averageChannelValue = nanmean(channelDataBank,2); 
            % get standard deviation of this channel across participants 
            averageChannelstd   = round(std(channelDataBank,0,2,'omitnan'),1); 
            
            EEG_P300_plot(gri).(currentField)  = cat(2,EEG_P300_plot(gri).(currentField),averageChannelValue);               
            
        end
    end

    
    
    
    
end


% change dir to save path
cd(savePath);

% name of the segmented dataset variable as a file
segmentedData = 'EEG_P300_plot_data.mat';
%% save EEG_psd_data 
save(segmentedData,'EEG_P300_plot','-v7.3');



frontalChans = {'F3';'Fz';'F4';'C3';'Cz';'C4'};
posteriorChans = {'P3';'PZ';'P4';'O1';'O2'}; 



areas = struct();

areas(1).chans = frontalChans; 
areas(2).chans = posteriorChans;  
areas(1).description = 'anterior';
areas(2).description = 'posterior';

fnames = fieldnames(EEG_P300_plot);
% find subject related non-data channel indices 
nonDataFields = regexp(fnames,'A_');
nonDataIndx = find([nonDataFields{:}]==1);
nonDataIndx = nonDataIndx(end);
nonDataIndx = nonDataIndx+1; % data starts 1 field after the non-data fields.

% assign x axis ticks 
xTICKS = [-.100:.100:.500]; %, 0, .250, .500, .750];
yTICKS = [-6 -3 0 3 6];

p300_window = findIndices(times, [.300 .400]);

% loop over brain areas (anterior, posterior) 
for loci = 1:length(areas)

    % get channels of this area
    currentChans = areas(loci).chans;
    % get channel count
    chanCount = length(currentChans); 
    % get half of channels for subplotting
    halfChanCount = ceil(chanCount/2);

    areaName = areas(loci).description;
    
    registeryPath = savePath; 
    
    registeryPath = [registeryPath,'\',areaName];
    cd(registeryPath);
    

    for fi = nonDataIndx:length(fnames)
            % get current field 
            currentField = fnames{fi};
            
            % create a new figure 
            f = figure('visible','off');
            dontSave = 0;
            for chani = 1:length(currentChans)
                
                % get this channel 
                currentChannel = currentChans{chani};
                
                % get index of this channel 
                channelIndex = find(strcmp(currentChans,currentChannel));

                % get group 1 data
                group1_data = EEG_P300_plot(1).(currentField)(:,channelIndex);
                
                % get group 2 data 
                group2_data = EEG_P300_plot(2).(currentField)(:,channelIndex);
                
                
                
                
                
                
                if isempty(group1_data) || isempty(group2_data) || isnan(group1_data(1)) || isnan(group2_data(1))
                    dontSave = 1;
                    continue
                end
                
                % select the position of this plot 
                subplot(halfChanCount,2,chani);
            
                % assign new Y limits 
                yLims = [-6 6];               
                
                % plot p300 area 
                rectangle('Position',[times(p300_window(1)),(yLims(1)-(abs(diff(yLims))*.02)),abs(diff(times(p300_window))),abs(diff(yLims))],'FaceColor',[.8 .8 .8],'EdgeColor',[.8 .8 .8])

                hold on  
                
                % plot channel name
                text([.05 .05],[yLims(1) yLims(1)]+1,currentChannel,'Color','k','FontSize',9,'FontWeight','bold','HorizontalAlignment','center')
                
                % plot group 1 as black
                plot(times,group1_data,'Color',[0 0 0],'linewidth',1.5)

                % plot group 2 as grey
                plot(times,group2_data,'Color',[.5 .5 .5],'linewidth',1.5)
                
                % plot stimulus inset 
                plot([0 0],get(gca,'ylim'),'k','LineWidth',1)                
                
                
                % get Y limits of the plot 
                ylimit = get(gca,'ylim');
                

                
                % format plot 
                set(gca,'xlim',[-.100 .500],'ylim', [yLims(1) yLims(2)], 'ydir','reverse',... 
                'FontName','Helvetica','FontSize',9,...
                'TickDir','out','linewidth',1.5,'XColor',[0 0 0],'YColor',[0 0 0])
            
                % disable box 
                set(gca,'box','off'); 
                
                set(gca, 'XTick',xTICKS,'YTick',yTICKS);

%                 if chani == halfChanCount * 2
%                     legend('Group 1','Group 2','Location','northeast');  %,'Location','northeastoutside'
%                     legend('boxoff');
%                 end
                
                

            end
            % if data is empty or nan, don't save figure
            if dontSave
                continue
            end
            
            saveas(f,[areaName,'_',currentField,'.tif'])
            
            
    end
    
    
    
    
    
end