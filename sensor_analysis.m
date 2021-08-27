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

pointIndexPerBin = 0 : (nPointsPerBin-1);
t = binTimeStart + binTimeInterval * (pointIndexPerBin/256);
t = t.';
t = t(:);
Ts = mean(binTimeInterval)/256
desiredFs = 1/Ts;

[LFPValuesResampled, tResampled] = resample(LFPValues, t, desiredFs, 'spline')

plot(t, LFPValues)
hold on
plot(tResampled, LFPValuesResampled)
hold off
legend('Original', 'Resampled using spline')