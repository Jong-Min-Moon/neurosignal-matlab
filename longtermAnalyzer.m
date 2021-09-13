classdef longtermAnalyzer < handle
    properties
        channels
        nChannels
    end

    methods
        function LA = longtermAnalyzer()
            LA.channels = struct;
            LA.nChannels = 0;
        end

        function addChannel(LA, ch)
            index = LA.nChannels + 1;
            
            LA.channels(index).organoidNum = ch.organoidNum;
            LA.channels(index).channelNum = ch.channelNum;
            LA.channels(index).month = ch.month;
            LA.channels(index).channel = ch;
            LA.channels(index).msPerTs = ch.msPerTs;

            %calculate FWHm
            spikes = ch.spikeWaveforms;
            nSpikes = size(spikes, 1);
            FWHms = zeros([nSpikes, 1]); %column vectors
            for i = 1 : nSpikes
                FWHms(i) = LA.getFWHm(spikes(i, :), ch.msPerTs);
            end
            LA.channels(index).FWHms = FWHms;
            LA.nChannels = LA.nChannels + 1;
        end %addChannel

        function FWHm = getFWHm(LA, spikeWaveform, msPerTs)
            %full width at half minimum
            halfMin = min(spikeWaveform) / 2;
            index1 = find(spikeWaveform <= halfMin, 1, 'first');
            index2 = find(spikeWaveform <= halfMin, 1, 'last');
            FWHm = (index2 - index1 + 1) * msPerTs; % FWHm in milisecond
        end % getFWHm  
        
        function drawHistByMonth(LA, channelNum)
            channelNum
            channelsOfThisChannelNum = LA.channels([LA.channels.channelNum] == channelNum)
            [channelsOfThisChannelNum.month]
            maxMonth = max([channelsOfThisChannelNum.month])
            minMonth = min([channelsOfThisChannelNum.month])

            % storage
            meanFWHmByMonth = repelem(0,maxMonth - minMonth); % save means for bar plot
            FWHmPointsByMonth = {}; % save FWHm datapoints for point plot
            organoidLabelsByMonth = {}; % save labels for point colors

            %for each month
            for monthNow = minMonth : maxMonth
                elems = channelsOfThisChannelNum([channelsOfThisChannelNum.month] == monthNow);
                
                %temporary storages
                FWHmsThisMonth = [];
                organoidLabelsThisMonth = [];

                %for each organoid
                for elem = elems
                    organoidNum = elem.organoidNum;
                    FWHms = elem.FWHms;
                    
                    %save at temporary storages
                    FWHmsThisMonth = [FWHmsThisMonth; FWHms];
                    organoidLabelsThisMonth = [organoidLabelsThisMonth; repelem(organoidNum, length(FWHms))'];
                end
                idx = monthNow - minMonth + 1;
                % save for bar plot
                meanFWHmByMonth(idx) = mean(FWHmsThisMonth);
                
                % save for point plotting
                FWHmPointsByMonth{idx} = FWHmsThisMonth;
                organoidLabelsByMonth{idx} = organoidLabelsThisMonth;
            end
            
            %barplot
            bar(meanFWHmByMonth);
            
            %+- sd
            
            hold on
            for monthNow = minMonth : maxMonth
                idx = monthNow - minMonth + 1;
                sdFWHm = std(FWHmPointsByMonth{idx});
                meanFWHm = meanFWHmByMonth(idx);
                upperLimit = meanFWHm + sdFWHm;
                lowerLimit = meanFWHm - sdFWHm;
                plot([monthNow, monthNow], [lowerLimit,upperLimit], 'k','LineWidth',2);  
                plot([monthNow-0.1, monthNow+0.1], [lowerLimit,lowerLimit], 'k','LineWidth',2);
                plot([monthNow-0.1, monthNow+0.1], [upperLimit,upperLimit], 'k','LineWidth',2);  

            end
            hold off

            %plot points
            hold on
            for monthNow = minMonth : maxMonth
                idx = monthNow - minMonth + 1;
                scatter(repelem(monthNow, length(FWHmPointsByMonth{idx})), FWHmPointsByMonth{idx}, [], organoidLabelsByMonth{idx}, 'filled')
            end
            hold off
        end %drawHistByMonth

        function drawPhaseSpace(LA, channelNum, month)
            elems = LA.channels(([LA.channels.channelNum] == channelNum) & ([LA.channels.month] == month));
            waveformsConcat = []; % storage
            msPerTs = mean([elems.msPerTs])
            %for each organoid
            for elem = elems
                waveformsConcat = [waveformsConcat; elem.channel.spikeWaveforms];
            end
            averageWaveform = mean(waveformsConcat);
            dVdt = diff(averageWaveform)/msPerTs;
            averageWaveform = averageWaveform - min(averageWaveform);     
            dVdt = dVdt - mean(dVdt)

            %draw
            V = averageWaveform(1:(end-1))
            hold on
            for i = 1: (length(dVdt)-1)
                plot([V(i), V(i+1)], [dVdt(i), dVdt(i+1)], 'k');
            end
            hold off
        end %drawPhaseSpace
    end %methods
end %classdef