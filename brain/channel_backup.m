classdef channel < channel_from_data
    methods
        function ch = channel(filename, organoidNum, channelNum, month)
            % MEA data.xlsx와 동일한 포맷의 파일에서 필요한 정보를 뽑아내어 channel_from_data
            % 클래스 생성자에 넘겨주어 obejct를 생성
            data = readmatrix(filename);
            binTimeStart = data(:,5);
            x = data(:,6:end);
            ch = ch@channel_from_data(binTimeStart, x, organoidNum, channelNum, month );
        end
    end
end