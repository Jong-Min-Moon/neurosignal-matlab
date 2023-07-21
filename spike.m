classdef spike < handle



methods

function sp = spike(ch, thresMultiplier, preTime, postTime)
% initialization
% from CyborgBrainOrg.m
% inputs
%% 1. thres: voltages lower than -thres*sd (i.e. local mins) are considered as peaks of spikes
%% 2. preTime: timelength (millisec) of the spike waveform before the spike peak
%% 3. postTime: timelength (millisec) of the spike waveform before the spike peak


sd_est = median(abs(ch.filtered)/0.6745);
threshold = -thresMultiplier.*median(abs(ch.filtered)/0.6745); % 표준편차를 근사하는 공식. outlier에 덜 민감
            ch.timestampsPrePeak = ceil(preTime * (ch.sf/1000)); % 발견된 spike peak 앞쪽으로 몇 timestamp만큼의 waveform을 저장해야 하는지 계산 
            ch.timestampsPostPeak = ceil(postTime * (ch.sf/1000)); %발견된 spike peak 뒷쪽으로 몇 timestamp만큼의 waveform을 저장해야 하는지 계산 
            ch.spikeTimestamps = []; % spike가 발견된 timestamp를 저장할 1d array
            ch.spikeWaveforms = []; % 앞에서 계산한 길이로 spike 앞뒤를 잘라 얻은 waveform을 각 row에 저장할 nd array
            
            % spike detection 수행 
            ii = ch.timestampsPrePeak + 1;
            count = 0;
            while ii < ch.nTimestamps
                tmp = ch.filtered(ii);
                if tmp < threshold
                    if ii + ch.timestampsPostPeak < ch.nTimestamps % spike가 뒷쪽에 있을 경우 waveformwidth가 확보될 때만 기록.
                        count = count + 1;
                        ch.spikeTimestamps(count) = ii;
                        ch.spikeWaveforms(count,:) = ch.filtered((-ch.timestampsPrePeak : ch.timestampsPostPeak) + ii);
                    end
                    ii = ii + ch.timestampsPostPeak;
                else
                    ii = ii + 1;
                end
            end
            
            
            
            ch.nSpikes = length(ch.spikeTimestamps); %발견한 spike 개수 저장 
            fprintf('number of spikes found : %d\n', ch.nSpikes);
            ch.calculateTotalMeanSpikes(); %mean spike 계산 후 저장
        end %end of detectSpikes
end

end % end of classdef