drawMeanSpike(spikeObject)

%% Figure 6 
% for each cluster (left column is cluster 1), from top to bottom,
% all the waveforms, the average waveform, and the average waveform +/- 1 S.D.;
timestampsPrePeak = spikeObject.tsPrePeak; 
timestampsPostPeak = spikeObject.tsPostPeak;
msPerTimestamp = 0.3277

figure
for c = 1:clusternum
    x=(-timestampsPrePeak:timestampsPostPeak)*msPerTimestamp;
    curve1=mean(waveform((clusters == c),:))-std(waveform((clusters == c),:));
    curve2=mean(waveform((clusters == c),:))+std(waveform((clusters == c),:));
    subplot(clusternum,1,c);
    plot(x, curve1, 'k--', 'LineWidth', 1);
    hold on;
    plot(x, curve2, 'k--', 'LineWidth', 1);
    hold on;                                    % add Paul
    x2 = [x, fliplr(x)];
    inBetween = [curve1, fliplr(curve2)];
    %fill(x2, inBetween, [0.85 0.85 0.85]);
    axis tight   
    title('Spike group (mean+-std)');
    % add mean spike
    plot((-timestampsPrePeak:timestampsPostPeak)*msPerTimestamp,mean(waveform((clusters == c),:)),'Linewidth',2,'Color','k');
    
    %min dVdt
    min(diff(mean(waveform((clusters == c),:)))*30)
end
%suptitle('Clustering of Profiles');
