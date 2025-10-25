function EEG = shift_event_latency(EEG, delay_ms)
% SHIFT_EVENT_LATENCY  Correct event latencies in an EEGLAB dataset
%
%   EEG = shift_event_latency(EEG, delay_ms)
%
%   Shifts all EEG.event and EEG.urevent latencies by a fixed delay.
%
%   INPUT:
%       EEG      - EEGLAB dataset
%       delay_ms - Delay in milliseconds
%                  (positive = observed triggers are late, so move earlier)
%
%   OUTPUT:
%       EEG      - Updated dataset with corrected event latencies
%
%   Example:
%       EEG = shift_event_latency(EEG, 60);  % shift events 60 ms earlier

    if nargin < 2
        error('Usage: EEG = shift_event_latency(EEG, delay_ms)');
    end
    
    % Convert ms to samples
    sampleshift = round((delay_ms/1000) * EEG.srate);

    % Total number of samples in dataset
    total_samples = EEG.pnts;

    % Helper to clip to [1, total_samples]
  %  clip = @(x) min(max(x, 1), total_samples);

    % --- Shift EEG.event ---
    if ~isempty(EEG.event)
        for k = 1:numel(EEG.event)
            if isfield(EEG.event(k), 'latency') && ~isempty(EEG.event(k).latency)
              %  EEG.event(k).latency = clip(EEG.event(k).latency - sampleshift);
                                EEG.event(k).latency = EEG.event(k).latency - sampleshift;

            end
        end
    end

    % --- Shift EEG.urevent ---
    if isfield(EEG, 'urevent') && ~isempty(EEG.urevent)
        for k = 1:numel(EEG.urevent)
            if isfield(EEG.urevent(k), 'latency') && ~isempty(EEG.urevent(k).latency)
                EEG.urevent(k).latency = EEG.urevent(k).latency - sampleshift;
            end
        end
    end

    % Recompute event/epoch consistency
    EEG = eeg_checkset(EEG, 'eventconsistency');

    % Log in EEG.history
    EEG.history = sprintf('%s\n%% shift_event_latency: shifted events by -%d samples (%.1f ms).', ...
                          EEG.history, sampleshift, delay_ms);
end
