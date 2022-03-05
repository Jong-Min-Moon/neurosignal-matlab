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
        thetaWaves
        thetaPhases
        spikeThetaAngles
        phaseStruct
        clusterColors

        bursts
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
            
            ch.t = t;
            ch.raw = x;
            ch.nTimestamps = length(t);
            
            ch.startTime = t(1);
            ch.endTimeApprox = t(end);
            ch.durationApprox = t(end) - t(1);
            
            ch.clusterColors = ["red", "green", "blue", "magenta", "cyan", "yellow"]';
        end

    
        function bandPass(ch, passBand)%(*)
            ch.filtered = bandpass(ch.raw, passBand, ch.sf);
        end

        function detectSpikes(ch, thres, preTime, postTime)
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
        
        function getThetas(ch)%(*)
            ch.thetaWaves = bandpass(ch.raw, [4, 8], ch.sf); %apply 4-8 Hz frequency band
            xHilbert = hilbert(ch.thetaWaves); % Hilbert transform하여 복소수 형태로 표현 
            ch.thetaPhases = angle(xHilbert); % 실수부와 허수부 사이 각을 계산 
            ch.spikeThetaAngles = ch.thetaPhases(ch.spikeTimestamps); %spike 발생 시점의 theta angle을 저장
            ch.saveCircularTheta() %cluster별로 나누어 theta phase 값을 저장
        end %end of getThetas
        
        function uniformTest(ch)
            pvals = zeros([ch.nClusters,1]);
            for c = 1 : ch.nClusters
                angles = ch.spikeThetaAngles(ch.clusters == c);
                [pval, z] = circ_rtest(angles);
                pvals(c) = pval;
            end
            pvals
        end


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
            % from CyborgBrainOrg.m

            for ii = 1:length(ch.spikeTimestamps)
                spikeTimestampTuple = ch.startTime + [ch.spikeTimestamps(ii), ch.spikeTimestamps(ii)]/ch.sf;
                p = plot(spikeTimestampTuple, [-1,1], 'k');
                p.Color = color;
                hold on
            end
            hold off
            ylim([-2, 2]);
            title('Raster plot');
            xlabel('time(s)');
            ylabel('Raster');
        end %drawRaster
        
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
            
            
        function saveCircularTheta(ch)%(*)
            for c = 1 : ch.nClusters
                ch.phaseStruct(c).values = ch.spikeThetaAngles(ch.clusters == c); %timestamp 단위를 milisecond 단위로 변환 
                ch.phaseStruct(c).clusterNum = c;%클러스터 번호 저장 
                ch.phaseStruct(c).nSpikes = ch.nSpikesPerCluster(c);% 클러스터 내 spike 개수 저장
 
            end
        end % saveCircularTheta
        

        function [phaseValues, nSpikes] = getThetaPhaseByClusterNum(ch, clusterNum)%(*)
            %주어진 clusterNum에 해당하는 클러스터의 theta phase 값을 가져오는 함수. 히스토그램 그릴 때
            %쓰는 데이터를 얻기 위해 사용
           phaseValues = ch.phaseStruct(clusterNum).values;
           nSpikes = ch.phaseStruct(clusterNum).nSpikes;
        end % end of getThetaPhaseByClusterNum
        
        

    end %methods
end %class
