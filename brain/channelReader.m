classdef channelReader < handle
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
        function chReader = channelReader()
        end
        
        function readWithoutTime(filename, organoidNum, channelNum, month)
            % time data가 없는 signal data를 불러오는 함수
            % retina project(Won Gi Chung)의 data1.csc와 동일한 포맷의 파일에서 필요한 정보를 뽑아내어 
            % channel_from_data 클래스 생성자에 넘겨주어 obejct를 생성
            data = readmatrix(filename);
            binTimeStart = data(:,5);
            x = data(:,6:end);
            ch = ch@channel_from_data(binTimeStart, x, organoidNum, channelNum, month );
            
        end   
            
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

    


 

    end %methods
end %class
