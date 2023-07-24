classdef channel < handle
    %핸들 클래스는 object를 참조하는 객체를 정의합니다. 객체를 복사하면 동일한 객체에 대한 *참조*가 하나 더 생성됩니다.
    properties
        organoidNum
        channelNum
        month
        sf
        msPerTs
        nTimestamps
        
        startTime
        endTimeApprox
        durationApprox
        
        originalTime
        t 
        raw
        
        filtered
        timestampsPrePeak
        timestampsPostPeak
        
        spikeTimestamps
        spikeTimestampsMatrix
        spikeWaveforms
        
        nSpikes
        PCScores
        explainedVar
        clusters
        nClusters
        nSpikesPerCluster
        
        totalMeanSpikeStruct
        meanSpikesStruct
        
        ISIbeforePCA
        ISI
        ISIStruct

        spikeBandAngles
        phaseStruct
        clusterColors

        % phase analysis per frequency band
        bandWave
        bandPhase
        bandAmplitude
        
        
        bursts
        
        
        %EMG data analysis
        originalSignal
        
        
        % baseline filterd
        signalRawLowBaseline
        signalRawNoBaseline
        signalFilteredLowBaseline
        signalFilteredNoBaseline
        
        % Rectified
        rawRectified
        filteredRectified
        signalRawLowBaselineRectified
        signalRawNoBaselineRectified
        signalFilteredLowBaselineRectified
        signalFilteredNoBaselineRectified
        

        % Enveloped
        rawEnveloped
        filteredEnveloped
        signalRawLowBaselineEnveloped
        signalRawNoBaselineEnveloped
        signalFilteredLowBaselineEnveloped
        signalFilteredNoBaselineEnveloped

        % max values of enveloped
        rawEnvelopedMax
        filteredEnvelopedMax
        signalRawLowBaselineEnvelopedMax
        signalRawNoBaselineEnvelopedMax
        signalFilteredLowBaselineEnvelopedMax
        signalFilteredNoBaselineEnvelopedMax


        %% for firing rate
        rawShuffled
        
       
    end
    
    methods
        function ch = channel(x, t, sampleRate, organoidNum, channelNum, month)%(*)
            % organoidNum, channelNum, month: 관리를 위한 index
                  
            % 필요한 값 저장
            ch.organoidNum = organoidNum;
            ch.channelNum = channelNum;
            ch.month = month;
            
            ch.sf = sampleRate;
            ch.msPerTs = (1000 / sampleRate);
            
            % t related
            ch.originalTime = t;
            ch.t = t;
            ch.nTimestamps = length(t);
            ch.startTime = t(1);
            ch.endTimeApprox = t(end);
            ch.durationApprox = t(end) - t(1);
            
            % signals
            ch.originalSignal = x;
            ch.raw = x;
            ch.filtered = x; %일단 filtered에도 raw x를 저장해 놓음


            
            ch.clusterColors = ["red", "green", "blue", "magenta", "cyan", "yellow"]';
            
            % provide essential information to the user
            fprintf("channel number = %d\n", ch.channelNum)
            fprintf("sampling rate = %fHz\n", ch.sf)
            fprintf("starts at %f, ends at %f, duration = %f\n", ch.startTime, ch.endTimeApprox, ch.durationApprox)
            fprintf("number of timestamps = %d\n\n", ch.nTimestamps)
        end
        

     
        %% Preprocessing for EMG
            %% 1. cutting

        function cutTime(ch, timeInterval)
            
            [timestampStart, timestampEnd] = ch.getIntervalTimestamps(timeInterval);
            ch.t = ch.t(timestampStart : timestampEnd);
            ch.nTimestamps = length(ch.t);
            
            ch.startTime = ch.t(1);
            ch.endTimeApprox = ch.t(end);
            ch.durationApprox = ch.t(end) - ch.t(1);
            

            %raw와 filtered 모두 cut하고 각자 저장함
            ch.raw = ch.originalSignal(timestampStart : timestampEnd);% raw
            ch.filtered = ch.originalSignal(timestampStart : timestampEnd);% filtered
                        
            %display info to the user
            fprintf("Reset all preprocessing of signals")
            fprintf("new startTime = %f\n", ch.startTime)
            fprintf("new endTime = %f\n", ch.endTimeApprox)
            fprintf("new duration = %f\n", ch.durationApprox)
            fprintf("new nTimestamp = %d\n", ch.nTimestamps)
        end % end of function cutTime

        %% 2. baseline filtering
        function filterBaseline(ch, baselineTimeIntervals, passBand)
            timeStampIntervals = ch.getMultipleIntervalTimestamps(baselineTimeIntervals);
            replacement = bandpass(ch.raw, passBand, ch.sf);
            ch.signalRawLowBaseline = ch.raw;
            ch.signalRawNoBaseline = ch.raw;
            for i = 1 : length(timeStampIntervals)
                intervalNow = timeStampIntervals{i};
                startStamp = intervalNow(1);
                endStamp = intervalNow(2);
                ch.signalRawLowBaseline(startStamp : endStamp) = replacement(startStamp : endStamp);
                ch.signalRawNoBaseline(startStamp : endStamp) = 0;
            end % end of for loop over timeStampIntervals
            ch.signalFilteredLowBaseline = ch.signalRawLowBaseline; %copy
            ch.signalFilteredNoBaseline = ch.signalRawNoBaseline; %copy
        end  % end of method filterBaseline      

        %% 3. signal filtering
        
        % bandpass filter
        function bandPass(ch, passBand)%(*)
            ch.filtered = bandpass(ch.filtered, passBand, ch.sf);
        end
        
        % butterworth high-pass filter
        function highPassButterworth(ch, order, cutoff)
            %cutoff of high-pass filter = lower bound
            Fn = (ch.sf/2); % Nyquist frequency
            ftype = "high";
            [b, a] = butter(order, cutoff/Fn, ftype);

            ch.filtered = filter(b,a,ch.filtered);
            ch.signalFilteredLowBaseline = filter(b,a,ch.signalFilteredLowBaseline);
            ch.signalFilteredNoBaseline = filter(b,a,ch.signalFilteredNoBaseline);
        
        end
        
        function notchButterworth(ch, order, notch)
            Fn = (ch.sf/2); % Nyquist frequency
            ftype = 'stop';
            [b, a] = butter(order, notch/Fn, ftype);

            ch.filtered = filter(b,a,ch.filtered); 
            ch.signalFilteredLowBaseline = filter(b,a,ch.signalFilteredLowBaseline);
            ch.signalFilteredNoBaseline = filter(b,a,ch.signalFilteredNoBaseline);
        end

        %% 4. rectify
        function rectify(ch)
            ch.rawRectified                       = abs(ch.raw);
            ch.filteredRectified                  = abs(ch.filtered);
            ch.signalRawLowBaselineRectified      = abs(ch.signalRawLowBaseline);
            ch.signalRawNoBaselineRectified       = abs(ch.signalRawNoBaseline);
            ch.signalFilteredLowBaselineRectified = abs(ch.signalFilteredLowBaseline);
            ch.signalFilteredNoBaselineRectified  = abs(ch.signalFilteredNoBaseline);
        end
        
        
        
        function envelope(ch, paramter, method)
            %enveloping
            [ch.rawEnveloped, lo]                       = envelope(ch.rawRectified, paramter, method);
            [ch.filteredEnveloped, lo]                  = envelope(ch.filteredRectified, paramter, method);
            [ch.signalRawLowBaselineEnveloped, lo]      = envelope(ch.signalRawLowBaselineRectified, paramter, method);
            [ch.signalRawNoBaselineEnveloped, lo]       = envelope(ch.signalRawNoBaselineRectified, paramter, method);
            [ch.signalFilteredLowBaselineEnveloped, lo] = envelope(ch.signalFilteredLowBaselineRectified, paramter, method);
            [ch.signalFilteredNoBaselineEnveloped, lo]  = envelope(ch.signalFilteredNoBaselineRectified, paramter, method);
                                 
            %maxs   
            ch.rawEnvelopedMax                       = max(ch.rawEnveloped);
            ch.filteredEnvelopedMax                  = max(ch.filteredEnveloped);
            ch.signalRawLowBaselineEnvelopedMax      = max(ch.signalRawLowBaselineEnveloped);
            ch.signalRawNoBaselineEnvelopedMax       = max(ch.signalRawNoBaselineEnveloped);
            ch.signalFilteredLowBaselineEnvelopedMax = max(ch.signalFilteredLowBaselineEnveloped);
            ch.signalFilteredNoBaselineEnvelopedMax  = max(ch.signalFilteredNoBaselineEnveloped);
        end
        
        
        %% baseline

        function [timestampStart, timestampEnd] = getIntervalTimestamps(ch, timeInterval)
            startTime = timeInterval(1);
            endTime = timeInterval(2);
            
            % deal with edge cases
            if startTime < ch.startTime
                fprintf("Start time is earlier than the channel's first timestamp")
                return
            end
            
            if endTime > ch.endTimeApprox
                fprintf("End time is later than the channel's last timestamp")
                return 
            end
            
            startDiff = startTime - ch.startTime;
            timestampStart = floor( (startDiff / (ch.msPerTs/1000) )) + 1;
            
            endDiff = ch.endTimeApprox - endTime;
            timestampEnd = length(ch.t) - floor( (endDiff / (ch.msPerTs/1000)) );
        end

        function timeStampIntervals = getMultipleIntervalTimestamps(ch, baselineTimeIntervals)
            timeStampIntervals = {};
            for i = 1 : length(baselineTimeIntervals)
                timeInterval = baselineTimeIntervals{i};
                [timestampStart, timestampEnd] = ch.getIntervalTimestamps(timeInterval);
                timeStampIntervals{i} = [timestampStart, timestampEnd];
            end
        end %end of method getIntervalTimestamps

        function timeStampIntervalsConcat = getIntervalTimestampsConcat(ch, timeIntervals)
            intervalsTimestamp = ch.getMultipleIntervalTimestamps(timeIntervals);
            
            firtInterval = intervalsTimestamp{1};

            timeStampIntervalsConcat = firtInterval(1):firtInterval(2);
            
            for i = 2:length(intervalsTimestamp)
                intervalNow = intervalsTimestamp{i};
                timeStampsNow = intervalNow(1) : intervalNow(2);
                timeStampIntervalsConcat = [timeStampIntervalsConcat, timeStampsNow];
            end
        end


     %% summary statistics
     function meanRMSValue = meanRMS(ch, timeIntervals)
         originalSignal = ch.originalSignal;
         timeStampIntervals = ch.getMultipleIntervalTimestamps(timeIntervals);
         for i = 1 : length(timeStampIntervals)
             intervalNow = timeStampIntervals{i};
             startStamp = intervalNow(1);
             endStamp = intervalNow(2);
             originalSignal(startStamp : endStamp) = 0;
         end
         meanRMSValue = mean(abs(originalSignal));
     end %end of method meanRMSValue

     function [pSignal, pNoise] = SNRValue(ch, signalIntervals, noiseIntervals)
         originalSignal = ch.originalSignal;

         timeStampSignal = ch.getIntervalTimestampsConcat(signalIntervals);
         timeStampNoise  = ch.getIntervalTimestampsConcat(noiseIntervals);
         
         pSignal = rms(originalSignal(timeStampSignal));
         pNoise  = rms(originalSignal(timeStampNoise));
     end %end of method SNRValue
        

     


            %%
        function count = detectSpikes(ch, thres, preTime, postTime)
            % from CyborgBrainOrg.m
            
            %주의:threshold에 minus가 붙어 있음, 즉 이 알고리즘은 local minimum을 찾는 알고리즘 
            threshold = -thres.*median(abs(ch.filtered)/0.6745); % 표준편차를 근사하는 공식. outlier에 덜 민감
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

        function [average_amp, amp_list] = getMeanSpikeAmplitude(ch)
            cmsa_instance = calculaterMeanSpikeAmplitude(ch);

         
            [average_amp, amp_list] = cmsa_instance.get_average_amp();
            end
       


        
        function detectSpikesPositive(ch, thres, preTime, postTime)
            % from CyborgBrainOrg.m
            
            %주의:threshold에 plus가 붙어 있음, 즉 이 알고리즘은 local maximum을 찾는 알고리즘 
            threshold = thres.*median(abs(ch.filtered)/0.6745); %% 바꾼 부분 % 표준편차를 근사하는 공식. outlier에 덜 민감
            ch.timestampsPrePeak = ceil(preTime * (ch.sf/1000)); % 발견된 spike peak 앞쪽으로 몇 timestamp만큼의 waveform을 저장해야 하는지 계산 
            ch.timestampsPostPeak = ceil(postTime * (ch.sf/1000)); %발견된 spike peak 뒷쪽으로 몇 timestamp만큼의 waveform을 저장해야 하는지 계산 
            ch.spikeTimestamps = []; % spike가 발견된 timestamp를 저장할 1d array
            ch.spikeWaveforms = []; % 앞에서 계산한 길이로 spike 앞뒤를 잘라 얻은 waveform을 각 row에 저장할 nd array
            
            % spike detection 수행 
            ii = ch.timestampsPrePeak + 1;
            count = 0;
            while ii < ch.nTimestamps
                tmp = ch.filtered(ii);
                if tmp > threshold %%바꾼 부분
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
        end %end of detectSpikesPositive

        function getPCScores(ch)
        % from CyborgBrainOrg.m
        % Inputs:
        % None
        %-------
        % Outputs: 
        % --------
        % PCScores : matlab 2d array (num_spikes x PCs)
            

            waveformZ = zscore(ch.spikeWaveforms); %standard scaling
            [~,score,~,~,explained] = pca(waveformZ); % waveform들에 PCA 적용 
            ch.PCScores = score(:,1:2); % pick first two PC scores
            ch.explainedVar = explained; % PC의 분산 설명량 저장
        end
        
        function getKmeansClusters(ch, clusternum, seednum)
        % from CyborgBrainOrg.m

            rng(seednum); % 시드 넘버 설정
            [clusters, centroid] = kmeans(ch.PCScores, clusternum);%주어진 cluster개수로 kmeans 실행 
            ch.clusters = clusters; %클러스터 membership 저장
            ch.nClusters = clusternum; %클러스터 개수 저장 

            % 클러스터당 spike 개수
            ch.nSpikesPerCluster = zeros([ch.nClusters,1]);
            for ii = 1 : length(ch.clusters)
                for c = 1 : ch.nClusters
                    if ch.clusters(ii) == c
                        ch.nSpikesPerCluster(c) = ch.nSpikesPerCluster(c) + 1;
                        ch.spikeTimestampsMatrix(c, ch.nSpikesPerCluster(c)) = ch.spikeTimestamps(ii);
                    end
                end
            end
            
            % 클러스터별 spike 개수를 사용자에게 출력해 주기
            disp("number of spikes per cluster:")
            for clusterNum = 1 : length(ch.nSpikesPerCluster)
                fprintf("cluaster %d: %d \n", clusterNum, ch.nSpikesPerCluster(clusterNum))
            end
            
            
            ch.calculateClusterMeanSpikes() %클러스터별로 meanSpike, S.D. 계산
            
            %클러스터별로 InterSpike Intervals 계산. 각 클러스터별로 spike가 두 개 이상이어야 함
            if sum(ch.nSpikesPerCluster<=1) == 0
                ch.calculateISI()
            else
                disp("mean spike와 sd는 계산되었으나, spike가 한 개 이하인 클러스터가 존재하므로 클러스터별 ISI를 계산할 수 없습니다. ISI를 계산하려면 seed number를 다르게 하거나, 클러스터 개수를 다르게 해야 합니다.")
            end
            
        end % end of getKmeansClusters
        
        % 2022.03.09
        function [isolation_distance, l_ratio] = mahalanobis_metrics(ch, this_unit_id)
        
        % Calculates isolation distance and L-ratio (metrics computed from Mahalanobis distance)
        % Based on metrics described in Schmitzer-Torbert et al. (2005) Neurosci 131: 1-11
        % Inputs:
        %-------
        % ch.PCScores : 2D array of PCs for all spikes (num_spikes x PCs) 
        % ch.clusters : 1D array of cluster labels for all spikes (num_spikes x 0)
        % this_unit_id : number corresponding to unit for which these metrics will be calculated (int)
    

            pcs_for_this_unit = ch.PCScores(ch.clusters == this_unit_id,:);
            pcs_for_other_units = ch.PCScores(ch.clusters ~= this_unit_id, :);
            n_this_unit = size(pcs_for_this_unit, 1);
            n_others = size(pcs_for_other_units, 1);
    
            mahalanobis_other = sort(mahal(pcs_for_other_units, pcs_for_this_unit));

     
            if min(n_this_unit, n_others) >= 2
                fprintf("Number of spikes: %i (cluster %i), %i (the others)\n", n_this_unit, this_unit_id, n_others)
                dof = size(pcs_for_this_unit, 2); % number of features              
                l_ratio = sum( chi2cdf( power(mahalanobis_other,2),dof,'upper')) / n_this_unit;
                % normalize by size of cluster, not number of other spikes
                
                if n_this_unit <= n_others
                    isolation_distance = power(mahalanobis_other(n_this_unit),2);
                else
                    fprintf("thus isolation distance not defined.\n")
                    isolation_distance = nan;
                end
            else
                fprintf("Number of spikes < 2, thus metrics not defined")
                l_ratio = nan;
                isolation_distance = nan;
            end
            fprintf("isolation distance of the cluster %i: %f \n", this_unit_id, isolation_distance)
            fprintf("L_ratio of the cluster %i: %f \n", this_unit_id, l_ratio)

            end % end of function

        %


    % drawing functions  
        function calculateTotalMeanSpikes(ch)
            %통합 mean spike
            tRangeCentered = (-ch.timestampsPrePeak : ch.timestampsPostPeak) * ch.msPerTs; %각 waveform의 t range. spike위치가 0이 되게 centering되어 있고, milisecond 단위로 변환 
            
        
            
            %meanSpike를 정의 
            if ch.nSpikes > 1 % 전체 spike 개수가 2개 이상이면 
                meanSpike = mean(ch.spikeWaveforms); %모든 spike의 waveform을 평균한 것이 meanSpike
                else %전체 spike 개수가 1개 뿐이면 
                    meanSpike = ch.spikeWaveforms;% 굳이  mean을 계산할 필요 없이 그 spike가 곧 meanSpike
                end
            stdSpikes = std(ch.spikeWaveforms);
            ch.totalMeanSpikeStruct.nSpikes  = ch.nSpikes; % cluster 내 spike 개수 저장 
            ch.totalMeanSpikeStruct.meanSpike = meanSpike; % meanSpike waveform 저장 
            ch.totalMeanSpikeStruct.std = stdSpikes;% standard deviation 저장 
            ch.totalMeanSpikeStruct.tRangeCentered = tRangeCentered; %waveform의 t range 저장 
        end %end of calculateTotalMeanSpikes
        
        function calculateClusterMeanSpikes(ch)
            % from CyborgBrainOrg.m
            % for each cluster, calculate average waveform, and S.D.;
          
            tRangeCentered = (-ch.timestampsPrePeak : ch.timestampsPostPeak) * ch.msPerTs; %각 waveform의 t range. spike위치가 0이 되게 centering되어 있고, milisecond 단위로 변환 
           
            
            for c = 1 : ch.nClusters %각 클러스터마다 반복 
                nSpikesNow = sum(ch.clusters == c);% 클러스터 내 spike 개수 저장 
                spikesNow = ch.spikeWaveforms((ch.clusters == c),:); %현 cluster 내 spike waveform만 모은 행렬 
                stdSpikes = std(ch.spikeWaveforms((ch.clusters == c),:));% 표준편차 계산
                
                %meanSpike를 정의 
                if nSpikesNow > 1 % 클러스터 내에 spike 개수가 2개 이상이면 
                    meanSpike = mean(spikesNow); %모든 spike의 waveform을 평균한 것이 meanSpike
                else %클러스터 내에 spike 개수가 1개 뿐이면 
                    meanSpike = spikesNow;% 굳이  mean을 계산할 필요 없이 그 spike가 곧 meanSpike
                end

                % 구조체에 클러스터별 데이터 저장장
                ch.meanSpikesStruct(c).nSpikes  = nSpikesNow; % cluster 내 spike 개수 저장 
                ch.meanSpikesStruct(c).meanSpike = meanSpike; % meanSpike waveform 저장 
                ch.meanSpikesStruct(c).std = stdSpikes;% standard deviation 저장 
                ch.meanSpikesStruct(c).tRangeCentered = tRangeCentered; %waveform의 t range 저장 
            end
        end % end of calculateClusterMeanSpikes
        
        function [meanSpikeWaveform, std, tRangeCentered, nSpikes] = getTotalMeanSpike(ch)
            meanSpikeWaveform = ch.totalMeanSpikeStruct.meanSpike;
            std = ch.totalMeanSpikeStruct.std;
            tRangeCentered = ch.totalMeanSpikeStruct.tRangeCentered;
            nSpikes = ch.totalMeanSpikeStruct.nSpikes;      
        end %end of getTotalMeanSpike
        
        function [meanSpikeWaveform, std, tRangeCentered, nSpikes] = getClusterMeanSpike(ch, clusterNum)
            meanSpikeWaveform = ch.meanSpikesStruct(clusterNum).meanSpike;
            std = ch.meanSpikesStruct(clusterNum).std;
            tRangeCentered = ch.meanSpikesStruct(clusterNum).tRangeCentered;
            nSpikes = ch.meanSpikesStruct(clusterNum).nSpikes;
        end %end of getClusterMeanSpike
        
 

        function drawRaster(ch, color)
            drawer_raster_instance = drawer_raster();
            drawer_raster_instance.drawRaster(ch, color);
        end

        
        function drawColoredRaster(ch, clusterColors)
            % from CyborgBrainOrg.m
                        
            for ii = 1 : length(ch.clusters)
                if ch.clusters(ii) == 1
                    clusterNum = ch.clusters(ii);
                    spikeTimestampTuple = ch.startTime + [ch.spikeTimestamps(ii), ch.spikeTimestamps(ii)]/ch.sf;
                    plot(spikeTimestampTuple,[-1,1], clusterColors(clusterNum));
                    hold on
                elseif ch.clusters(ii) == 2
                    clusterNum = ch.clusters(ii);
                    spikeTimestampTuple = ch.startTime + [ch.spikeTimestamps(ii), ch.spikeTimestamps(ii)]/ch.sf;
                    plot(spikeTimestampTuple,[-1,1], clusterColors(clusterNum));
                    hold on
                elseif ch.clusters(ii) == 3
                    clusterNum = ch.clusters(ii);
                    spikeTimestampTuple = ch.startTime + [ch.spikeTimestamps(ii), ch.spikeTimestamps(ii)]/ch.sf;
                    plot(spikeTimestampTuple,[-1,1], clusterColors(clusterNum));
                    hold on
                elseif ch.clusters(ii) == 4
                    clusterNum = ch.clusters(ii);
                    spikeTimestampTuple = ch.startTime + [ch.spikeTimestamps(ii), ch.spikeTimestamps(ii)]/ch.sf;
                    plot(spikeTimestampTuple,[-1,1], clusterColors(clusterNum));
                    hold on
                elseif ch.clusters(ii) == 5
                    clusterNum = ch.clusters(ii);
                    spikeTimestampTuple = ch.startTime + [ch.spikeTimestamps(ii), ch.spikeTimestamps(ii)]/ch.sf;
                    plot(spikeTimestampTuple,[-1,1], clusterColors(clusterNum));
                    hold on
                end
            end
            ylim([-2,2]);
            hold off
        end % drawColoredRaster
        
        function ISIbeforePCA = getISIvaluesBeforePCA(ch)
            ch.ISIbeforePCA = diff(ch.spikeTimestamps);
            ISIbeforePCA = ch.ISIbeforePCA * ch.msPerTs;
          
        end % end of getISIvaluesBeforePCA
        
        function calculateISI(ch)
            % from CyborgBrainOrg.m

            %calculate ISI
            for c = 1 : ch.nClusters
                for j = 2 : ch.nSpikesPerCluster(c)
                    if ch.spikeTimestampsMatrix(c, j) > 0
                        ch.ISI(c,j) = ch.spikeTimestampsMatrix(c, j) - ch.spikeTimestampsMatrix(c, j - 1);
                    end  
                end
            end
            
            ch.ISI(:, 1) = [];
            
            
            %클러스터별 ISI 값을 구조체(struct)에 저장
            for c = 1 : ch.nClusters %cluster 1부터 마지막 cluster까지 반복. c가 클러스터 번호
                ch.ISIStruct(c).values = ch.ISI(c, 1 : ch.nSpikesPerCluster(c) - 1) * ch.msPerTs; %timestamp 단위를 milisecond 단위로 변환 
                ch.ISIStruct(c).clusterNum = c;%클러스터 번호 저장 
                ch.ISIStruct(c).nSpikes = ch.nSpikesPerCluster(c);% 클러스터 내 spike 개수 저장
            end
        end % end of calculateISI
        
        function [ISIvalues, nSpikes] = getISIvalues(ch, clusterNum)
            ISIvalues = ch.ISIStruct(clusterNum).values;
            nSpikes = ch.ISIStruct(clusterNum).nSpikes;  
        end %end of getISIvalues
        
        function bursts = detectBurstsMI(ch, begISI, endISI, minSpikes, minDurn, minIBI)
            % input:
            % - one spike train
            % - begISI : maximum interval to start burst; max ISI at start of burst; Beginning inter spike interval
            % - endISI : maximum interval to end burst; max ISI in burst; Ending inter spike interval
            % - minIBI: minimum interval between bursts (threshold for combining bursts)
            % - minDurn: minimum duration of a burst; minimum duration to consider as burst
            % - minSpikes: minimum number of spikes in burst; minimum number of spikes to consider as burst
            
            % output: bursts found using max interval method.          
            
            msPerTs = ch.msPerTs;
            nspikes = ch.nSpikes;
            spikes = ch.spikeTimestamps;
            spikes = spikes * msPerTs;
                      
            % Create a temp array for the storage of the bursts.  
            % Assume that it will not be longer than Nspikes/2
            % since we need at least two spikes to be in a burst.
            maxBursts = floor(nspikes/2);
            bursts = NaN(maxBursts, 3);
            bursts = array2table(bursts, 'VariableNames',{'beg','end','IBI'});
            
            noBursts = []; %value to return if no bursts found.
            burst = 0; % current burst number
            
              
            %Start of the main algorithm  
            % Phase 1 -- burst detection.
            % 
            % parameters used: begISI, endISI
            %
            % when two consecutive spikes have an ISI *less* than begISI apart.
            % i.e. if nextISI < begISI,
            % a burst is defined as starting.
            %
            % The end of the burst is given  
            % when two spikes have an ISI *greater* than endISI,
            % i.e. if nextISI > endISI.
              
              
            % in short, we find ISIs closer than begISI, and end with endISI.
            
            
            % lastEnd is the time of the last spike in the previous burst.
            % This is used to calculate the IBI.
            % For the first burst, this is no previous IBI
            lastEnd = NaN;                        %for first burst, there is no IBI.
            
            n = 2;
            isInBurst = false;
              
            while n <= nspikes 
                nextISI = spikes(n) - spikes(n-1);
                
                if isInBurst 
                  % end of burst
                    if nextISI > endISI
                        endStamp = n - 1;
                        isInBurst = false;
                        ibi =  spikes(beg) - lastEnd;
                        lastEnd = spikes(endStamp);
                        res = [beg, endStamp, ibi];
                        burst = burst + 1;
            
                        % fail case
                        if burst > maxBursts
                            print("too many bursts!!! algorithm failed.")
                        return
                        end %end of {if burst > maxBursts}
                    
                        bursts(burst, : ) = array2table(res);
                    end % end of {nextISI > endISI}     
                else % else of {if isInBurst}, i.e. not yet in burst
                  
                    % Found the start of a new burst.
                    if nextISI < begISI  
                        beg = n - 1;
                        isInBurst = true;
                    end % end of {nextISI < begISI}
                end % end of {if isInBurst}
                n = n + 1;
            end %end of while n <= nspikes
            
            %phase 1.1. At the end of the burst, check if we were in a burst when the train finished.
            if isInBurst
                endStamp = nspikes;
                ibi =  spikes(beg) - lastEnd;
                res = [beg, endStamp, ibi];
                burst = burst + 1;
            
                % fail case
                if burst > maxBursts
                    print("too many bursts!!! algorithm failed.")
                    return
                end % end of if burst > maxBursts
            
                bursts(burst , :) = array2table(res);
            end % end of if isInBurst
            
            %phase 1.2. Check if any bursts were found.
            if burst > 0 
                % truncate to right length, as bursts will typically be very long.
                % (since we initated bursts with nrow = maxBursts)
                bursts = bursts(1:burst, :);
            else
                %% no bursts were found, so return an empty structure.
                print("no bursts were found. algorithm failed.")
                return
            end %end of {burst > 0} 
            
            %print results
            nBurstsPhase1 = size(bursts);
            nBurstsPhase1 = nBurstsPhase1(1);
            fprintf("phase 1 result: found %d bursts, using parameters begISI and endISI\n\n", nBurstsPhase1)
            %bursts
            
            
            
            
              
            % Phase 2 -- merging of bursts.
            %
            % parameters used : minIBI
            %
            % Here we see if any pair of bursts have an IBI *less* than minIBI; 
            % if so, we then merge the bursts.
            % We specifically need to check when say three bursts are merged into one.
              
            ibis = bursts(: ,'IBI');
            ibis = table2array(ibis);
            isMergeNeeded = ibis < minIBI;
            isAnyMergeNeeded = logical(sum(isMergeNeeded));
            if isAnyMergeNeeded
            % Merge bursts efficiently.
            % Work backwards through the list, 
            % and then delete the merged lines afterwards.  
            % This works when we have say 3+ consecutive bursts that merge into one.
                mergeIndex = find(isMergeNeeded);
                mergeIndexRev = flip(mergeIndex)
            
                for j = mergeIndexRev
                    burst = mergeIndexRev(j);
                    bursts(burst-1, "end") = bursts(burst, "end") %move the information one step forward.
                    bursts(burst  , "end") = NaN         %not needed, but helpful.
                end %end or for loop
            
                bursts = bursts(not(isMergeNeeded) , : ) % delete the unwanted info.
            end % end of {sum(mergeBursts) > 1}
            
            nBurstsPhase2 = size(bursts);
            nBurstsPhase2 = nBurstsPhase2(1);
            fprintf("phase 2 result: after merging by minIBI, %d bursts left\n\n", nBurstsPhase2)
            % bursts
            
            
            
            
            
            
            
            % Phase 3 -- remove small bursts
            %
            % parameters used : minDurn, minSpikes
            % 
            % delete small bursts i.e.
            % less than min duration (minDurn), or
            % having too few spikes (less than minSpikes).
            % In this phase we have the possibility of deleting all spikes.
            
            % LEN = number of spikes in a burst.
            % DURN = duration of burst.
            
            bursts = table2array(bursts);
            len = bursts(: , 2) - bursts(: , 1) + 1; %end, beg
            durn = spikes(bursts(: , 2)) - spikes(bursts(: , 1)); %end, beg
            bursts = [bursts, len, durn'];
            bursts = array2table(bursts, 'VariableNames',{'beg','end','IBI', 'len', 'durn'});
            
            IsReject = ((durn' < minDurn) | ( len < minSpikes));
            isAnyRejects = logical(sum(IsReject));

            fprintf("phase 3 result: %d bursts were removed whose duration is less than %d milisecond or have spikes less than %d ", sum(IsReject), minDurn, minSpikes)
            rejectsIndex = find(IsReject);
            
            % delete small bursts
            if isAnyRejects
                bursts = bursts(not(IsReject) , : );
            end % end of if isAnyRejects
              
              
            nBursts = size(bursts);
            nBursts = nBursts(1);
            if nBursts == 0 % if all the bursts were removed during phase 3.
                bursts = noBursts;
            else % else of {nBursts == 0}
                % Compute mean ISIS
                bursts = table2array(bursts);
                len = bursts(: , 2) - bursts(: , 1) + 1; %end, beg
                durn = spikes( bursts(: , 2) ) - spikes( bursts(: , 1) ); %end, beg
                meanISI = durn' ./ (len-1);
            
                % Recompute IBI (only needed if phase 3 deleted some cells).
                if nBursts > 1 
                    ibiBeg = spikes( bursts(: , 1) ); %beg
                    ibiBeg = ibiBeg(2:nBursts);
                    ibiEnd = spikes( bursts(: , 2) ); %end
                    ibiEnd = ibiEnd(1:(nBursts-1));
            
                    ibi2 = ibiBeg - ibiEnd;
                    ibi2 = [NaN; ibi2'];
                else
                    ibi2 = NaN;
                end
                bursts(: ,3) = ibi2; %IBI
               
                           
                bursts = [bursts, meanISI];
                bursts = array2table(bursts, 'VariableNames',{'beg','end','IBI', 'nSpikes', 'durn', 'meanISI'});
                end %end of {if nBursts == 0}
                ch.bursts = bursts;
            end %end of the function   
    
   
%%%% phase analysis per frequency band
% 1. getBand
% 2. saveCircularBand

function [bandWaveOut, bandPhaseOut] = getBand(ch, frequencyRange)
        % added 2023.06.06
        % slightly modified the function getThetas
        % for the request "LFP-SU joint analysis"
        % input: 
        % 1. freqBand: array of two numbers e.g. [4, 8]
        % - frequency band used for bandpass filter
        %
        % output:
        % 1. bandWave: 1d array.
        % - filtered voltage
        % 2. bandPhase: 1d array.
        % - filtered phase
            ch.bandWave = bandpass(ch.raw, frequencyRange, ch.sf); %uses the raw signal, so the function do not applies iteratively.
            analytic_signal = hilbert(ch.bandWave); % Hilbert transform하여 복소수 형태로 표현 
            ch.bandAmplitude = abs(analytic_signal);
            ch.bandPhase = angle(analytic_signal); % 실수부와 허수부 사이 각을 계산
            ch.spikeBandAngles = ch.bandPhase(ch.spikeTimestamps); %spike 발생 시점의 angle을 저장
            ch.saveCircularBand() %cluster별로 나누어 phase 값을 저장

            %output
            bandWaveOut = ch.bandWave;
            bandPhaseOut = ch.bandPhase;
        end %end of function getBand

        function saveCircularBand(ch)%(*)
            for c = 1 : ch.nClusters
                ch.phaseStruct(c).values = ch.spikeBandAngles(ch.clusters == c); %timestamp 단위를 milisecond 단위로 변환 
                ch.phaseStruct(c).clusterNum = c;%클러스터 번호 저장 
                ch.phaseStruct(c).nSpikes = ch.nSpikesPerCluster(c);% 클러스터 내 spike 개수 저장 
            end
        end % saveCircularBand

        function [phaseValues, nSpikes] = getBandPhaseByClusterNum(ch, clusterNum)%(*)
            %주어진 clusterNum에 해당하는 클러스터의 theta phase 값을 가져오는 함수. 히스토그램 그릴 때
            %쓰는 데이터를 얻기 위해 사용
           phaseValues = ch.phaseStruct(clusterNum).values;
           nSpikes = ch.phaseStruct(clusterNum).nSpikes;
        end % end of getBandPhaseByClusterNum

        function uniformTest(ch)
            pvals = zeros([ch.nClusters,1]);
            for c = 1 : ch.nClusters
                angles = ch.spikeBandAngles(ch.clusters == c);
                [pval, z] = circ_rtest(angles);
                pvals(c) = pval;
            end
            pvals
        end
            
        


        
        %% for test purpose
        function shuffle(ch, nfold)
        % add random noise to the raw signal to imitate 
            nSample = length(ch.raw);
            nSamplePerFold = fix(nSample / nfold);
            nSampleRemain= rem(nSample, nfold);
            
            fold_index = {};
            for i = 1 : nfold
                fold_index{i} = ((i-1) * nSamplePerFold + 1) : (i * nSamplePerFold);
            end

            p = randperm(nfold);
            for i = 1 : nfold
                random_integer = p(i);
                raw_index = fold_index{i};
                random_index = fold_index{random_integer};
                ch.raw(raw_index) = ch.raw(random_index);
            end
            ch.filtered = ch.raw;
           
        end


    end %methods
end %class
