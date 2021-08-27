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
Ts = mean(binTimeInterval)/256 % milisecond per timestamp
desiredFs = 1/Ts %approx. 3000hz. 1/10 of reference code 30000hz
[LFPValuesResampled, tResampled] = resample(LFPValues, t, desiredFs, 'spline');

plot(t, LFPValues)
hold on
plot(tResampled, LFPValuesResampled)
hold off
legend('Original', 'Resampled using spline')

%apply xxx-xxxx Hz bandpath filter
LFPValuesfiltered = bandpass(LFPValuesResampled, [1000, 2000], desiredFs);

subplot(3,1,1);
plot(tResampled, LFPValuesResampled)
xlim([min(tResampled), max(tResampled)])

subplot(3,1,2);
plot(tResampled, LFPValuesfiltered)
xlim([min(tResampled), max(tResampled)])



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%paramter setting
thres = 10; %define multiple of sigma
threshold = -thres.* median(abs(LFPValuesfiltered)/0.6745); %approximate standard deviation with probable error
waveformHalfWidth = 600 %reference code: 2 * 30 = 60
time_stampl = []
waveform = []

%%spike detection
count = 0;
ii = waveformHalfWidth
while ii < length(LFPValuesfiltered)
    tmp = LFPValuesfiltered(ii);
    if tmp < threshold
        if ii + waveformHalfWidth < length(LFPValuesfiltered) % spike가 뒷쪽에 있을 경우 waveformwidth가 확보될 때만 기록한다.
            count = count + 1;
            time_stamp(count) = ii;
            waveform(count,:) = LFPValuesfiltered( (-waveformHalfWidth : waveformHalfWidth) + ii );
        end
        ii = ii + waveformHalfWidth;
    else
        ii = ii + 1;
    end
end
            

%plot((-waveformHalfWidth : waveformHalfWidth)*Ts, waveform')
%xlabel('time(ms)')
%ylabel('Voltage(uV)')



%raster plot
subplot(3,1,3);
hold on
for ii = 1:length(time_stamp)
    time_stamp(ii)
    plot(binTimeStart(1) + [time_stamp(ii), time_stamp(ii)]*Ts, [-1,1], 'k');
end
xlim([min(tResampled), max(tResampled)])
ylim([-10,10])

%%dimension reduction (PCA)
waveform = zscore(waveform)