
classdef channelsFromMultiChannel < handle
    properties
        data
        channelRows
    end
    methods
        function chmc = channelsFromMultiChannel(filename)
            %1_singleunit wave.xlsx파일과 똑같은 포맷을 가정
            %80mb짜리 파일 기준으로 코어 i7 2.3GHz에서 데이터 로드에 1분 이상 소요
            data = readmatrix(filename, NumHeaderLines = 6);  %데이터가 7번째 줄부터 시작하므로, 위에서부터 6줄은 버리고 데이터 로드 
            channelRows = data(:,1);  %파일에 있는 채널 목록을 확인 

            chmc.data = data;
            chmc.channelRows = channelRows;
        end
        
        function channelObject = channel(chmc, organoidNum, channelNum, month)
            channelBoolean = chmc.channelRows == channelNum;
            channelData = chmc.data(channelBoolean,:);

            binTimeStart = channelData(:,3);
            x = channelData(:, 4:end);
            channelObject = channel_from_data(binTimeStart, x, organoidNum, channelNum, month);
        end
    end
end