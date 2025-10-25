function [EEG] = convertAudioToEvents(EEG, threshold)
% convertAudioToEvents - Detects sound events in an EEG channel and adds them as event markers in EEGLAB.
%
% Syntax:  [EEG] = convertAudioToEvents(EEG, threshold)
%
% Inputs:
%    EEG - EEGLAB structure containing EEG data
%    threshold - Threshold value to detect sound events
%
% Outputs:
%    EEG - EEGLAB structure with added event markers
%
% Example: 
%    EEG = convertAudioToEvents(EEG, 2000);
%
% Other m-files required: eeglab, pop_editeventvals, eeg_checkset
% Subfunctions: none
% MAT-files required: none
%
% See also: EEG, eeglab
%
% Author: Martin Bleichner
% Email: martin.bleichner@uol.de
% Date: 2024-06-03
% License: MIT License

% The MIT License (MIT)
% 
% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
% 
% The above copyright notice and this permission notice shall be included in
% all copies or substantial portions of the Software.
% 
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
% THE SOFTWARE.

%------------- BEGIN CODE --------------

% Extract the channel that records sound events
MarkerChannel = EEG.data(7, :);

% Detect points where the signal crosses the threshold from below
crossings = find(MarkerChannel(1:end-1) < threshold & MarkerChannel(2:end) >= threshold);

% Initialize the EEG.event structure if it is empty
if isempty(EEG.event)
    EEG.event = struct('latency', {}, 'type', {});
end

% Add detected sound events as new events in the EEG structure
for k = 1:length(crossings)
    EEG.event(end+1).latency = crossings(k);  % Add latency of the event
    EEG.event(end).type = 'SoundOnset';  % Define event type
end

% Ensure event consistency and sort events by latency
EEG = eeg_checkset(EEG, 'eventconsistency');
EEG = pop_editeventvals(EEG, 'sort', {'latency' 0});

%------------- END OF CODE --------------
end
