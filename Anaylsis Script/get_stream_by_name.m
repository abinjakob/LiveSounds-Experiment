function s = get_stream_by_name(streams, name)
%GET_STREAM_BY_NAME  Retrieve an LSL stream struct from load_xdf by its name.
%
%   S = GET_STREAM_BY_NAME(STREAMS, NAME) searches through the cell array
%   STREAMS (as returned by LOAD_XDF) and returns the first stream whose
%   .info.name matches the string NAME.
%
%   INPUTS:
%       STREAMS : cell array of stream structs from load_xdf
%       NAME    : string, the name of the desired stream
%
%   OUTPUT:
%       S       : struct corresponding to the requested stream. Contains
%                 at least the following fields:
%                   .info.name       (string, stream name)
%                   .info.type       (string, stream type)
%                   .time_stamps     (double array, timestamps in seconds)
%                   .time_series     (matrix, samples; rows=channels, cols=time)
%
%   EXAMPLES:
%       % Load an XDF file
%       [streams, header] = load_xdf('myrecording.xdf');
%
%       % List all available stream names
%       for k = 1:numel(streams)
%           fprintf('Stream %d: %s\n', k, streams{k}.info.name);
%       end
%
%       % Retrieve specific streams by name
%       eeg     = get_stream_by_name(streams, 'EEG');
%       markers = get_stream_by_name(streams, 'Markers');
%
%       % Plot first EEG channel against time
%       plot(eeg.time_stamps, eeg.time_series(1,:));
%       xlabel('Time (s)');
%       ylabel('Amplitude');
%       title('EEG Channel 1');
%
%   See also LOAD_XDF

    % Input validation
    if ~iscell(streams)
        error('STREAMS must be a cell array as returned by load_xdf.');
    end
    if ~ischar(name) && ~isstring(name)
        error('NAME must be a character vector or string.');
    end
    name = char(name);

    % Search for matching stream
    idx = find(cellfun(@(x) strcmp(x.info.name, name), streams), 1);

    if isempty(idx)
        error('No stream named "%s" found in the provided streams.', name);
    end

    % Return the stream struct
    s = streams{idx};
end
