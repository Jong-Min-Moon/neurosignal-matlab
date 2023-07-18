classdef drawer_raster < handle
    %UNTITLED4 Summary of this class goes here
    %   Detailed explanation goes here

    properties
    end

    methods
        function dr = drawer_raster()
            %UNTITLED4 Construct an instance of this class
            %   Detailed explanation goes here
        end
        function drawRaster(dr, channel_instance, color)
            channelNum = channel_instance.channelNum;
            hold on
            dr.drawRaster_basic(channel_instance, channelNum, color);
            hold off
            ylim( channelNum + [-1, 1]);
            title('Raster plot');
            xlabel('time(s)');
            ylabel('Raster');
        end

        function drawRaster_basic(dr, channel_instance, y_index, color)
            % from CyborgBrainOrg.m
            spikeTimestamps = channel_instance.spikeTimestamps;
            sf = channel_instance.sf;
            startTime = channel_instance.startTime;
            for ii = 1:length(spikeTimestamps)
                spikeTimestampTuple = startTime + [spikeTimestamps(ii), spikeTimestamps(ii)]/sf;
                p = plot(spikeTimestampTuple, y_index + [-0.2, 0.2], 'k');
                p.Color = color;
            end
        end %drawRaster

        function drawRasterAll(dr, multiChannel_instance, color)
            if isa(multiChannel_instance, "networkAnalyzer")
                channel_dictionary = multiChannel_instance.channels;
                channelNum_array = keys(channel_dictionary);
            end
            
            hold on
            for ii = 1:length(channelNum_array)
                channelNum = channelNum_array(ii);
                channel_now = channel_dictionary(channelNum);
                dr.drawRaster_basic(channel_now, ii, color);
            end
            hold off
            ylim([-1, length(channelNum_array) + 1])
            xlabel('time(s)');
            ylabel('channel');
            set(gca,'YTick',[])
            flip(channelNum_array,1)
   
        end %drawRasterAll


    end
end