classdef channelReader < handle
    properties
        massiveData
        massiveDataChannelRows
    end
    
    methods
        function chReader = channelReader()
        end
        
        
        function channelObject = readBrainSingleChannel(chReader, filename, organoidNum, channelNum, month)
            % MEA data.xlsx와 동일한 포맷의 파일에서 필요한 signal data를 불러오는 함수 
            x = readmatrix(filename);
            binTimeStart = x(:,5);  %시간을 나타내는 첫 번째 열을 따로 저장 
            x = x(:,6:end); %6번째 열부터 데이터로 저장 
            x = chReader.checkNanCol(x); %NaN column check
            [xVector, nObsPerRow] = chReader.vectorizeX(x);
            [tVector, sampleRate] = chReader.vectorizeT(binTimeStart, nObsPerRow, numel(xVector));
            [xResampled, tResampled] = resample(xVector, tVector, sampleRate, 'spline'); %resample 및 interpolation 실행

            
            channelObject = channel(xResampled, tResampled, sampleRate, organoidNum, channelNum, month); 
        end
        
        function readMultiChannelFile(chReader, filename)
            %1_singleunit wave.xlsx 또는 전체.xlsx 파일과 똑같은 포맷을 가정
            %80mb짜리 파일 기준으로 코어 i7 2.3GHz에서 데이터 로드에 1분 이상 소요
            data = readmatrix(filename, NumHeaderLines = 6);  %데이터가 *7*번째 줄부터 시작하므로, 위에서부터 *6*줄은 버리고 데이터 로드 
            channelRows = data(:,1);  %파일에 있는 채널 목록을 확인 

            chReader.massiveData = data;
            chReader.massiveDataChannelRows = channelRows;
        end
        
        
        function channelObject = readSingleChannelFromFile(chReader, organoidNum, channelNum, month)
            channelBoolean = chReader.massiveDataChannelRows == channelNum; %channel num에 해당하는 row만 골라냄 
            channelData = chReader.massiveData(channelBoolean,:); % 그 boolean을 datatset에 적용 

            binTimeStart = channelData(:,3); %시간변수 
            x = channelData(:, 4:end); % 관측값 
            
            x = chReader.checkNanCol(x); %NaN column check
            [xVector, nObsPerRow] = chReader.vectorizeX(x);
            [tVector, sampleRate] = chReader.vectorizeT(binTimeStart, nObsPerRow, numel(xVector));
            [xResampled, tResampled] = resample(xVector, tVector, sampleRate, 'spline'); %resample 및 interpolation 실행

            channelObject = channel(xResampled, tResampled, sampleRate, organoidNum, channelNum, month); 
        end % function readSingleChannelFromFile
        
        function channelObjects = readManyChannelsFromFile(chReader, organoidNum, channelNums, month)
            channelObjects = {};
            for channelNum = channelNums
                channelObjects{channelNum} = chReader.readSingleChannelFromFile(organoidNum, channelNum, month);
            end % for loop
            
        end % function readAllChannelsFromFile
        
        
        function channelObject = readRetinaWithTime(chReader, filename, organoidNum, channelNum, month)
            % time data가 없는 signal data를 불러오는 함수
            % retina project(Won Gi Chung)의 data1.csv와 동일한 포맷의 파일에서 필요한 정보를 뽑아내어 
            % channel_from_data 클래스 생성자에 넘겨주어 obejct를 생성
            x = readmatrix(filename, NumHeaderLines = 7);  %데이터가 8번째 줄부터 시작하므로, 위에서부터 7줄은 버리고 데이터 로드
            binTimeStart = x(:,1);  %시간을 나타내는 첫 번째 열을 따로 저장 
            x(:,1) = []; %시간 변수 지우고 측정값만 남김
            
            % Data 1.csv, Data 2.csv 모두 마지막 열 옆에 공백문자만으로 이루어진 열이 하나 더 있어서,
            % matalb에서 NaN으로 읽힘. 그것을 제거.
            x = chReader.checkNanCol(x);
            
            
            [xVector, nObsPerRow] = chReader.vectorizeX(x);
            [tVector, sampleRate] = chReader.vectorizeT(binTimeStart, nObsPerRow, numel(xVector));           
            [xResampled, tResampled] = resample(xVector, tVector, sampleRate, 'spline'); %resample 및 interpolation 실행
          
            channelObject = channel(xResampled, tResampled, sampleRate, organoidNum, channelNum, month);    
        end  % end of readRetinaWithTime
        
        
        function channelObject = readRetinaWithoutTime(chReader, filename, sampleRate, organoidNum, channelNum, month)
            % time data가 없는 signal data를 불러오는 함수
            % retina project(Won Gi Chung)의 data1.csv와 동일한 포맷의 파일에서 필요한 정보를 뽑아내어 
            % channel_from_data 클래스 생성자에 넘겨주어 obejct를 생성
            x = readmatrix(filename, NumHeaderLines = 7);  %데이터가 *8*번째 줄부터 시작하므로, 위에서부터 *7*줄은 버리고 데이터 로드
            
            % Data 1.csv, Data 2.csv 모두 마지막 열 옆에 공백문자만으로 이루어진 열이 하나 더 있어서,
            % matalb에서 NaNd으로 읽힘. 그것을 제거.
            x = chReader.checkNanCol(x);
                        
            [xVector, ~] = chReader.vectorizeX(x);
            tVector = chReader.makeTimeVariable(numel(xVector), sampleRate);
          
            channelObject = channel(xVector, tVector, sampleRate, organoidNum, channelNum, month);    
        end % end of readRetinaWithoutTime
        
              
        function t = makeTimeVariable(chReader, nTotalObs, sampleRate)
            tDuration = (nTotalObs / sampleRate); %첫 측정치 timepoint에서 마지막 측정치 timepoint까지의 time interval
            lastObervationTimepoint = tDuration - 1/sampleRate;
            t = linspace(0, lastObervationTimepoint, nTotalObs); % 위 두 값을 기반으로 시간 변수 생성
        end % end of makeTimeVariable
        
        
        function [tVector, sf] = vectorizeT(chreader, binTimeStart, nObsPerRow, nx)
            tVector = zeros(1, nx);
            
            binTimeInterval = diff(binTimeStart); % 각 row간 time interval 계산
            binTimeInterval(end + 1) = binTimeInterval(end); %마지막 row에서는 interval 계산이 불가하므로 그 전 row 값을 사용 
            
            % 각 row 내에서 데이터가 균등 시간 간격으로 측정되었다고 가정하고, 시간 array t를 생성
            % 관측치가 적은 row를 탐지하고 NaN을 제거했기 때문에, t를 만들 때도 행별로 해야 함.
            startPoint = 1;
            endPoint = 0;
            for r = 1:length(nObsPerRow)
                nObs = nObsPerRow(r);
                tPercentileInsideBin = linspace(0, (nObs - 1) / nObs, nObs);
                cleanT = binTimeStart(r) + binTimeInterval(r) * tPercentileInsideBin;
                
                endPoint = endPoint + length(cleanT);
                startPoint = endPoint - length(cleanT) + 1;
                
                tVector(startPoint : endPoint) = cleanT;
            end
            msPerTimestamp = mean(binTimeInterval' ./ nObsPerRow); % milisecond per timestamp. timestamp->ms conversion.
            sf = 1 / msPerTimestamp; % 데이터에서 계산한 sampling frequency 
        end %end of vectorizeT
        
        function [xVector, nObsPerRow] = vectorizeX(chReader, x)
            nRow = size(x, 1);
            nCol = size(x, 2);
            
            nObsPerRow = zeros(1, nRow);
            xVector = zeros(1,nRow*nCol);
            
            %관측치가 적은 row를 탐지하고 NaN을 제거하는 과정.
            %각 row에서, 맨 끝부터 시작해 NaN이 있는지 확인.
            %NaN이 나오지 않는 순간 탐지를 종료하고, 그 앞에 있는 값들은 다 정상값으로 간주
            % 즉, 끝부분에 연속적으로 나오는 NaN만 제거.
            startPoint = 1;
            endPoint = 0;
            for r = 1 : nRow
                i = nCol;
                while isnan(x(r, i))
                    i = i - 1;
                end
                
                if i < nCol
                    fprintf('%d행의 관측치 수가 %d로, %d개인 다른 행보다 관측치 수가 적습니다.\n', r, i, nCol);
                end

                cleanRow = x(r, 1:i);
                nObsPerRow(r) = i;
                
                endPoint = endPoint + i;
                startPoint = endPoint - i + 1;
                xVector(startPoint : endPoint) = cleanRow;
        
            end
            
            xVector = xVector(1:endPoint);
        end
        
        function cleansedX = checkNanCol(chReader, x)
            cleansedX = x; %python과 달리, matlab은 이렇게 하면 복사본을 생성함. 
            nRow = size(cleansedX,1);
            lastCol = cleansedX(:, end);
            
            if sum(isnan(lastCol)) >= nRow
                cleansedX(:, end) = [];
                fprintf('파일의 마지막 열이 모두 공백 문자로 되어 있습니다. matlab은 공백 문자를 NaN으로 불러옵니다. 해당 열을 삭제했습니다.\n');
            end
        end
        
   

    end %methods
end %class
