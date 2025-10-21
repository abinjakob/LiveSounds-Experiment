%% LIVE SOUNDS PLAYBACK TASK
% --------------------------
% This script playsback the live sounds recorded using 'LiveSoundsParadigm_Record.m'
% script. The start and end of the experiment is indicated using the respective event markers 
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

% initial wait period before experiment begins 
startwait     = 20;  
% path to audio files
filepath      = 'C:\Users\messung\Desktop\Soundscape-Pilots\Paradigms\audio_files';
recordedfile  = 'sticks_sounds_recording.wav'; 
      
% ------------------------------------------------------------------------




% initialize LSL
disp('Loading LSL library...');
lib = lsl_loadlib();

disp('Creating a new marker stream info...');
info = lsl_streaminfo(lib,'MarkerStream','Markers',1,0,'cf_string','myuniquesourceid23443');
outlet = lsl_outlet(info);

% load recorded audio file
[audioData, fs] = audioread(fullfile(filepath, recordedfile));
audioData = audioData';  % [channels x samples]
nrchannels = size(audioData,1);

% initialize PsychPortAudio
InitializePsychSound(1); % Request low-latency mode

% pause between start
disp(['Experiement will begin in ',num2str(startwait),' sec...']);
WaitSecs(startwait);

% open device for this file's sample rate & channels
pahandle = PsychPortAudio('Open', [], 1, 1, fs, nrchannels);
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

