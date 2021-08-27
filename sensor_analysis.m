%load dataset
% use 16 digits of precision(MATLAB default)
format long % display numbers up to 15 digits

data = readmatrix("raw data.csv");
binTimeStart = data(:,5);
binTimeInterval = diff(binTimeStart);

%turn MFP values into a single 1d array
LFPValues = data(:,6:end);
[nBins, nPointsPerBin] = size(LFPValues);
LFPValues = LFPValues.'; %transpose
LFPValues = LFPValues(:); % collapse into 1d array, columnwisely

pointIndexPerBin = 0 : (nPointsPerBin-1);
time = binTimeStart + binTimeInterval * (pointIndexPerBin/256);
time = time.';
time = time(:);


plot(time, LFPValues)