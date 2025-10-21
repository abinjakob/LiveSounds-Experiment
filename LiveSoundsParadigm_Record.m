%% LIVE SOUNDS TASK WITH LSL MARKER & AUDIO RECORDING
% ----------------------------------------------------
% This script runs an live sounds task using Psychtoolbox and Lab Streaming 
% Layer (LSL). The start and end of the experiment is indicated using the
% respective event markers and the live sounds are recorded in paralel. 
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

startwait   = 20;    % initial wait period before experiment begins in seconds
recordfile  = 'sticks_sounds_recording.wav';  
soundscapefile = 'office-01.mp3';
filepath    = 'C:\Users\messung\Desktop\Soundscape-Pilots\Paradigms\audio_files';

% ------------------------------------------------------------------------




% initialize LSL
disp('Loading LSL library...');
lib = lsl_loadlib();

disp('Creating a new marker stream info...');
info   = lsl_streaminfo(lib,'MarkerStream','Markers',1,0,'cf_string','myuniquesourceid23443');
outlet = lsl_outlet(info);

% determine experiment duration
% loading the soundscape file and setting the audio duration as experiment length
[y, audioFs] = audioread(fullfile(filepath, soundscapefile));
expduration = round(length(y) / audioFs); 


% PsychPort setup
InitializePsychSound(1);                    % 1 = low-latency mode
PsychPortAudio('Close');

% beep tone to indicate start & end of the experiment
fs         = 44100;                         
nrchannels = 1;                             
pahandle   = PsychPortAudio('Open', [], 1, 1, fs, nrchannels);
amp      = 0.5;                          
duration = 0.2;                   
freq     = 880;  
t        = 0:1/fs:duration;
soundData = amp * sin(2*pi*freq*t); 
soundData = soundData(:)';                  % row
soundData = repmat(soundData, nrchannels,1); % channels x samples

% audio recording setup
rec_fs      = 44100;    
rec_channels = 1;      % 1 for mono, 2 for stereo
rec_device   = 7;      % run getaudioDevice script to determine audio device
bufferSize  = 0; 

% open audio device for recording
rec_handle = PsychPortAudio('Open', rec_device, 2, 1, rec_fs, rec_channels);
PsychPortAudio('GetAudioData', rec_handle, expduration + 1);


% pause between start
disp(['Experiment will begin in ',num2str(startwait),' sec...']);
WaitSecs(startwait);


% -- main task loop --
% start experiment
PsychPortAudio('FillBuffer', pahandle, soundData);
PsychPortAudio('Start', pahandle, 1, 0, 1);
disp('Experiment Started');
WaitSecs(duration); % wait until beep finishes
outlet.push_sample({'start'});
% start audio recording
PsychPortAudio('Start', rec_handle, 1, 0, 1);

% run for experiment duration
WaitSecs(expduration);

% stop recording and get audio
PsychPortAudio('Stop', rec_handle);
[audioData, ~, overflow] = PsychPortAudio('GetAudioData', rec_handle);
PsychPortAudio('Close', rec_handle);

outlet.push_sample({'end'});

% end experiment
PsychPortAudio('FillBuffer', pahandle, soundData);
PsychPortAudio('Start', pahandle, 1, 0, 1);
disp('Experiment Complete');
WaitSecs(duration);
PsychPortAudio('Stop', pahandle);
PsychPortAudio('Close', pahandle);

% save audio
audiowrite(fullfile(filepath, recordfile), audioData', rec_fs);
disp('Recording saved');


