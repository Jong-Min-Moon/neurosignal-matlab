classdef longtermAnalyzer < handle
    properties
        channelObjects
        nChannelObjects
    end

    methods
        function LA = longtermAnalyzer()
            LA.channelObjects = struct;
            LA.nChannelObjects = 0;
        end

        function addChannel(LA, ch)
            %LA.nChannelObjects index 0에서 시작 
            LA.nChannelObjects = LA.nChannelObjects + 1; %channel object 하나 추가할 때마다 index를 하나씩 늘림
            index = LA.nChannelObjects; 
            
            %channelObjects 구조체에 정보 저장
            LA.channelObjects(index).organoidNum = ch.organoidNum;
            LA.channelObjects(index).channelNum = ch.channelNum;
            LA.channelObjects(index).month = ch.month;
            LA.channelObjects(index).channel = ch;
            LA.channelObjects(index).msPerTs = ch.msPerTs;

            %calculate FWHm
            LA.getFWHmsForChannel(ch, index);
            
            
        end %addChannel
        
        function FWHms = getFWHmsForChannel(LA, ch, index)
            spikes = ch.spikeWaveforms;
            nSpikes = size(spikes, 1);
            FWHms = zeros([nSpikes, 1]); %column vectors
            for i = 1 : nSpikes
                FWHms(i) = LA.getFWHm(spikes(i, :), ch.msPerTs);
            end
            LA.channelObjects(index).FWHms = FWHms; 
        end %end of getFWHmsForChannel
        
        function FWHm = getFWHm(LA, spikeWaveform, msPerTs)
            %full width at half minimum
            halfMin = min(spikeWaveform) / 2;
            index1 = find(spikeWaveform <= halfMin, 1, 'first');
            index2 = find(spikeWaveform <= halfMin, 1, 'last');
            indexDiff = (index2 - index1 + 1);
            FWHm = indexDiff * msPerTs; % FWHm in milisecond
        end % end of getFWHm  
        
        
        function [FWHmPoints, organoidLabels, meanFWHm] = getFWHmHistByMonth(LA, monthNum, channelNum)
            
            %주어진 month와 channel에 해당하는 channel object만 가져오
            channelsFiltered = LA.channelObjects([LA.channelObjects.channelNum] == channelNum);
            channelsFiltered = channelsFiltered([channelsFiltered.month] == monthNum);
            
            % storage
            
            FWHmPoints = []; % save FWHm datapoints for point plot
            organoidLabels = []; % save labels for point colors

            for ch = channelsFiltered
                FWHms = ch.FWHms;
                organoidNum = ch.organoidNum;
                FWHmPoints = [FWHmPoints; FWHms];
                organoidLabels = [organoidLabels; repelem(organoidNum, length(FWHms))'];
            end
            
            meanFWHm = mean(FWHmPoints);
         end
            

        
        function drawFWHmHistByMonth_backup(LA, channelNum)
            channelsOfThisChannelNum = LA.channelObjects([LA.channelObjects.channelNum] == channelNum);
            maxMonth = max([channelsOfThisChannelNum.month]);
            minMonth = min([channelsOfThisChannelNum.month]);

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
                x = repelem(monthNow, length(FWHmPointsByMonth{idx}));
                y = FWHmPointsByMonth{idx};
                colors = organoidLabelsByMonth{idx};
                scatter(x, y, [], colors, 'filled');
            end
            hold off
            ylabel("FWHm(ms)")
        end %drawHistByMonth

        function drawPhaseSpace(LA, channelNum, month)
            elems = LA.channelObjects(([LA.channelObjects.channelNum] == channelNum) & ([LA.channelObjects.month] == month));
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
        
        function aggregateByMonth(LA, channelNum, month)
            elems = LA.channelObjects(([LA.channelObjects.channelNum] == channelNum) & ([LA.channelObjects.month] == month));
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