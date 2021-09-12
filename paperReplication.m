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
 %define multiple of sigma (for threshold settings)
 %in ms, acquisition time before (pre_time) and after (post_time)detection of a waveform peak



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
