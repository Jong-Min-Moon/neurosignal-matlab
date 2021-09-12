function [tResampled, xResampled, msPerTimestamp, desiredSamplingFrequency] = loadResample(filename)
% load the file, read time interval, convert into 1d array, 
% and resample into uniform time interval(for passband filtering)


%% Read data
% load dataset
% use 16 digits of precision(MATLAB default)
data = readmatrix(filename);

%% Convert data into a single 1d array

% calculate time interval of each bin(which contains 256 observations)
binTimeStart = data(:,5); %assuming that 'time' means starting time.
binTimeInterval = diff(binTimeStart);
binTimeInterval(end+1) = binTimeInterval(end);

% x varaible into a single 1d array
x = data(:,6:end); % data in format of matrix of size nBin * 256 
% [nBins, nPointsPerBin] = size(x);
x = transpose(x);
x = x(:); % collapse into 1d array, columnwisely

% time variable into a single 1d array
tPercentileInsideBin = linspace(0,255/256,256);
t = binTimeStart + binTimeInterval * tPercentileInsideBin;
t = transpose(t);
t = t(:);

%% resample the signal using spline, to make uniform time interval
msPerTimestamp = mean(binTimeInterval) * (1000/256); % milisecond per timestamp. stamp->ms conversion.
desiredSamplingFrequency = 1000 * (1/msPerTimestamp); %approx. 3000hz. 1/10 of reference code 30000hz
[xResampled, tResampled] = resample(x, t, desiredSamplingFrequency, 'spline');