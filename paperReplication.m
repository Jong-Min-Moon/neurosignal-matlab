%% Required toolbox
% bioinformatic toolbox (for mapcaplot)
% signal processing toolbox (for bandpass)
% circular statistics (for phase analysis)


%% Read data
fileNames = ["ch6", "ch8", "ch9"];
for i = 1:length(fileNames)
    fileName = fileNames(i) + ".csv";
    [t, x, msPerTimestamp, desiredSamplingFrequency] = loadResample(fileName);
    raw(i).name = fileNames(i);
    raw(i).t = t;
    raw(i).x = x;
    raw(i).msPerTs = msPerTimestamp;
    raw(i).sf = desiredSamplingFrequency;           
end

rawLimMax = max(max([raw.x]));
rawLimMin = min(min([raw.x]));
rawLim = [rawLimMin, rawLimMax];

%% Apply bandpass filter and compare with the original signal
for i = 1:length(raw)

end

filteredLimMax = max(max([filtered.x]));
filteredLimMin = min(min([filtered.x]));
filteredLim = [filteredLimMin, filteredLimMax];
%% detect spikes

% parameters
thres = 5; %define multiple of sigma (for threshold settings)
preTime =2; postTime = 2; %in ms, acquisition time before (pre_time) and after (post_time)detection of a waveform peak

for i = 1:length(filtered)
    [timestampsPrePeak, timestampsPostPeak, timeStamp, waveform] = spike(filtered(i).x, filtered(i).sf, thres, preTime, postTime);
    spikes(i).name = filtered(i).name;
    spikes(i).timeStamp = timeStamp;
    spikes(i).waveform = waveform;
end
%% pca and k-means
clusternum = 3;% parameter

for i = 1:length(spikes)
    [scoreTwoDim, cluster] = pcaKmeans(spikes(i).waveform, clusternum);
    clusteredPCs(i).name = spikes(i).name;
    clusteredPCs(i).scores = scoreTwoDim;
    clusteredPCs(i).clusters = cluster;
end
%% figure 2.b.

for i = 1:length(raw)
    subplot(length(raw), 1, i);
    plot(raw(i).t, raw(i).x)
    ylim(rawLim)
    title(raw(i).name)
end
%%

tslim = [min(tResampled), max(tResampled)+1] %xlim for time in second, for later use
tmslim = 1000 * [min(tResampled), max(tResampled)+1] %xlim for time in milisecond, for later use


%% figure 2.f

for i = 1:length(filtered)
    subplot(length(filtered), 1, i);
    plot(filtered(i).t, filtered(i).x)
    ylim(filteredLim)
    title(filtered(i).name)
end




%% Figure 2 shows the time series and the corresponding raster plot (before clustering)
figure

% plot 2.1: the time series
xlimCalculated = binTimeStart(1) + [0, 1 + (length(yFiltered))/desiredSamplingFrequency]
time_for_plot = binTimeStart(1) + (1:length(yFiltered))/desiredSamplingFrequency; %timestamp to ms conversion
subplot(2,1,1)
plot(time_for_plot,test_data);

xlim(xlimCalculated);
peaks=findpeaks(test_data,'MinPeakHeight',-threshold);
title('Filtered data');
xlabel('time(s)');
ylabel('Voltage(uV)');

%plot 2.2: raster plot
subplot(2,1,2)
hold on
for ii = 1:length(time_stamp)
    spikeTimestampTuple = binTimeStart(1) + [time_stamp(ii), time_stamp(ii)]/desiredSamplingFrequency
    plot(spikeTimestampTuple, [-1,1], 'k');
end
xlim(xlimCalculated);
ylim([-10,10]);
title('Raster plot');
xlabel('time(s)');
ylabel('Raster');




%% Color raster plot
figure
for i=1:clusternum
    Snumb(i)=0;%counting spikes in each cluster
end

for ii = 1:length(clusters)
    if clusters(ii)==1
        Snumb(1)=Snumb(1)+1;
        time_stamps(1,Snumb(1))=time_stamp(ii);
        spikeTimestampTuple = binTimeStart(1) + [time_stamp(ii), time_stamp(ii)]/desiredSamplingFrequency;
        plot(spikeTimestampTuple,[-1,1],'b');
        hold on
    elseif clusters(ii)==2
        Snumb(2)=Snumb(2)+1;
        time_stamps(2,Snumb(2))=time_stamp(ii);
        spikeTimestampTuple = binTimeStart(1) + [time_stamp(ii), time_stamp(ii)]/desiredSamplingFrequency;

        plot(spikeTimestampTuple,[-1,1],'r');
        hold on
    elseif clusters(ii)==3
     Snumb(3)=Snumb(3)+1;
        time_stamps(3,Snumb(3))=time_stamp(ii);
        spikeTimestampTuple = binTimeStart(1) + [time_stamp(ii), time_stamp(ii)]/desiredSamplingFrequency;

        plot(spikeTimestampTuple,[-1,1],'g');
        hold on
    elseif clusters(ii)==4
        Snumb(4)=Snumb(4)+1;
        time_stamps(4,Snumb(4))=time_stamp(ii);
        spikeTimestampTuple = binTimeStart(1) + [time_stamp(ii), time_stamp(ii)]/desiredSamplingFrequency;
        
        plot(spikeTimestampTuple,[-1,1],'y');
        hold on
    elseif clusters(ii)==5
        Snumb(5)=Snumb(5)+1;
        time_stamps(5,Snumb(5))=time_stamp(ii);
        spikeTimestampTuple = binTimeStart(1) + [time_stamp(ii), time_stamp(ii)]/desiredSamplingFrequency;
        
        plot(spikeTimestampTuple,[-1,1],'p');
        hold on
        end
end
xlim(tslim);
ylim([-10,10]);
title('Colored Raster plot');
xlabel('time(s)');
ylabel('Raster');

%% Additional analysis for each cluster
figure 
for c = 1:clusternum
    subplot(2,clusternum,c);
        %Half-width
        findpeaks(-mean(waveform((clusters == c),:)),(-timestampsPrePeak:timestampsPostPeak)*msPerTimestamp,'Annotate','extents','WidthReference','halfheight');
        title('Signal Peak Widths')
        hold on
        curve1=mean(waveform((clusters == c),:))-std(waveform((clusters == c),:));
        curve2=mean(waveform((clusters == c),:))+std(waveform((clusters == c),:));
        findpeaks(-curve1,(-timestampsPrePeak:timestampsPostPeak)*msPerTimestamp,'Annotate','extents','WidthReference','halfheight');
        hold on
        findpeaks(-curve2,(-timestampsPrePeak:timestampsPostPeak)*msPerTimestamp,'Annotate','extents','WidthReference','halfheight');
        legend('off');
        hold on
        %ISI calculation
            for j=2:Snumb(c)
                if time_stamps(c,j)>0
                    ISI(c,j)=time_stamps(c,j)-time_stamps(c,j-1);
                end  
            end
end
ISI(:,1)=[];
for c = 1:clusternum  %ISI histograms
    subplot(2,clusternum,c+clusternum);
    histogram(ISI(c,1:Snumb(c)-1)/30,100);
    title('ISI histogram');
    xlabel('ISI (ms)');
    hold on
end
