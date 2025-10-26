
clear; clc; close all;

% audio file to pick audio onsets 
audiofile = 'SUB01_sticks_sounds_recording.wav';
foldername = 'TestRecording03_23102025';

% path to directory 
rootpath = '/Users/abinjacob/Documents/02 Translational Psychology/Research Work/nEEGlace/Recordings/Pilots/Soundscape-Project';

% add paths 
cd(fullfile(rootpath, 'Analysis Scripts'));
addpath(fullfile(rootpath, foldername));

% audio file  
[y, Fs] = audioread(audiofile);
duration = length(y) / Fs; 
timevec = linspace(0, duration, length(y));


% detect onsets
display(['Computing audio onsets for file ', audiofile])
[onsets_sec, info] = onset_detect_audio(audiofile);

% import plot styles
% ![ Important: requires the custome function 'plotStyles' ]
s = plotStyles();
clr = [s.color1; s.color2];

% plot audio and onsets from audio
figure('Units', 'centimeters', 'Position', s.figsize); 
hold on
plot(timevec, y, 'k')
% add onset markers
for k = 1:numel(onsets_sec)
    xline(onsets_sec(k), 'r--', 'LineWidth', 1);
end
xlabel('Time (s)');
ylabel('Amplitude');
title(['Onsets detected from ' audiofile], 'Interpreter','none');
set(gca, 'FontSize', s.plt_fontsize);

%% plot bela onsets on the audio

% --------------------------------------------------------------------------------------
% ![ Important: Manually load the xdf file on EEGLAB and then run the rest of the code ]
% --------------------------------------------------------------------------------------

if exist('EEG', 'var') && isstruct(EEG) && isfield(EEG, 'data') && ~isempty(EEG.data)
    % find onsets from bela 
    EEG=convertAudioToEvents(EEG,4000);
    % select the EEG segment during the audio 
    startEventIdx = find(strcmp({EEG.event.type}, 'start'));
    st = EEG.event(startEventIdx).latency;
    ed = st + round(duration * EEG.srate) - 1;
    EEG = pop_select( EEG, 'point',[st ed] ); 

    % plot the bela onsets with onset detector onsets 
    % plot audio and onsets from audio
    figure('Units', 'centimeters', 'Position', s.figsize); 
    hold on
    plot(timevec, y, 'k')
    % add onset markers
    for k = 1:numel(onsets_sec)
        xline(onsets_sec(k), 'r--', 'LineWidth', 1.5);
    end
    % add bela markers
    for j = 1:numel(EEG.event)
    xline(EEG.event(j).latency/EEG.srate, 'b--', 'LineWidth', .5);
    end

    xlabel('Time (s)');
    ylabel('Amplitude');
    title(['Onsets detected from ' audiofile], 'Interpreter','none');
    set(gca, 'FontSize', s.plt_fontsize);
else
    display('Load the file manually using EEGLAB before running the script')
end 


