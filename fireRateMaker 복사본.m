classdef animatedPixelMaker < handle
    properties
        channels
        endTimeMin
        startTimeMax
        selectedTimestamp
        selectedMs
    end
    
    methods
        function apm = animatedPixelMaker(nRow, nCol)
           apm.channels = cell(nRow, nCol);
           apm.endTimeMin = 0;
           apm.startTimeMax = 0;
           apm.selectedTimestamp = {};  
           apm.selectedMs = {};
        end

        function addChannel(frm, channelObject)
            
            if (length(channelObject.spikeTimestamps) < 1)
                fprintf("This channel does not have spikes information. Do detectSpikes(possibly with lower threshold value). Current total number of channels = %d", length(frm.channels));
            else
                frm.channels{end + 1} = channelObject;
                fprintf("Added a channel object. Current total number of channels = %d\n", length(frm.channels));
            end
        end
        
        function deleteLastChannel(frm)
            frm.channels(end) = [];
        end
        
        function processing(frm, cutoffVal, binWidth)
            frm.cutoff(cutoffVal);
            frm.turnSelecteSpikesIntoMs()
            frm.setEndTimeMin();
            frm.setStartTimeMax();
            frm.fireRate(binWidth);
        end
        
        function cutoff(frm, cutoffVal) %step 1
            frm.selectedTimestamp = {}; %clear previous results
            for i = 1 : length(frm.channels)
                channelNow = frm.channels{i};
                channelNowSpikesMax = max(channelNow.spikeWaveforms, [], 2); %max for each row
                channelNowSelectedIdxBoolean = channelNowSpikesMax > cutoffVal; % apply the cutdoff. the result looks like (true, true, false, true, false,...)
                channelNowSelectedTimestamp = channelNow.spikeTimestamps(channelNowSelectedIdxBoolean);
                frm.selectedTimestamp{end+1} = channelNowSelectedTimestamp; %apply the boolean and get the selected spikes
            end % for loop
        end % method cutoff
        
        function turnSelecteSpikesIntoMs(frm) %step 2
            frm.selectedMs = {};
            for i = 1 : length(frm.channels)
                channelNow = frm.channels{i};
                channelNowSelectedMs = (channelNow.startTime + frm.selectedTimestamp{i} / channelNow.sf) * 1000; %milisecond 단위
                frm.selectedMs{end+1} = channelNowSelectedMs;
            end
               
        end
        
        function setEndTimeMin(frm) %step 3
            channelNow = frm.channels{1};
            endTimeMin = channelNow.endTimeApprox;
            for i = 2 : length(frm.channels)
                channelNow = frm.channels{i};
                endTimeNow = channelNow.endTimeApprox;
                if endTimeNow < endTimeMin
                    endTimeMin = endTimeNow;
                end
            end
            frm.endTimeMin = endTimeMin;
        end
        
        function setStartTimeMax(frm) %step 4
            channelNow = frm.channels{1};
            startTimeMax = channelNow.startTime;
            for i = 2 : length(frm.channels)
                channelNow = frm.channels{i};
                startTimeNow = channelNow.startTime;
                if startTimeNow > startTimeMax
                    startTimeMax = startTimeNow;
                end
            end
            frm.startTimeMax = startTimeMax;
        end
        
        
        function fireRate(frm, binWidth)
            % 1. edges
            if frm.startTimeMax >= frm.endTimeMin
                print("error: startTime >= endTime")
                return
            end
        
            edges = [frm.startTimeMax*1000: binWidth: frm.endTimeMin*1000]; %시작점 : 구간길이 : 끝점
            th = zeros(length(edges),1)'; %Initialize the PSTH with zeros
        
            %2. histc with for loop
            for j  = 1 : length(frm.channels)
                th = th + histc(frm.selectedMs{j}, edges);
            end
            th = (th / binWidth) / length(frm.channels); %rate and averaging
            figure
            bar(edges, th)
        end
    end % methods
end %class
