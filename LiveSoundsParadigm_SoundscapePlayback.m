%% LIVE SOUNDS PLAYBACK wt SOUNDSCAPETASK
% -----------------------------------------------
% This script playback the live sounds recorded using 'LiveSoundsParadigm_Record.m'
% script along with a soundscape audio. The start and end of the experiment is indicated 
% using the respective event markers 
%
% Pre-requisits:
% - LabStreamingLayer (LSL) MATLAB interface
% - Psychtoolbox (with PsychPortAudio enabled)
%
% Author(s) : Abin Jacob
%             Translational Psychology Lab
%             Carl von Ossietzky Universität Oldenburg
%             abin.jacob@uni-oldenburg.de 
% Date      : 21/10/2025
% --------------------------------------------------

clear; clc; close all;

% ------------------------------------------------------------------------
% ----------------------------- SCRIPT SETUP -----------------------------
startwait     = 20;  
filepath      = 'C:\Users\messung\Desktop\Soundscape-Pilots\Paradigms\audio_files';
file1         = 'sticks_sounds_recording.wav';
file2         = 'office-01.mp3'; 
% ------------------------------------------------------------------------

% initialize LSL
disp('Loading LSL library...');
lib = lsl_loadlib();

disp('Creating a new marker stream info...');
info = lsl_streaminfo(lib,'MarkerStream','Markers',1,0,'cf_string','myuniquesourceid23443');
outlet = lsl_outlet(info);

% load both audio files
[audio1, fs1] = audioread(fullfile(filepath, file1));
[audio2, fs2] = audioread(fullfile(filepath, file2));

% check if sample rates match
if fs1 ~= fs2
    error('Sample rates of the two files do not match.');
end

% make sure both audio files have same number of samples
len = min(size(audio1,1), size(audio2,1));
audio1 = audio1(1:len,:)';
audio2 = audio2(1:len,:)';

% combine audio
audioData = audio1 + audio2;
nrchannels = size(audioData,1);

% initialize PsychPortAudio
InitializePsychSound(1); % low-latency mode

disp(['Experiment will begin in ',num2str(startwait),' sec...']);
WaitSecs(startwait);

% open device
pahandle = PsychPortAudio('Open', [], 1, 1, fs1, nrchannels);
PsychPortAudio('FillBuffer', pahandle, audioData);
outlet.push_sample({'start'});

% start playback
startTime = PsychPortAudio('Start', pahandle, 1, 0, 1);

% wait until finished
PsychPortAudio('Stop', pahandle, 1);
outlet.push_sample({'end'});
PsychPortAudio('Close', pahandle);
PsychPortAudio('Close');
disp('All files played successfully.');
