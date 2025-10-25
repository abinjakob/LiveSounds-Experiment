function out = align_stream2_to_stream1(t1, X1, t2, X2, varargin)
%ALIGN_STREAM2_TO_STREAM1  Align a 2nd stream to a reference stream's time axis.
%
%   OUT = ALIGN_STREAM2_TO_STREAM1(T1, X1, T2, X2, ...) returns X2 aligned
%   to the timestamps in T1. Stream 2 may start/end earlier or later and
%   may have a different number of samples. The result has exactly
%   length(T1) rows, with non-overlapping parts padded.
%
%   INPUTS
%     T1 : [N1x1] reference timestamps (seconds)
%     X1 : [N1xC1] reference samples (unused for the alignment; passed to OUT)
%     T2 : [N2x1] timestamps of stream 2 (seconds)
%     X2 : [N2xC2] samples of stream 2 (rows=time)
%
%   NAME-VALUE OPTIONS
%     'Interp' : 'linear' | 'nearest' | 'pchip'  (default 'nearest')
%                Interpolation used to sample X2 at T1.
%     'Pad'    : 'zero' | 'nan' | 'edge'         (default 'zero')
%                How to fill values where T1 lies outside [T2(1), T2(end)]:
%                  'zero' -> fill with 0
%                  'nan'  -> fill with NaN
%                  'edge' -> replicate nearest edge value of X2
%
%   OUTPUT (struct)
%     .t_ref        : copy of T1
%     .X1           : copy of X1 (for convenience)
%     .X2_aligned   : [N1 x C2] stream-2 samples aligned to T1 (padded)
%     .overlap_mask : [N1 x 1] logical; true where T1 is within [T2(1),T2(end)]
%     .t2_window    : [t2_start t2_end]
%     .coverage     : seconds of temporal overlap
%     .frac_covered : fraction of T1 inside T2's range
%
%   EXAMPLE
%     % Suppose T1/X1 is your reference stream (e.g., EEG),
%     % and T2/X2 is another sensor that may start later and end earlier.
%     out = align_stream2_to_stream1(T1, X1, T2, X2, 'Interp','linear','Pad','nan');
%     X2a = out.X2_aligned;        % same number of rows as X1
%     m   = out.overlap_mask;      % where X2 actually had support
%
%     % Plot a channel to verify alignment
%     ch = 1;
%     plot(out.t_ref, X1(:,min(ch,size(X1,2))), '-', out.t_ref, X2a(:,min(ch,size(X2a,2))), '--');
%     xlabel('Time (s)'); legend('X1','X2 aligned');
%
%   NOTES
%     - No assumption of equal sampling rates needed.
%     - If you KNOW both streams share the same Fs and want sample-accurate
%       nearest-neighbour alignment, use 'Interp','nearest'.
%
%   See also interp1
%
%   Martin’s helper — 2025-09-29

p = inputParser;
p.addParameter('Interp','nearest', @(s)ischar(s)||isstring(s));
p.addParameter('Pad','zero', @(s)ischar(s)||isstring(s));
p.parse(varargin{:});
opt = p.Results;
opt.Interp = char(opt.Interp);
opt.Pad    = char(opt.Pad);

% ---- shape & sanity
t1 = t1(:); t2 = t2(:);
X1 = ensure2D(X1); X2 = ensure2D(X2);

if size(X1,1) ~= numel(t1), error('Rows(X1) must equal length(T1).'); end
if size(X2,1) ~= numel(t2), error('Rows(X2) must equal length(T2).'); end

% ---- compute overlap of T1 against T2 domain
in2 = (t1 >= t2(1)) & (t1 <= t2(end));  % where T1 falls inside T2 range
t_ref = t1;

% ---- choose padding filler per channel
switch lower(opt.Pad)
    case 'zero'
        padfun = @(n,c) zeros(n,c);
    case 'nan'
        padfun = @(n,c) nan(n,c);
    case 'edge'
        % We'll fill with nearest edge value after interpolation/extrapolation.
        padfun = []; % handled later
    otherwise
        error('Unknown Pad option: %s', opt.Pad);
end

% ---- interpolate X2 at T1
% Use 'extrap' then post-fix padding zones explicitly to the requested scheme.
X2a = nan(numel(t_ref), size(X2,2));
for c = 1:size(X2,2)
    X2a(:,c) = interp1(t2, X2(:,c), t_ref, opt.Interp, 'extrap');
end

% ---- apply padding outside overlap
if strcmpi(opt.Pad,'edge')
    % replicate nearest edge values in out-of-range zones
    leftMask  = t_ref < t2(1);
    rightMask = t_ref > t2(end);
    if any(leftMask)
        X2a(leftMask,:) = repmat(X2(1,:), sum(leftMask), 1);
    end
    if any(rightMask)
        X2a(rightMask,:) = repmat(X2(end,:), sum(rightMask), 1);
    end
else
    mask = ~in2;
    if any(mask)
        X2a(mask,:) = padfun(sum(mask), size(X2,2));
    end
end

% ---- coverage stats
t2win   = [t2(1) t2(end)];
if any(in2)
    % Approx coverage in seconds: count of in2 * median dt of t1
    dt1 = median(diff(t1)); 
    coverage = sum(in2) * dt1;
else
    coverage = 0;
end
frac_cov = mean(in2);   % fraction of T1 covered by T2

% ---- pack
out = struct();
out.t_ref        = t_ref;
out.X1           = X1;
out.X2_aligned   = X2a;
out.overlap_mask = in2;
out.t2_window    = t2win;
out.coverage     = coverage;
out.frac_covered = frac_cov;

end

% ---------- helpers ----------
function X = ensure2D(X)
    if isvector(X), X = X(:); end
end
