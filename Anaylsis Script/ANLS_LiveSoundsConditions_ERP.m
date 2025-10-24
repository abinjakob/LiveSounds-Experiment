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
foldername = 'TestRecording03_23102025';
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

% prepare directory and files
cd(fullfile(rootpath, 'Analysis Scripts'));
foldersplit = strsplit(foldername, '_');
subjid = foldersplit{1}; 
livesoundsfile = [subjid, '_sticks_sounds_recording.wav'];

% detect onsets from the live sounds 
[y, Fs] = audioread(livesoundsfile);
duration = length(y) / Fs; 
timevec = linspace(0, duration, length(y));
display(['Computing audio onsets for file ', livesoundsfile])
[onsets_live, info_live] = onset_detect_audio(fullfile(rootpath, foldername, livesoundsfile));
% removing the first two onset as it is experiment begin beep tone 
onsets_live(1:2) = []; 
display([num2str(numel(onsets_live)), ' onsets detected'])

% detect onsets from the soundscape sounds 
[x, Fs2] = audioread(soundscapefile);
duration2 = length(x) / Fs2; 
timevec2 = linspace(0, duration2, length(x));
display(['Computing audio onsets for file ', soundscapefile])
[onsets_soundscape, info_soundscape] = onset_detect_audio(fullfile(rootpath, 'Audio Files', soundscapefile));
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

% files to load 
eegfiles = {'_LiveSounds_Record.set', '_LiveSounds_Playback.set', '_LiveSounds_PlaybackNoise.set'};

% open EEGLAB
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;




