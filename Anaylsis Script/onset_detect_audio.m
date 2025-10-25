function [onsets_sec, info] = onset_detect_audio(filepath, params)
% ONSET_DETECT_AUDIO  Load audio and detect onsets over the entire file.
% 
%   onsets_sec = onset_detect_audio(filepath)
%   [onsets_sec, info] = onset_detect_audio(filepath, params)
%
% Inputs
%   filepath : char/string, path to .wav/.mp3 (any format audioread supports)
%   params   : (optional) struct with fields to override defaults:
%       .blockSize             (default 32)                  % samples
%       .threshBase            (default [16 8 4 4])          % WB, LP, BP, HP
%       .param1_jumpFactor     (default [4 6 32 8])          % jump on detect
%       .decayConst            (default [8000 100 100 2000]) % converts to per-sample decay
%       .tauFast_ms            (default [2 2 2 4])           % ms
%       .tauSlow_ms            (default [20 10 5 160])       % ms
%       .svf_cutoff_Hz         (default 800)
%       .svf_Q                 (default 1/sqrt(2))
%
% Outputs
%   onsets_sec : column vector of onset times (seconds)
%   info       : struct with diagnostics
%       .Fs                : sampling rate
%       .N                 : number of samples used
%       .params            : resolved parameter set
%       .thresh_history    : [N x 4] thresholds (WB,LP,BP,HP)   (may be large)
%       .debug_counts      : struct with counts
%
% Notes
% - Stereo audio is averaged to mono.
% - Uses stateful block processing so filters are continuous across blocks.
% - Energy ratio guards against divide-by-zero.
%
% Author: refactored from your OnsetDetection class (no GUI).

    arguments
        filepath (1,:) char
        params.blockSize (1,1) double = 32
        params.threshBase (1,4) double = [16 8 4 4]
        params.param1_jumpFactor (1,4) double = [4 6 32 8]
        params.decayConst (1,4) double = [8000 100 100 2000] % larger => slower decay
        params.tauFast_ms (1,4) double = [2 2 2 4]
        params.tauSlow_ms (1,4) double = [20 10 5 160]
        params.svf_cutoff_Hz (1,1) double = 800
        params.svf_Q (1,1) double = 1/sqrt(2)
    end

    % ---------- Load audio ----------
    [x, Fs] = audioread(filepath);
    if size(x,2) > 1
        x = mean(x,2); % mono
    end
    x = x(:);
    N = numel(x);

    % ---------- Resolve parameters ----------
    blk = params.blockSize;
    base = params.threshBase(:).';             % row 1x4
    jump = params.param1_jumpFactor(:).';      % row 1x4
    decayConst = params.decayConst(:).';       % row 1x4
    tauFast_ms = params.tauFast_ms(:).';       % row 1x4
    tauSlow_ms = params.tauSlow_ms(:).';       % row 1x4
    cutoff = params.svf_cutoff_Hz;
    Q = params.svf_Q;

    % per-sample decay multiplier (0..1), larger decayConst -> closer to 1 -> slower decay
    decay_mul = decayConst.^(-1/Fs);           % row 1x4

    % ---------- Allocate ----------
    onsets = [];                                % sample indices
    thresh_history = zeros(N, 4, 'double');     % may be big; keep if you want diagnostics

    % States for energy ratio (WB, LP, BP, HP)
    Zi_fast = zeros(1,4);
    Zi_slow = zeros(1,4);

    % States for SVF (shared for LP/BP/HP)
    state1 = 0; state2 = 0;

    % Dynamic threshold raise term
    threshold_raise = zeros(1,4);

    % ---------- Main loop (block-wise, but sample-accurate decisions) ----------
    i = 1;
    while i <= N
        iIn  = i;
        iOut = min(i + blk - 1, N);
        block = x(iIn:iOut);

        % Bandsplit for this block (stateful)
        [out_lp, out_bp, out_hp, state1, state2] = SVF_bandsplit(block, Fs, cutoff, Q, state1, state2);

        % Fast/slow energy ratios per channel (stateful)
        [er_wb, Zi_fast(1), Zi_slow(1)] = FastToSlowEnergyMeasure(block,   Fs, tauFast_ms(1), tauSlow_ms(1), Zi_fast(1), Zi_slow(1));
        [er_lp, Zi_fast(2), Zi_slow(2)] = FastToSlowEnergyMeasure(out_lp,  Fs, tauFast_ms(2), tauSlow_ms(2), Zi_fast(2), Zi_slow(2));
        [er_bp, Zi_fast(3), Zi_slow(3)] = FastToSlowEnergyMeasure(out_bp,  Fs, tauFast_ms(3), tauSlow_ms(3), Zi_fast(3), Zi_slow(3));
        [er_hp, Zi_fast(4), Zi_slow(4)] = FastToSlowEnergyMeasure(out_hp,  Fs, tauFast_ms(4), tauSlow_ms(4), Zi_fast(4), Zi_slow(4));

        DataMatrix = [er_wb, er_lp, er_bp, er_hp]; % size lenBlock x 4

        % Per-sample thresholding inside the block
        nb = numel(block);
        for kk = 1:nb
            thr = base + threshold_raise;  % 1x4
            sampleRow = DataMatrix(kk,:);

            thresh_history(iIn + kk - 1, :) = thr;

            if any(sampleRow > thr)
                onsets(end+1,1) = iIn + kk - 1; %#ok<AGROW>
                threshold_raise = jump .* thr;   % jump up after detection
            end

            % exponential decay each sample
            threshold_raise = threshold_raise .* decay_mul;
        end

        i = iOut + 1;
    end

    % ---------- Outputs ----------
    onsets_sec = onsets / Fs;

    if nargout > 1
        info = struct();
        info.Fs = Fs;
        info.N = N;
        info.params = struct('blockSize', blk, 'threshBase', base, ...
                             'param1_jumpFactor', jump, 'decayConst', decayConst, ...
                             'tauFast_ms', tauFast_ms, 'tauSlow_ms', tauSlow_ms, ...
                             'svf_cutoff_Hz', cutoff, 'svf_Q', Q, ...
                             'decay_multiplier', decay_mul);
        info.thresh_history = thresh_history;
        info.debug_counts = struct('n_onsets', numel(onsets));
    end
end

% ===================== Helpers =====================

function [EnergRatio, Zi_fast, Zi_slow] = FastToSlowEnergyMeasure(inSig, fs, tau_fast_ms, tau_slow_ms, Zi_fast, Zi_slow)
    % One-pole IIR on squared signal (RMS-like envelopes), ratio fast/slow.
    if nargin < 6, Zi_slow = 0; end
    if nargin < 5, Zi_fast = 0; end

    alpha_fast = exp(-1/(tau_fast_ms*1e-3*fs));
    alpha_slow = exp(-1/(tau_slow_ms*1e-3*fs));

    x2 = inSig .* inSig;
    [y_fast, Zi_fast] = filter(1 - alpha_fast, [1 -alpha_fast], x2, Zi_fast);
    [y_slow, Zi_slow] = filter(1 - alpha_slow, [1 -alpha_slow], x2, Zi_slow);

    EnergRatio = y_fast ./ max(y_slow, eps); % guard against divide-by-zero
end

function [out_lp, out_bp, out_hp, state1new, state2new] = SVF_bandsplit(inSig, fs, cutoff, Q, state1, state2)
    % State-Variable Filter (TPT form): returns LP/BP/HP at 'cutoff' and 'Q'
    % Based on references in your class.
    if nargin < 6, state2 = 0; end
    if nargin < 5, state1 = 0; end
    if nargin < 4 || isempty(Q), Q = 1/sqrt(2); end

    wd = cutoff * 2*pi;
    T = 1/fs;
    wa = (2/T) * tan(wd*T/2);

    g = wa*T/2;
    R = 1/(2*Q);

    Mul_state1 = 2*R + g;
    Mul_in = 1/(1 + 2*R*g + g*g);

    out_lp = zeros(size(inSig));
    out_bp = zeros(size(inSig));
    out_hp = zeros(size(inSig));

    for k = 1:numel(inSig)
        x = inSig(k);

        yhp = (x - Mul_state1*state1 - state2) * Mul_in;

        help1 = yhp * g;
        ybp = state1 + help1;
        state1 = ybp + help1;

        help2 = ybp * g;
        ylp = state2 + help2;
        state2 = ylp + help2;

        out_lp(k) = ylp;
        out_bp(k) = ybp;
        out_hp(k) = yhp;
    end

    state1new = state1;
    state2new = state2;
end
