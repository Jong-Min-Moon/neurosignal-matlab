%load dataset
% use 16 digits of precision(MATLAB default)

data = readmatrix("raw data.csv");
binTimeStart = data(:,5);
binTimeInterval = diff(binTimeStart);
binTimeInterval(end+1) = binTimeInterval(end)

%turn MFP values into a single 1d array
LFPValues = data(:,6:end);
[nBins, nPointsPerBin] = size(LFPValues);
LFPValues = LFPValues.'; %transpose
LFPValues = LFPValues(:); % collapse into 1d array, columnwisely

%time variable into a single 1d array
tPercentileInsideBin = linspace(0,255/256,256)
t = binTimeStart + binTimeInterval * tPercentileInsideBin;
t = t.';
t = t(:);

%resample the signal using spline, to make uniform time interval
Ts = mean(binTimeInterval)/256
desiredFs = 1/Ts;
[LFPValuesResampled, tResampled] = resample(LFPValues, t, desiredFs, 'spline');

plot(t, LFPValues)
hold on
plot(tResampled, LFPValuesResampled)
hold off
legend('Original', 'Resampled using spline')

%apply xxx-xxxx Hz bandpath filter
LFPValuesfiltered = bandpass(LFPValuesResampled, [500, 1000], desiredFs)

subplot(2,1,1);
plot(tResampled, LFPValuesResampled)
subplot(2,1,2);
plot(tResampled, LFPValuesfiltered)


