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
            spike_waveform = cmsa.spikeWaveforms(i,)
            signal_max = max(spike_waveform)
            signal_min = min(spike_waveform)
            amp = signal_max - signal_min;
            amp_array(i) = amp;
        end % end of for
        average_amp = mean(amp_array);
        end % end of function get_average_amp

        function time_min_spike = get_time_min_spike_new(cmsa, ts_spike_peak)
        spikeIdx = find(cmsa.spikeTimestamps==ts_spike_peak);
        spikeWaveform = cmsa.spikeWaveforms(spikeIdx,:);
        amp_min_spike = min(spikeWaveform);
        time_min_spike = ts_spike_peak - cmsan_timestamps_pre_peak + find(spikeWaveform==amp_min_spike) - 1;
        end % end of function get_time_min_spike

       function time_max_spike = get_time_max_spike_new(cmsa, ts_spike_peak)
        spikeIdx = find(cmsa.spikeTimestamps==ts_spike_peak);
        spikeWaveform = cmsa.spikeWaveforms(spikeIdx,:);
        amp_max_spike = max(spikeWaveform);
        time_max_spike = ts_spike_peak - cmsan_timestamps_pre_peak + find(spikeWaveform==amp_max_spike) - 1;
        end % end of function get_time_min_spike
    end % end of method
        function [average_amp, aaa] = get_average_amp_old(cmsa, range_start, range_end, signal)
        % range_start = spike를 계산에 포함시키는 시간 범위 시작점
        % range_end = spike를 계산에 포함시키는 시간 범위 끝점
        start_number = cmsa.get_first_spike_timestamp(range_start);
        end_number = cmsa.get_end_number(range_end);
        sum_amp = 0;
        u=1;
        for i = start_number:end_number
            ts_spike_peak = cmsa.spikeTimestamps(i);
            time_min_spike = cmsa.get_time_min_spike(ts_spike_peak, signal); % i번째 spike의 위치 가져오기
            time_max_spike = cmsa.get_time_max_spike(ts_spike_peak, time_min_spike, signal);
            aaa(u) = signal(time_max_spike) - signal(time_min_spike);
            sum_amp = sum_amp + signal(time_max_spike)-signal(time_min_spike);
            u = u + 1;
            if i == end_number
                average_amp = sum_amp / (end_number-start_number+1);
            end % end of if
        end % end of for
        end % end of function get_average_amp

        function start_number = get_first_spike_timestamp(cmsa, time_start)
            % find the timestamp of the first spike
            % inside the specified time range
            start_number = 0;
            ttt = 1;
            ts_spike_peak_2 = 0;
            
            while ttt < cmsa.numberofspikes
                ts_spike_peak_2 = cmsa.spikeTimestamps(ttt);
                start_number = start_number + 1;
                if ts_spike_peak_2 > time_start * cmsa.sf
                    ttt = cmsa.numberofspikes + 1;
                end
                ttt=ttt+1;
            end
        end % end of get_start_number

        function end_number = get_end_number(cmsa, range_end)
            end_number = 0;
            ts_spike_peak_3 = 0;
            eee=1;
            while eee < cmsa.numberofspikes
                ts_spike_peak_3 = cmsa.spikeTimestamps(eee);
                end_number = end_number + 1;
                 if ts_spike_peak_3 > range_end * cmsa.sf
                    eee = cmsa.numberofspikes + 1;
                    end_number = end_number-1;
                end
                eee = eee+1;
            end
        end % end of function get_end_number

        function time_min_spike = get_time_min_spike(cmsa, ts_spike_peak, signal)
        min_spike = 0;
        tsInterval = ts_spike_peak + (-cmsa.n_timestamps_pre_peak : cmsa.n_timestamps_ms_post_peak); % spike를 중심으로 waveform의 t축 범위를 timestamp 단위로 정함. 해당 범위에 해당하는 timestamp index를 저장
        for k = tsInterval
            if min_spike > signal(k)
                min_spike = signal(k);
                time_min_spike = k;
            end % end of if
        end % end of for
        end % end of function get_time_min_spike



        function time_max_spike = get_time_max_spike(cmsa, ts_spike_peak, time_min_spike, signal)
            s = time_min_spike;
            while s < (ts_spike_peak + cmsa.n_timestamps_ms_post_peak)
                if signal(s) < signal(s+1)
                    time_max_spike = s+1;
                    s=s+1;
                else
                    s = ts_spike_peak + cmsa.n_timestamps_ms_post_peak+1;% escape while
                end % end of if
            end % end of while
        end % end of function get_time_max_spike

 

        
end % end of class



    

        
  




   
            


 
        



