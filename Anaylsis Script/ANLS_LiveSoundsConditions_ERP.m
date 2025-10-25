% % LIVE SOUNS TASK CONDITIONS DATA ANALYSIS 
% -------------------------------------------
% The code performs the pre-processing and data analysis pipeline for 
% the EEG data collected during different live sounds conditions. In first 
% condition the participant listened to live sounds created randomly using 
% a sticks by the experimenter. In the second condition, the recording of
% the first sounds were played back and the in the third condition the the
% playback of the sounds were mixed with a soundscape scene. 
%
% EEG was recorded with Mentalab Amplifier (32 Channel)
% 
% What the script does:
% 1. Loads the audio files and detects the onsets 
% 2. Loads each condition EEG (.set) file and:
% 3. Selects the EEG segment when the audio happended 
% 3. Pre-Process the Data
%        - Low-pass and high-pass filtering 
%        - Epoch the data based on onset events detected from the audio
%        - Remove artifactual epochs
%        - Baseline correction
% 3. Compute ERP for each sound file and plots them 
%
% Pre-requisits:
% - Assumes the data is in .set format 
% - Requires following functions to run: plotStyles, onset_detect_audio. 
% 
% Author:   Abin Jacob 
%           Carl von Ossietzky Universität Oldenburg
%           abin.jacob@uni-oldenburg.de
% Date  : 23/10/2025

clear all; clc; close all;

% ------------------------------------------------------------------------
% ----------------------------- SCRIPT SETUP -----------------------------

% -- Files & Folders --
% working data folder 
foldername = 'SUB01_24102025';
% audio file to pick audio onsets 
soundscapefile = 'office-01.mp3'; 
% path to directory 
rootpath = '/Users/abinjacob/Documents/02 Translational Psychology/Research Work/nEEGlace/Recordings/Pilots/Soundscape-Project';


% -- Analysis Params --
% high-pass filter 
HP = .1; HPorder = 826;                
% low-pass filter   
LP = 30; LPorder = 776; 
% epoch period 
epoch_start = -0.5; epoch_end = 1;
% reject artefactual epochs 
PRUNE = 4;

% Perform rereferencing?
% Set '0' for No Re-refrencing [OR] '1' to Re-refrencing to CAR [OR] '2' to Re-refrencing to Mastoids
re_ref = 2;

% Save figures to folder?
% Set 'true' to save figures to the folder
save_fig = true;

% ------------------------------------------------------------------------

%% DETECTING AUDIO ONSETS 

% add paths 
cd(fullfile(rootpath, 'Analysis Scripts'));
addpath(fullfile(rootpath, 'Audio Files'));
filepath = fullfile(rootpath, foldername); 
addpath(filepath);


foldersplit = strsplit(foldername, '_');
subjid = foldersplit{1}; 
livesoundsfile = [subjid, '_sticks_sounds_recording.wav'];

% detect onsets from the live sounds 
[y, Fs] = audioread(livesoundsfile);
duration = length(y) / Fs; 
timevec = linspace(0, duration, length(y));
display(['Computing audio onsets for file ', livesoundsfile])
[onsets_live, info_live] = onset_detect_audio(livesoundsfile);
% removing the first two onset as it is experiment begin beep tone 
onsets_live(1:2) = []; 
display([num2str(numel(onsets_live)), ' onsets detected'])

% detect onsets from the soundscape sounds 
[x, Fs2] = audioread(soundscapefile);
duration2 = length(x) / Fs2; 
timevec2 = linspace(0, duration2, length(x));
display(['Computing audio onsets for file ', soundscapefile])
[onsets_soundscape, info_soundscape] = onset_detect_audio(soundscapefile);
% removing the first two onset as it is experiment begin beep tone 
onsets_soundscape(1:2) = []; 
display([num2str(numel(onsets_soundscape)), ' onsets detected'])

% import plot styles
% ![ Important: requires the custome function 'plotStyles' ]
s = plotStyles();
clr = [s.color1; s.color2];

% plot onsets detected 
display('Plotting.....')
figure('Units', 'centimeters', 'Position', s.figsize2);
% live sounds onsets 
subplot(2,1,1)
hold on
plot(timevec, y, 'k')
% add onset markers
for k = 1:numel(onsets_live)
    xline(onsets_live(k), 'r--', 'LineWidth', 1);
end
xlabel('Time (s)');
ylabel('Amplitude');
title(['Onsets detected from ' livesoundsfile], 'Interpreter','none');
set(gca, 'FontSize', s.plt_fontsize);
% soundscape onsets 
subplot(2,1,2)
hold on
plot(timevec2, x, 'k')
% add onset markers
for k = 1:numel(onsets_soundscape)
    xline(onsets_soundscape(k), 'b--', 'LineWidth', 1);
end
xlabel('Time (s)');
ylabel('Amplitude');
title(['Onsets detected from ' soundscapefile], 'Interpreter','none');
set(gca, 'FontSize', s.plt_fontsize);


%% ANALYSING EEG FOR DIFFERENT CONDITIONS 

% eeg file names
eegfiles = {'_LiveSounds_Record', '_LiveSounds_Playback', '_LiveSounds_PlaybackNoise'};
eegdata = [];
events  = {'AudioOnset'};

% open EEGLAB
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

% -- Setting up Plots --
% create figure folder if doesn't exist
plotfolder = fullfile(filepath,'Figures');
if ~exist(plotfolder, 'dir')
    mkdir(plotfolder);
    display('New Folder Created for Saving Plots')
end
% import plot styles
% ![ Important: requires the custom function 'plotStyles' ]
s = plotStyles();
clr = ['r', 'b', 'm', 'k'];
if re_ref == 2
    channels2plot = [8 4 9 13];
else 
    channels2plot = [8 4 9 14];
end 

for fidx = 1:numel(eegfiles)
    eegfile = [subjid ,eegfiles{fidx}, '.set']; 
    display(['Loading EEG file ', eegfile])
    EEG = pop_loadset('filename', eegfile, 'filepath', filepath);
    
    % -- EEG Preprocessing 
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
    % select the EEG segment during the audio 
    startEventIdx = find(strcmp({EEG.event.type}, 'start'));
    st = EEG.event(startEventIdx).latency;
    ed = st + round(duration * EEG.srate) - 1;
    EEG = pop_select( EEG, 'point',[st ed] ); 
    display([num2str(duration), 'min of EEG segment relative to audio selected'])

    % -- EEG Epocihing
    % preparing onsets detected from live sounds audio
    onset_samples = round(onsets_live * EEG.srate);
    onset_samples = onset_samples';
    % create new events 
    new_events = struct( ...
        'type', repmat({'AudioOnset'}, 1, length(onset_samples)), ...
        'latency', num2cell(onset_samples), ...
        'duration', num2cell(zeros(1,length(onset_samples))) ... 
    );
    % replace EEG events with new onset events
    EEG.event = new_events;
    % events with out-of-bounds latencies and removing from events and onsets
    badevents = find([EEG.event.latency] < (abs(epoch_start) * EEG.srate) | [EEG.event.latency] > EEG.pnts); 
    if badevents 
        onsets(badevents) = [];
    end
    EEG = eeg_checkset(EEG, 'eventconsistency');
    % epoching 
    EEG = pop_epoch(EEG, events, [epoch_start epoch_end], 'newname', [subjid ,eegfiles{fidx}],'epochinfo', 'yes');
    % remove artifact epochs
    EEG = pop_jointprob(EEG, 1, [1:EEG.nbchan], PRUNE, PRUNE, 0, 1, 0);
    EEG = eeg_checkset(EEG);
    % baseline correction
    baseline = [epoch_start*1000 0];  
    EEG = pop_rmbase(EEG, baseline);
    EEG = eeg_checkset(EEG);
    % store eeg data 
    eegdata = cat(3, eegdata, EEG.data);

    % -- Plotting ERPs
    if fidx == 1
        figure('Units', 'centimeters', 'Position', s.figsize); 
        hold on
    end 
    plot(EEG.times, mean(mean( EEG.data(channels2plot,:,:) ,3),1), 'Color', clr(fidx), 'LineWidth', s.plt_linewidth)
end 
% plotting mean of everything 
plot(EEG.times, mean(mean( eegdata(channels2plot,:,:) ,3),1), 'Color', clr(fidx+1), 'LineWidth', s.plt_linewidth)
legend({'Live Sounds', 'Playback', 'PlaybackNoise', 'Average'});
xlabel('Time (ms)');
ylabel('Amplitude (µV)');
title(['ERPs - ' subjid]);
set(gca, 'FontSize', s.plt_fontsize);


% save plot
if save_fig
    plotname = [subjid, '_livesoundsERP'];
    plotsave = fullfile(plotfolder, [plotname, '.png']);
    saveas(gcf, plotsave)
end 

%% plot topographies 

peaks2plot = [152 188 260 388];
pop_topoplot(EEG, 1, peaks2plot, 'PlaybackNoise', [1 length(peaks2plot)] ,0, 'electrodes', 'on', 'chaninfo', EEG.chaninfo); 

