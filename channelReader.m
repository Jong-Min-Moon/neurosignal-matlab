classdef channelReader < handle
    properties
        massiveData
        massiveDataChannelRows
        channelList
        fileSampleRate
        fileTimeColumnIdx
        fileBinTimeStart
    end
    
    methods
        function chReader = channelReader()
        end
    %part 1 : single channel file
    %part 2 : multi-channel file
    %part 3 : utils


        function channelObject = readVerticalChannel(chReader, filename, timeColumnIdx, startRowIdx, startColIdx, sampleRate, organoidNum, channelNum, month)
           
           
            x = readmatrix(filename);
            if timeColumnIdx > 0 %time variable이 있는 경우 
                binTimeStart = readmatrix(filename,  range = [startRowIdx timeColumnIdx] ); %time이 첫 번째 column이 되도록 데이터를 불러온 후  
                binTimeStart = binTimeStart(:, 1); % 
                % 시간을 나타내는 열을 따로 저장 
                
            end
            
            x = chReader.checkNanCol(x); % NaN column check
            
            % make xVector and tVector
            if timeColumnIdx > 0
                [xVector, nObsPerRow] = chReader.vectorizeX(x);
                [tVector, sampleRateUsed] = chReader.vectorizeT(binTimeStart, nObsPerRow, numel(xVector));
            else
                sampleRateUsed = sampleRate;
                [xVector, ~] = chReader.vectorizeX(x);
                tVector = chReader.makeTimeVariable(numel(xVector), sampleRateUsed);
            end
                        
            % common procedure
            [xResampled, tResampled] = resample(xVector, tVector, sampleRateUsed, 'spline'); %resample 및 interpolation 실행
            channelObject = channel(xResampled, tResampled, sampleRateUsed, organoidNum, channelNum, month);
        end

        function channelObject = readSingleChannel(chReader, filename, timeColumnIdx, startRowIdx, startColIdx, sampleRate, organoidNum, channelNum, month)
            % inputs:
            %   1. filename: 파일 경로 입력
            %   2. timeColumnIdx: 각 row의 시작시간이 기록되어 있는 column의 번호. 시간이 기록되어 있지
            %                    않으면 0으로 입력
            %   3. startRowIdx: 관측치 기록이 시작되는 row number
            %   4. startColIdx: 관측치 기록이 시작되는 column number
            %   5. sampleRate: sampling frequency.시간이 기록되어 있는 파일의 경우 이 값은 사용되지
            %                 않음
            %   6. organoidNum : 관리를 위한 organoid number. 데이터 변환에 사용되지는 않음.
            %   7. channelNum : 관리를 위한 channel number. 데이터 변환에 사용되지는 않음.
            %   8. month : 관리를 위한 month number. 데이터 변환에 사용되지는 않음.
           
            x = readmatrix(filename,  range = [startRowIdx startColIdx] );
            if timeColumnIdx > 0 %time variable이 있는 경우 
                binTimeStart = readmatrix(filename,  range = [startRowIdx timeColumnIdx] ); %time이 첫 번째 column이 되도록 데이터를 불러온 후  
                binTimeStart = binTimeStart(:, 1); % 
                % 시간을 나타내는 열을 따로 저장 
                
            end
            
            x = chReader.checkNanCol(x); % NaN column check
            
            % make xVector and tVector
            if timeColumnIdx > 0
                [xVector, nObsPerRow] = chReader.vectorizeX(x);
                [tVector, sampleRateUsed] = chReader.vectorizeT(binTimeStart, nObsPerRow, numel(xVector));
            else
                sampleRateUsed = sampleRate;
                [xVector, ~] = chReader.vectorizeX(x);
                tVector = chReader.makeTimeVariable(numel(xVector), sampleRateUsed);
            end
                        
            % common procedure
            [xResampled, tResampled] = resample(xVector, tVector, sampleRateUsed, 'spline'); %resample 및 interpolation 실행
            channelObject = channel(xResampled, tResampled, sampleRateUsed, organoidNum, channelNum, month);
        end
                      
        

 
        function readMultiChannelFile(chReader, ...
                filename, channelColumnIdx, timeColumnIdx, startRowIdx, startColIdx, sampleRate ...
                )
            % inputs:
            % 1. filename: string.
            %    - file path (e.g. "./data/1_singleunit wave.xlsx")
            % 2. channelColumnIdx: int.
            %    - indicates which column stores the channel information.
            %    - a multichannel file must have this information.                       
            % 3. timeColumnIdx: int.
            %    - indicates which column stores the starting time of each row.
            %    - input 0 if the file does not contain this information.
            %     (than that file must contain sampleRate information)
            % 4. startRowIdx: int.
            %    - indicates which row starts recording obervations               
            % 5. startColIdx: int.
            %    - indicates which column starts recording obervations 
            % 6. sampleRate: double.
            %    - sampling frequency.
            %    - input nan if 
            %
            % output: none
            % This function preproces information from the multi-channel data file.
            % Channel data extraction is handled by other functions

            % read data part of the file (i.e. skip the explanations written in English)
            data = readmatrix(filename, range = [startRowIdx channelColumnIdx]); 

            % extract channel information and  create a channel list
            chReader.massiveDataChannelRows = data(:,1);         
            chReader.channelList = unique(chReader.massiveDataChannelRows);

            % print out the channel list to the user
            fprintf("This file has %d channels: ", length( chReader.channelList ))
            transpose(chReader.channelList) %just to print out the list in horizontal format

            % if starting time for each row is available, save it for later use
            % it will be used for calculating the sampleRate 
            if timeColumnIdx > 0 % 시간이 기록되어 있으면, 
                chReader.fileBinTimeStart = data(:, timeColumnIdx- channelColumnIdx + 1);
            end
            
            % save the numeric recording part of the file
            chReader.massiveData = data(:, (startColIdx - channelColumnIdx + 1):end );
            chReader.fileTimeColumnIdx = timeColumnIdx;
            chReader.fileSampleRate = sampleRate;
        end        
                
        function channelObject = readSingleChannelFromFile(chReader, organoidNum, channelNum, month)
            channelBoolean = chReader.massiveDataChannelRows == channelNum; %channel num에 해당하는 row만 골라냄 
            channelData = chReader.massiveData(channelBoolean,:); % 그 boolean을 datatset에 적용 
            channelBinTimeStart = chReader.fileBinTimeStart(channelBoolean,:);
            x = chReader.checkNanCol(channelData); % NaN column check
            
            % make xVector and tVector
            if chReader.fileTimeColumnIdx > 0
                [xVector, nObsPerRow] = chReader.vectorizeX(x);
                [tVector, sampleRateUsed] = chReader.vectorizeT(channelBinTimeStart, nObsPerRow, numel(xVector));
            else
                sampleRateUsed = ch.fileSampleRate;
                [xVector, ~] = chReader.vectorizeX(x);
                tVector = chReader.makeTimeVariable(numel(xVector), sampleRateUsed);
            end
            
            [xResampled, tResampled] = resample(xVector, tVector, sampleRateUsed, 'spline'); %resample 및 interpolation 실행
            channelObject = channel(xResampled, tResampled, sampleRateUsed, organoidNum, channelNum, month);             
        end % function readSingleChannelFromFile
        
        function channelDict = readManyChannelsFromFile(chReader, organoidNum, month)
            fprintf("Reading %d channels at once...\n\n", length(chReader.channelList))
            channelDict = dictionary;
            for i = 1:length(chReader.channelList)
                channelNum = chReader.channelList(i);
                channelObject = chReader.readSingleChannelFromFile(organoidNum, channelNum, month);
                channelDict(channelNum) = channelObject;
            end % for loop
        end % function readAllChannelsFromFile
   
        function channelPair = readMixedSingleChannelFromFile(chReader, organoidNum, channelNum, month, LFPRange, SURange)
            channelPair = dictionary;
            
            fprintf("LFP:\n")
            LFPChannelObject = chReader.readSingleChannelFromFile(organoidNum, channelNum, month);
            LFPChannelObject.bandPass(LFPRange)
            LFPChannelObject.raw = LFPChannelObject.filtered;           
            channelPair("LFP") = LFPChannelObject;
            
            fprintf("SU:\n")
            SUChannelObject = chReader.readSingleChannelFromFile(organoidNum, channelNum, month);
            SUChannelObject.bandPass(SURange)
            SUChannelObject.raw = SUChannelObject.filtered;
            channelPair("SU") = SUChannelObject;   
        end        
        
        function channelDict = readManyMixedChannelsFromFile(chReader, organoidNum, month, LFPRange, SURange)
            fprintf("Reading %d mixed channels at once...\n\n", length(chReader.channelList))
            channelDict = dictionary;
            for i = 1:length(chReader.channelList)
                channelNum = chReader.channelList(i);
                channelObject = chReader.readMixedSingleChannelFromFile(organoidNum, channelNum, month, LFPRange, SURange);
                keyStringLFP = channelNum + ", LFP";
                keyStringSU = channelNum + ", SU";
                channelDict(keyStringLFP) = channelObject("LFP");
                channelDict(keyStringSU) = channelObject("SU");
            end % for loop
        end % function readManyMixedChannelsFromFile        
        

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
% part 3. utils       
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                
              
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
