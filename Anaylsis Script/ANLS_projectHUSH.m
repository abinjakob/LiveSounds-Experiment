% % SUBVOCAL SPEECH TASK DATA ANALYSIS 
% -------------------------------------
% The code performs the pre-processing and data analysis pipeline for 
% the Subvocal Speech sEMG data collected with Mentalab Amplifier (32 Channel)
% and plots relevant plots and save it to folder.
% 
% What the script does:
% 1. Loads the sEMG (.set) file
% 2. Pre-Process the Data
%        - Low-pass and high-pass filtering 
%        - Epoch the data based on events and epoch periods
%        - Remove artifactual epochs
%        - Baseline correction
% 3. Compute RMS and plots the average of the envelope 
%
% Pre-requisits:
% - Assumes the data is in .set format (Use PROC_convertXDF_and_mapOnsets.m 
%   script before running this script)
% - Requires following functions to run: plotStyles
% 
% Author:   Abin Jacob 
%           Carl von Ossietzky Universität Oldenburg
%           abin.jacob@uni-oldenburg.de
% Date  : 01/10/2025

clear all; clc; close all;

% ------------------------------------------------------------------------
% ----------------------------- SCRIPT SETUP -----------------------------

% -- Files & Folders --

% folder with EEG files 
foldername = 'SUB01_24102025';
% XDF file to load for analysis
filename   = 'SUB01_Subvocal_Silent.set';    

% path to the folder
rootpath = '/Users/abinjacob/Documents/02 Translational Psychology/Research Work/nEEGlace/Recordings/Pilots/Soundscape-Project';

% -- Analysis Params --

% event markers 
% high-pass filter 
HP = 20; HPorder = 826;                
% low-pass filter  
LP = 100; LPorder = 776; 
% epoch period 
epoch_start = -1.5; epoch_end = 2;
% reject artefactual epochs 
PRUNE = 4;

% Perform rereferencing?
% Set '0' for No Re-refrencing [OR] '1' to Re-refrencing to CAR [OR] '2' to Re-refrencing to Mastoids
re_ref = 0;

% Save figures to folder?
% Set 'true' to save figures to the folder
save_fig = true;

% ------------------------------------------------------------------------

%% data processing 

namesplit = strsplit(filename, '_');
if contains(filename, 'Subvocal')
    events = {'Pa'};
    plotfile = [namesplit{2},'-',strrep(namesplit{3}, '.set', '')];
else
    events = {'Press'};
    plotfile = namesplit{2};
end

% -- Load files to EEGLAB --
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
filepath = fullfile(rootpath,foldername);
EEG = pop_loadset('filename', filename, 'filepath', filepath);
% set current directory
cd(fullfile(rootpath, 'Analysis Scripts'));
display('Directory Changed')

% filtering
disp(['Data Filtering: LP = ', num2str(LP), ' HP = ', num2str(HP)])
EEG = pop_firws(EEG, 'fcutoff', LP, 'ftype', 'lowpass', 'wtype', 'hamming', 'forder', LPorder);
EEG = pop_firws(EEG, 'fcutoff', HP, 'ftype', 'highpass', 'wtype', 'hamming', 'forder', HPorder);
% re-referencing
if re_ref == 1
    % re-referencing to CAR
    EEG = pop_reref(EEG, [], 'refstate',0);
    display('Re-referenced to CAR')
elseif re_ref == 2
    % re-referencing to mastoids
    EEG = pop_reref( EEG, [11 15] );
    display('Re-referenced to Mastoids')
end 


% epoching 
EEG = pop_epoch(EEG, events, [epoch_start epoch_end], 'newname', 'Oddball_epoched','epochinfo', 'yes');
% remove artifact epochs
EEG = pop_jointprob(EEG, 1, [1:EEG.nbchan], PRUNE, PRUNE, 0, 1, 0);
EEG = eeg_checkset(EEG);
% baseline correction
baseline = [epoch_start*1000 0];  
EEG = pop_rmbase(EEG, baseline);
EEG = eeg_checkset(EEG);

% -- Setting up Plots --
% set plot file names
% create figure folder if doesn't exist
plotfolder = fullfile(filepath,'Figures');
if ~exist(plotfolder, 'dir')
    mkdir(plotfolder);
    display('New Folder Created for Saving Plots')
end
% import plot styles
% ![ Important: requires the custome function 'plotStyles' ]
s = plotStyles();
clr = [s.color1; s.color2];


%% plotting envelopes 

% calculating RMS 
data = EEG.data; 
window = round(0.05*EEG.srate); % 50 ms RMS window
emg_env = movmean(abs(data), window, 2); 
% choosing data only from ear electrodes 
chans = [11 15];

% plotting envelope
figure('Units', 'centimeters', 'Position', s.figsize);
hold on;
plot(EEG.times, squeeze(mean(emg_env(chans(1),:,:),3)), 'Color', 'r','LineWidth',s.plt_linewidth);
plot(EEG.times, squeeze(mean(emg_env(chans(2),:,:),3)), 'Color', 'b','LineWidth',s.plt_linewidth);
plot(EEG.times, squeeze(mean(mean(emg_env(chans, :, :),3),1)), 'Color', 'k','LineWidth',2);
xlabel('Time (ms)'); ylabel('RMS Amplitude (µV)'); 
legend(EEG.chanlocs(chans(1)).labels, EEG.chanlocs(chans(2)).labels, [EEG.chanlocs(chans(1)).labels, ' & ', EEG.chanlocs(chans(2)).labels, ' average'])
title(['Gestures Envelope for ', plotfile], 'Interpreter', 'none');
set(gca, 'FontSize', s.plt_fontsize);

% save plot
if save_fig
    plotsave = fullfile(plotfolder, [plotfile, '-temporalchannels', '.png']);
    saveas(gcf, plotsave)
end

%%
% plotting topographies with Matlab markers
peaks2plot = [0 180 356 540 1500];
pop_topoplot(EEG, 1, peaks2plot, 'After Gesture', [1 length(peaks2plot)] ,0, 'electrodes', 'on', 'chaninfo', EEG.chaninfo); 


%% plotting all channels together 

% define channel groups
fronto_central_chans    = {'FPz','F3','Fz','F4','FC1','FC2','C3','Cz','C4','FC5', 'FC6',};
ear_electrode_chans     = {'T7','T8'};
temporal_chans          = {'CP5', 'CP6', 'P7','P8','PO7','PO8'};
central_parietal_chans  = {'CP1','CP2'};
parieto_occipital_chans = {'P3','Pz','P4','PO3','POz','PO4','O1','Oz','O2'};
% find channel groups indices
fronto_central = find(ismember({EEG.chanlocs.labels}, fronto_central_chans));
ear_electrode = find(ismember({EEG.chanlocs.labels}, ear_electrode_chans));
temporal = find(ismember({EEG.chanlocs.labels}, temporal_chans));
central_parietal = find(ismember({EEG.chanlocs.labels}, central_parietal_chans));
parieto_occipital = find(ismember({EEG.chanlocs.labels}, parieto_occipital_chans));


% create figure
figure('Units', 'centimeters', 'Position', s.figsize2);
hold on;
% plot each channnel group
for ch = fronto_central
    plot(EEG.times, mean(emg_env(ch,:,:),3), 'Color', 'c', 'LineWidth', s.plt_linewidth);
end
for ch = ear_electrode
    plot(EEG.times, mean(emg_env(ch,:,:),3), 'Color', 'r', 'LineWidth', s.plt_linewidth);
end
for ch = temporal
    plot(EEG.times, mean(emg_env(ch,:,:),3), 'Color', 'm', 'LineWidth', s.plt_linewidth);
end
for ch = central_parietal
    plot(EEG.times, mean(emg_env(ch,:,:),3), 'Color', 'g', 'LineWidth', s.plt_linewidth);
end
for ch = parieto_occipital
    plot(EEG.times, mean(emg_env(ch,:,:),3), 'Color', 'b', 'LineWidth', s.plt_linewidth);
end
% plot grand average
plot(EEG.times, squeeze(mean(mean(emg_env,3),1)), 'k', 'LineWidth', 3); 
xlabel('Time (ms)');
ylabel('RMS Amplitude (µV)');
title(['Gestures Envelope for ', plotfile], 'Interpreter', 'none');
set(gca, 'FontSize', s.plt_fontsize);
legend([fronto_central_chans, ear_electrode_chans, temporal_chans, central_parietal_chans, parieto_occipital_chans], 'Location', 'eastoutside');

% save plot
if save_fig
    plotsave = fullfile(plotfolder, [plotfile, '-allchannels', '.png']);
    saveas(gcf, plotsave)
end

%% plotting different channels 

nCols = ceil(sqrt(size(EEG.data,1)));     
nRows = ceil(size(EEG.data,1) / nCols);    

% plotting pa data 
figure('Units', 'centimeters', 'Position', s.figsize2);
sgtitle(plotfile, 'Interpreter', 'none', 'FontSize', 16, 'FontWeight', 'bold')
for ch = 1:size(EEG.data,1)
    subplot(nRows, nCols, ch);
    plot(EEG.times, mean(emg_env(ch,:,:),3),'LineWidth',s.plt_linewidth); 
    hold on;
    xline(0, '--r', 'LineWidth', 1.5); % vertical line at time 0
    hold off;
    title(EEG.chanlocs(ch).labels)
    xlim([-1500 2000])
    set(gca, 'FontSize', s.plt_fontsize);
end 
subplot(nRows, nCols, ch+1);
plot(EEG.times, squeeze(mean(mean(emg_env,3),1)), 'Color', 'k'); 
hold on;
xline(0, '--r', 'LineWidth', 1.5); % vertical line at time 0
hold off;
title('Average')
xlim([-1500 2000])
set(gca, 'FontSize', s.plt_fontsize);

% save plot
if save_fig
    plotsave = fullfile(plotfolder, [plotfile, '-indchannels', '.png']);
    saveas(gcf, plotsave)
end


%% single trials

figure('Units', 'centimeters', 'Position', s.figsize);
imagesc(EEG.times, 1:size(emg_env,3), squeeze(emg_env(chans(2),:,:))'); 
caxis([0 8]); 
colormap('parula'); colorbar;
xlabel('Time (ms)'); ylabel('Trial'); 
title(['Gestures Envelope Heatmap for ', plotfile], 'Interpreter', 'none');
set(gca, 'FontSize', s.plt_fontsize);

% save plot
if save_fig
    plotsave = fullfile(plotfolder, [plotfile, '-singletrial', '.png']);
    saveas(gcf, plotsave)
end


