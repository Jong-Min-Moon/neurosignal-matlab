classdef channel < handle
    properties
        sf
        msPerTs
        nTimestamps
        t
        raw
        filtered
        timestampsPrePeak
        timestampsPostPeak
        spikeTimestamps
        spikeWaveforms
        PCScores
        clusters
        thetaWaves
        thetaPhases
    end
    
    methods
        function ch = channel(filename)
            data = readmatrix(filename);
            
            % 1. Convert data into a single 1d array
            % 1.1. calculate time interval of each bin(which contains 256 observations)
            binTimeStart = data(:,5); %assuming that 'time' means starting time.
            binTimeInterval = diff(binTimeStart);
            binTimeInterval(end + 1) = binTimeInterval(end);

            % 1.2. x varaible into a single 1d array
            x = data(:,6:end); % data in format of matrix of size nBin * 256 
            x = transpose(x);
            x = x(:); % collapse into 1d array, columnwisely

            % 1.3. time variable into a single 1d array
            tPercentileInsideBin = linspace(0,255/256,256);
            t = binTimeStart + binTimeInterval * tPercentileInsideBin;
            t = transpose(t);
            t = t(:);

            % 2. resample the signal using spline, to make uniform time interval
            msPerTimestamp = mean(binTimeInterval) * (1000/256); % milisecond per timestamp. stamp->ms conversion.
            desiredSamplingFrequency = 1000 * (1/msPerTimestamp); %approx. 3000hz. 1/10 of reference code 30000hz
            [xResampled, tResampled] = resample(x, t, desiredSamplingFrequency, 'spline');
        
            %3. initialize properties
            ch.sf = desiredSamplingFrequency;
            ch.msPerTs = msPerTimestamp;
            ch.t = tResampled;
            ch.raw = xResampled;
            ch.nTimestamps = length(tResampled);
        end
    
        function bandPass(ch, passBand)
            ch.filtered = bandpass(ch.raw, passBand, ch.sf);
        end

        function detectSpikes(ch, thres, preTime, postTime)
            threshold = -thres.*median(abs(ch.filtered)/0.6745); % approximate standard deviation, robust to outliers
            ch.timestampsPrePeak = ceil(preTime * (ch.sf/1000)); %reference code: 2ms * 30stamps/ms = 60stamps
            ch.timestampsPostPeak = ceil(postTime * (ch.sf/1000)); %reference code: 2ms * 30stamps/ms = 60stamps
            ch.spikeTimestamps = []; % 1d array to store the timestamp of spike occurrence.
            ch.spikeWaveforms = []; % nd array to store the waveform of spikes. Each row represents one waveform of spike.
            
            % spike detection
            ii = ch.timestampsPrePeak;
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
            % apply PCA to waveforms and pick first two PC scores
            waveformZ = zscore(ch.spikeWaveforms); %standardize
            [coeff,score,latent,tsquared,explained] = pca(waveformZ);
            ch.PCScores = score(:,1:2);
        end
        
        function getKmeansClusters(ch, clusternum)
            % apply k-means clustering of waveforms
            [clusters, centroid] = kmeans(ch.PCScores, clusternum);
            ch.clusters = clusters
        end        

        function getThetas(ch)
            %apply 4-8 Hz frequency band
            ch.thetaWaves = bandpass(ch.raw, [4, 8], ch.sf);
            
            %phase caculation through Hilbert transform
            xHilbert = hilbert(ch.thetaWaves);
            ch.thetaPhases = angle(xHilbert);       
        end
                
                
                
    end %methods
end %class
