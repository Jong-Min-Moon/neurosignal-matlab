classdef channel_from_data < handle
    properties
        organoidNum
        channelNum
        month
        nObsPerRow
        sf
        msPerTs
        nTimestamps
        startTime
        t
        raw
        filtered
        timestampsPrePeak
        timestampsPostPeak
        spikeTimestamps
        spikeTimestampsMatrix
        spikeWaveforms
        PCScores
        explainedVar
        clusters
        nClusters
        nSpikesPerCluster
        ISI
        thetaWaves
        thetaPhases
        spikeThetaAngles
        clusterColors
    end
    
    methods
        function ch = channel_from_data(binTimeStart, x, organoidNum, channelNum, month)%(*)
            % binTimeStart: xlsx 파일의 3번째 column에 해당. 각 row의 첫 번째 observation이 기록된 시간으로 구성된 column
            % x: xlsx파일의 4번째 column부터 기록된 voltage data value
            % organoidNum, channelNum, month: 관리를 위한 index
            
    
            % 1. 1d array로 변환
            % 1.1. 각 row 간 time interval 계산
            ncol = size(x,2); %row당 observation 개수 저장
            ch.startTime = binTimeStart(1); % 최초 측정 시간 저장
            binTimeInterval = diff(binTimeStart); % 각 row간 time interval 계산
            binTimeInterval(end + 1) = binTimeInterval(end); %마지막 row에서는 interval 계산이 불가하므로 그 전 row 값을 사용 

            % 1.2. transpose 후 컬럼을 아래로 쭉 이어붙여 한줄로 만들기 
            x = transpose(x);
            x = x(:); %

            % 1.3. 각 row 내에서 ncol개의 데이터가 균등 시간 간격으로 측정되었다고 가정하고, 시간 array t를 생성 
            tPercentileInsideBin = linspace(0, (ncol-1)/ncol, ncol);
            t = binTimeStart + binTimeInterval * tPercentileInsideBin;
            t = transpose(t);
            t = t(:);

            % 2. t가 row별로 시간간격이 아주 약간 다른데, bandpass filter 적용을 위해 완전 균등간격으로
            % 바꾸고(resample) 이에 맞춰 voltage 측정값도 interpolate. spile을 사용. t값 변화가 거의 없으므로
            % voltage 그래프도 거의 변화가 없음
            msPerTimestamp = mean(binTimeInterval) * (1000/ncol); % milisecond per timestamp. timestamp->ms conversion.
            desiredSamplingFrequency = 1000 * (1/msPerTimestamp); % 데이터에서 계산한 sampling frequency 
            [xResampled, tResampled] = resample(x, t, desiredSamplingFrequency, 'spline'); %resample 및 interpolation 실행
        
            %3. 필요한 값 저장
            ch.organoidNum = organoidNum;
            ch.channelNum = channelNum;
            ch.month = month;
            ch.nObsPerRow = ncol;
            ch.sf = desiredSamplingFrequency;
            ch.msPerTs = msPerTimestamp;
            ch.t = tResampled;
            ch.raw = xResampled;
            ch.nTimestamps = length(tResampled);
            ch.clusterColors = ["red", "green", "blue", "magenta", "cyan", "yellow"]';
        end

    
        function bandPass(ch, passBand)%(*)
            ch.filtered = bandpass(ch.raw, passBand, ch.sf);
        end

        function detectSpikes(ch, thres, preTime, postTime)
            % from CyborgBrainOrg.m
            
            threshold = -thres.*median(abs(ch.filtered)/0.6745); % approximate standard deviation, robust to outliers
            ch.timestampsPrePeak = ceil(preTime * (ch.sf/1000)); %reference code: 2ms * 30stamps/ms = 60stamps
            ch.timestampsPostPeak = ceil(postTime * (ch.sf/1000)); %reference code: 2ms * 30stamps/ms = 60stamps
            ch.spikeTimestamps = []; % 1d array to store the timestamp of spike occurrence.
            ch.spikeWaveforms = []; % nd array to store the waveform of spikes. Each row represents one waveform of spike.
            
            % spike detection
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
        end %method detectSpikes

        function getPCScores(ch)
            % from CyborgBrainOrg.m

            % apply PCA to waveforms and pick first two PC scores
            waveformZ = zscore(ch.spikeWaveforms); %standard scaling
            
            [coeff,score,latent,tsquared,explained] = pca(waveformZ);
            ch.PCScores = score(:,1:2);
            ch.explainedVar = explained;
        end
        
        function getKmeansClusters(ch, clusternum, seednum)
            % from CyborgBrainOrg.m

            % apply k-means clustering of waveforms
            rng(seednum); % For reproducibility
            [clusters, centroid] = kmeans(ch.PCScores, clusternum);
            ch.clusters = clusters;
            ch.nClusters = clusternum;

            %count spikes in each cluster
            ch.nSpikesPerCluster = zeros([ch.nClusters,1]);
            for ii = 1 : length(ch.clusters)
                for c = 1 : ch.nClusters
                    if ch.clusters(ii) == c
                        ch.nSpikesPerCluster(c) = ch.nSpikesPerCluster(c) + 1;
                        ch.spikeTimestampsMatrix(c, ch.nSpikesPerCluster(c)) = ch.spikeTimestamps(ii);
                    end
                end
            end         
        end % getKmeansClusters
        
        function getThetas(ch)%(*)
            %apply 4-8 Hz frequency band
            ch.thetaWaves = bandpass(ch.raw, [4, 8], ch.sf);
            
            %phase caculation through Hilbert transform
            xHilbert = hilbert(ch.thetaWaves);
            ch.thetaPhases = angle(xHilbert);    
            
            %theta angles at spikes
            ch.spikeThetaAngles = ch.thetaPhases(ch.spikeTimestamps);
            
        end
        
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
        function p = drawRaw(ch, color)
            p = plot(ch.t, ch.raw);
            p.Color = color;
        end

        function drawMeanSpike(ch, color)
            % from CyborgBrainOrg.m

            %for each cluster, the average waveform, and the average waveform +/- 1 S.D.;
            x = (-ch.timestampsPrePeak : ch.timestampsPostPeak) * ch.msPerTs;
            x2 = [x, fliplr(x)];
            
            spikesNow = ch.spikeWaveforms;
            nSpikesNow = size(spikesNow,1);
            stdSpikes = std(spikesNow);
            if nSpikesNow > 1
                meanSpike = mean(spikesNow);
            else
                meanSpike = spikesNow;
            end
            
            curve1 = meanSpike - stdSpikes;
            curve2 = meanSpike + stdSpikes;
                 
            plot(x, curve1, 'k--', 'LineWidth', 1, 'Color', color);
            hold on;
            plot(x, curve2, 'k--', 'LineWidth', 1, 'Color', color);
            hold on;
                 
            %inBetween = [curve1, fliplr(curve2)];
            %fill(x2, inBetween, 'r');
                 
     
            axis tight   
            title('Mean spike(+-std), n = ' + string(nSpikesNow) );
            plot(x, meanSpike,'Linewidth',2,'Color','k');% add mean spike
        end % method drawMeanSpike      
        
        function drawPCA(ch)
            % from CyborgBrainOrg.m

            subplot(2,1,1)
            bar(ch.explainedVar);
            title("Explained variance by principal component");
            
            subplot(2,1,2)
            PC1 = ch.PCScores(:,1);
            PC2 = ch.PCScores(:,2);
            for c = 1 : ch.nClusters
                scatter(PC1((ch.clusters == c),:), PC2((ch.clusters == c),:) ,ch.clusterColors(c), 'filled')
                hold on;
                
            end
            legend(["cluster 1", "cluster 2", "cluster 3"])
   
            xlabel('First PC');
            ylabel('Second PC');
            title('Principal Component Scatter Plot with Colored Clusters');    
            legend("cluster " + string(1 : ch.nClusters));
        end

        function drawClusterMeanSpikes(ch)
            % from CyborgBrainOrg.m

            %for each cluster, the average waveform, and the average waveform +/- 1 S.D.;
            x = (-ch.timestampsPrePeak : ch.timestampsPostPeak) * ch.msPerTs;
            x2 = [x, fliplr(x)];

            %get meanSpikes
            meanSpikes = [];
            for ii = 1 : ch.nClusters
                nSpikesNow = sum(ch.clusters == ii);
                spikesNow = ch.spikeWaveforms((ch.clusters == ii),:);
                stdSpikes = std(ch.spikeWaveforms((ch.clusters == ii),:));
                if nSpikesNow > 1
                    meanSpike = mean(spikesNow);
                else
                    meanSpike = spikesNow;
                end
                meanSpikes = [meanSpikes; meanSpike];
            end
           
            %get ylim            
            
            maxes = max(meanSpikes');
            mins = min(meanSpikes');
            ylimForAll = [min(mins)*2, max(maxes)*2];
            
            
            for c = 1 : ch.nClusters
                nSpikesNow = sum(ch.clusters == c);
                spikesNow = ch.spikeWaveforms((ch.clusters == c),:);
                stdSpikes = std(ch.spikeWaveforms((ch.clusters == c),:));
                if nSpikesNow > 1
                    meanSpike = mean(spikesNow);
                else
                    meanSpike = spikesNow;
                end

                curve1 = meanSpike - stdSpikes;
                curve2 = meanSpike + stdSpikes;
                
                subplot(ch.nClusters, 1, c);
                plot(x, curve1, 'k--', 'LineWidth', 1, 'Color', ch.clusterColors(c));
                hold on;
                plot(x, curve2, 'k--', 'LineWidth', 1, 'Color', ch.clusterColors(c));
                hold on;
                
                %inBetween = [curve1, fliplr(curve2)];
                %fill(x2, inBetween, ch.clusterColors(c));
                
    
                axis tight   
                title('Mean spike(+-std) for group ' + string(c) + ', n = ' + string(nSpikesNow) );
                % add mean spike
                plot(x, meanSpike,'Linewidth',2,'Color','k');
                ylim(ylimForAll);%3개 클러스터의 축 통일
            end
            hold off;
        end % method drawClusterMeanSpikes

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
        
        function drawColoredRaster(ch)
            % from CyborgBrainOrg.m
                        
            for ii = 1 : length(ch.clusters)
                if ch.clusters(ii) == 1
                    spikeTimestampTuple = ch.startTime + [ch.spikeTimestamps(ii), ch.spikeTimestamps(ii)]/ch.sf;
                    plot(spikeTimestampTuple,[-1,1], ch.clusterColors(ch.clusters(ii)));
                    hold on
                elseif ch.clusters(ii) == 2
                    spikeTimestampTuple = ch.startTime + [ch.spikeTimestamps(ii), ch.spikeTimestamps(ii)]/ch.sf;
                    plot(spikeTimestampTuple,[-1,1], ch.clusterColors(ch.clusters(ii)));
                    hold on
                elseif ch.clusters(ii) == 3
                    spikeTimestampTuple = ch.startTime + [ch.spikeTimestamps(ii), ch.spikeTimestamps(ii)]/ch.sf;
                    plot(spikeTimestampTuple,[-1,1], ch.clusterColors(ch.clusters(ii)));
                    hold on
                elseif ch.clusters(ii) == 4
                    spikeTimestampTuple = ch.startTime + [ch.spikeTimestamps(ii), ch.spikeTimestamps(ii)]/ch.sf;
                    plot(spikeTimestampTuple,[-1,1], ch.clusterColors(ch.clusters(ii)));
                    hold on
                elseif ch.clusters(ii) == 5
                    spikeTimestampTuple = ch.startTime + [ch.spikeTimestamps(ii), ch.spikeTimestamps(ii)]/ch.sf;
                    plot(spikeTimestampTuple,[-1,1], ch.clusterColors(ch.clusters(ii)));
                    hold on
                end
            end
            ylim([-2,2]);
        end % drawColoredRaster

        function drawISI(ch)
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
            %draw ISI histograms
            for c = 1 : ch.nClusters 
                nSpikesNow = sum(ch.clusters == c);
                subplot(1, ch.nClusters, c);
                h = histogram(ch.ISI(c, 1 : ch.nSpikesPerCluster(c) - 1) * ch.msPerTs, 100);
                h.FaceColor = ch.clusterColors(c);
                title('cluster ' + string(c) + ', n = ' + string(nSpikesNow) );
                xlabel('ISI (ms)');
                hold on
            end
        end %drawISI

        function drawCircularTheta(ch)%(*)
            for c = 1 : ch.nClusters
                nSpikesNow = sum(ch.clusters == c);
                angles = ch.spikeThetaAngles(ch.clusters == c);
                subplot(1, ch.nClusters, c);
                circ_plot(angles,'hist',[],20,true,false,'linewidth',2,'color',ch.clusterColors(c));
                title('cluster ' + string(c) + ', n = ' + string(nSpikesNow) );
            end
        end % drawCircularTheta

        function drawThetaHist(ch)%(*)
            for c = 1 : ch.nClusters
                nSpikesNow = sum(ch.clusters == c);
                angles = ch.spikeThetaAngles(ch.clusters == c);
                subplot(1, ch.nClusters, c);
                h = histogram(angles,10);
                h.FaceColor = ch.clusterColors(c);
                xlim([-1.5 * 3.15,1.5*3.15]);
                
                title('cluster ' + string(c) + ', n = ' + string(nSpikesNow) );
            end
        end % drawCircularTheta
        
        function drawPhaseSpace(ch, color)%(*)
            averageWaveform = mean(ch.spikeWaveforms);
            dVdt = diff(averageWaveform)/ch.msPerTs;
            averageWaveform = averageWaveform - min(averageWaveform);     
            dVdt = dVdt - mean(dVdt);

            %draw
            V = averageWaveform(1:(end-1))
            hold on
            for i = 1: (length(dVdt)-1)
                p = plot([V(i), V(i+1)], [dVdt(i), dVdt(i+1)], 'k');
                p.Color = color;
            end
            hold off
        end %drawPhaseSpace

    end %methods
end %class
