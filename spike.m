function [timestampsPrePeak, timestampsPostPeak, timeStamp, waveform] = spike(x, sf, thres, preTime, postTime)

threshold = -thres.*median(abs(x)/0.6745); % approximate standard deviation, robust to outliers
timestampsPrePeak = ceil(preTime * (sf/1000)) %reference code: 2ms * 30stamps/ms = 60stamps
timestampsPostPeak = ceil(postTime * (sf/1000)); %reference code: 2ms * 30stamps/ms = 60stamps

% In the reference code and data, timestamp per milisecond was an integer(30)
% so the waveform length in terms of timestamps was conviniently calculated as 2*30.
% For our dataset, timestamp per milisecond is not an integer.
% So instead of using 2*30, we explicitly make varaibles to store waveform length in terms of timestamp(ceild to make them into integer). 

% spike detection
timeStamp = []; % 1d array to store the timestamp of spike occurrence.
waveform = []; % nd array to store the waveform of spikes. Each row represents one waveform of spike.
ii = timestampsPrePeak;
count = 0;

while ii < length(x)
    tmp = x(ii);
    if tmp < threshold
        if timestampsPostPeak + ii < length(x) % spike가 뒷쪽에 있을 경우 waveformwidth가 확보될 때만 기록.
            count = count + 1;
            timeStamp(count) = ii;
            waveform(count,:) = x((-timestampsPrePeak : timestampsPostPeak) + ii);
        end
        ii = ii + timestampsPostPeak;
    else
        ii = ii + 1;
    end
end
