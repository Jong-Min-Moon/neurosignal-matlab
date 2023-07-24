classdef calculaterMeanSpikeAmplitude < handle
    % inputs spike information, outputs mean amplitude information
    % original code written by the lab representative of WearableLab Yonsei 
    properties
        spikeTimestamps
        numberofspikes
        sf
        n_timestamps_pre_peak
        n_timestamps_ms_post_peak
        signal_raw
        signal_filtered
        spikeWaveforms
        nSpikes
    end

    methods
        function cmsa = calculaterMeanSpikeAmplitude(channel_object)
        cmsa.spikeTimestamps = channel_object.spikeTimestamps;
        cmsa.sf = channel_object.sf;
        cmsa.numberofspikes = length(cmsa.spikeTimestamps);
        cmsa.n_timestamps_pre_peak = channel_object.timestampsPrePeak;
        cmsa.n_timestamps_ms_post_peak = channel_object.timestampsPostPeak;
        cmsa.signal_raw = channel_object.raw;
        cmsa.signal_filtered = channel_object.filtered;
        cmsa.spikeWaveforms = channel_object.spikeWaveforms;
        cmsa.nSpikes = channel_object.nSpikes;
        end % end of initializer

        function [average_amp, aaa] = get_average_amp_raw(cmsa, range_start, range_end)
        [average_amp, aaa] = cmsa.get_average_amp(range_start, range_end, cmsa.signal_raw);
        end

        function [average_amp, aaa] = get_average_amp_filtered(cmsa, range_start, range_end)
        [average_amp, aaa] = cmsa.get_average_amp(range_start, range_end, cmsa.signal_filtered);
        end
        function [average_amp, amp_array] = get_average_amp(cmsa)
        % range_start = spike를 계산에 포함시키는 시간 범위 시작점
        % range_end = spike를 계산에 포함시키는 시간 범위 끝점
        amp_array = NaN([1,cmsa.nSpikes]);
       
        for i = 1:cmsa.nSpikes
            spike_waveform = cmsa.spikeWaveforms(i,:);
            signal_max = max(spike_waveform);
            signal_min = min(spike_waveform);
            amp = signal_max - signal_min;
            amp_array(i) = amp;
        end % end of for
        average_amp = mean(amp_array);
        end % end of function get_average_amp

    end


 

        
end % end of class



    

        
  




   
            


 
        



