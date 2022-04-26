% FILE: EMG_SignalToNoiseRatio.m
%
% EDITED: Lukas Gerald Wiedemann, March 2017
% Department of Mechanical Engineering, University of Auckland, New Zealand
% https://www.auckland.ac.nz/en.html
% -------------------------------------------------------------------------
% INPUT: data ... 1xn (or nx1) vector, EMG signal of length n
% OPTIONAL: fs ... sample frequency (default: 1000 Hz)
%           show_plot ... to learn about the algorithm: '1' shows relevant
%           plots
%
% OUTPUT: SNR ... double, signal-to-noise ratio [dB]
% Enoise ... double, root-mean-square value of the noise content
% DC ... double, duty-cycle (relative duration of muscle activity
% throughout the signal) [%]
%
% USAGE: This routine obtains the signal-to-noise ratio of cyclic
% electromyographic (EMG) signals without a priori knowledge of the
% signal. The outputs of this routine might be further used as input 
% parameters for double-threshold detectors for determining on- and offsets
% of muscle activity. The procedure performed in this code can be found and
% is based on the following scientific article:
%
% Agostini, V., & Knaflitz, M. (2012). An algorithm for the estimation of 
% the signal-to-noise ratio in surface myoelectric signals generated during 
% cyclic movements. IEEE Transactions on Biomedical Engineering, 59(1), 
% 219–225. doi:10.1109/TBME.2011.2170687
%
% 
%
% MATLAB COMMAND: -----------------------------------------------
% [SNR, Enoise, DC] = EMG_SignalToNoiseRatio(data, fs);
% [SNR, Enoise, DC] = EMG_SignalToNoiseRatio(data) % uses fs = 1000Hz;
% with sample data try: [SNR, Enoise, DC] = EMG_SignalToNoiseRatio(sample_data,1000,1)
% -------------------------------------------------------------------------
% LITERATURE:
% [Ag]: http://ieeexplore.ieee.org/abstract/document/6035761/

function [SNR, Enoise, DC] = EMG_SignalToNoiseRatio(data, fs, show_plots)

if nargin == 1
    fs = 1000;
    show_plots = 0;
end

if nargin == 2
    show_plots = 0;
end

[r, c] = size(data);

if c > r
    data = data';
end

if r ~= 1
    error('Please only use a 1xn vector as input for data');
end

%% 1. 2. and 3. step: divide signal into N/r epochs (N... data length; r = 10 with a sample frequency of 2kHz)
% obtain the normalized sum of squares for these epochs.
r = 10 / (2000/fs); % r=10 is recommended for a sample frequency of 2kHz according to [Ag]
Cr = [];
for k = 1:length(data) / r - 1
   Cr(k) = sum((data((k-1) * r +1: k*r+1).^2)./r); 
end

%% 4. step: obtain the bins and their frequency of the histogram of the series Log10(Cr)
nbins = 60;
bins = [];
for m = 1:2:nbins*2-1
   bins(end+1) = m*((max(log10(Cr)) - min(log10(Cr)))/(2*nbins))...
       + min(log10(Cr)); 
end

Freq = hist(log10(Cr),bins);

%% 5. step: smoothing of Freq and search of local maximas
y_new = rms_calc(Freq,7); % performs a root-mean-square (rms) of the frequencies of the histogram with a window size of 7 frames
y_new = rms_calc(y_new,7); % double rms calculation to smooth the curve (to view results set 'show_plots' to '1')

[~, locs] = findpeaks(y_new, 1:length(y_new),'MinPeakDistance', 3, 'SortStr', 'descend');
if (length(locs) < 2) % if two peaks in the curve cannot be found return NaNs
    disp('Signal and noise cannot be distinguished');
    SNR = NaN;
    Enoise = NaN;
    DC = NaN;
    return;
end

Inoise = locs(1);
Isignal = locs(2);

%% 6. step: Estimate mean power of noise
Pnoise = sum(10.^bins(Inoise-2:Inoise+2) .* Freq(Inoise-2:Inoise+2)) / ...
    sum(Freq(Inoise-2:Inoise+2));

%% 7. step: Estimate mean power of signal
Psignal = sum(10.^bins(Isignal-2:Isignal+2) .* Freq(Isignal-2:Isignal+2)) / ...
    sum(Freq(Isignal-2:Isignal+2));

if (Psignal < Pnoise)
    disp('SNR insufficient');
    SNR = NaN;
    Enoise = NaN;
    DC = NaN;
    return;
end

%% 8. step: Estimate RMS value of background noise
Enoise = sqrt(Pnoise);

%% 9. step: Estimate SNR
SNR = 10* log10((Psignal - Pnoise)/Pnoise);

%% 10. step: Estimate the DC (%)
DC = 100 * sum(Freq(Isignal-2:Isignal+2)) / ...
    (sum(Freq(Isignal-2:Isignal+2)) + sum(Freq(Inoise-2:Inoise+2)));

%% optional step: show plots to learn about the algorithm
if show_plots
    figure,
    plot(data)
    title('raw data')
    
    figure,
    hist(log10(Cr),bins)
    title('Histogram of Log10(C)')
    hold all
    plot(bins,Freq, 'Linewidth', 2)
    plot(bins, y_new, 'Linewidth', 2)
end
