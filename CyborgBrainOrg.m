%% Required toolbox
% bioinformatic toolbox (for mapcaplot)
% signal processing toolbox (for bandpass)
% 


%% Read data
% load dataset
% use 16 digits of precision(MATLAB default)

data = readmatrix("raw data.csv");

%% Convert data into a single 1d array

% calculate time interval of each bin(which contains 256 observations)
binTimeStart = data(:,5); %assuming that 'time' means starting time.
binTimeInterval = diff(binTimeStart);
binTimeInterval(end+1) = binTimeInterval(end);

% y varaible into a single 1d array
y = data(:,6:end); % data in format of matrix of size nBin * 256 
[nBins, nPointsPerBin] = size(y);
y = transpose(y);
y = y(:); % collapse into 1d array, columnwisely

% time variable into a single 1d array
tPercentileInsideBin = linspace(0,255/256,256);
t = binTimeStart + binTimeInterval * tPercentileInsideBin;
t = transpose(t);
t = t(:);




%% resample the signal using spline, to make uniform time interval
msPerTimestamp = mean(binTimeInterval) * (1000/256) % milisecond per timestamp. stamp->ms conversion.
desiredSamplingFrequency = 1000 * (1/msPerTimestamp) %approx. 3000hz. 1/10 of reference code 30000hz
[yResampled, tResampled] = resample(y, t, desiredSamplingFrequency, 'spline');

% Plot to compare the resampled data with the original one. Indiscernible,
% because the original time interval was almost uniform.
plot(t, y)
hold on
plot(tResampled, yResampled)
hold off
legend('Original', 'Resampled using spline')

tslim = [min(tResampled), max(tResampled)+1] %xlim for time in second, for later use
tmslim = 1000 * [min(tResampled), max(tResampled)+1] %xlim for time in milisecond, for later use

%% Set passband frequency for bandpass filtering
%try several [low, high] Hz passband frequency, using the information from the plot 
passbandFrequency = [200,1000] % parameter to set.
bandpass(yResampled, passbandFrequency, desiredSamplingFrequency)

%% Apply bandpass filter and compare with the original signal
passbandFrequency = [200, 1000]
yFiltered = bandpass(yResampled, passbandFrequency, desiredSamplingFrequency);

subplot(3,1,1);
plot(tResampled, yResampled)
xlim(tslim)
title('original')

subplot(3,1,2);
plot(tResampled, yFiltered)
xlim(tslim)
title('filtered')

%% parameter definition
% import data
test_data = yFiltered;

thres = 5; %define multiple of sigma (for threshold settings)
threshold = -thres.*median(abs(test_data)/0.6745); % approximate standard deviation, robust to outliers

desiredSamplingFrequency; % Unlike the reference code, this is not set, but calculated above.
clusternum = 2; % define number of cluster in analysis(classification of spikes using kmeans)
pre_time =2; post_time = 2; %in ms, acquisition time before (pre_time) and after (post_time)detection of a waveform peak

% In the reference code and data, timestamp per milisecond was an integer(30)
% so the waveform length in terms of timestamps was conviniently calculated as 2*30.
% For our dataset, timestamp per milisecond is not an integer.
% So instead of using 2*30, we explicitly make varaibles to store waveform length in terms of timestamp(ceild to make them into integer). 
timestampsPrePeak = ceil(pre_time * (desiredSamplingFrequency/1000)) %reference code: 2ms * 30stamps/ms = 60stamps
timestampsPostPeak = ceil(pre_time * (desiredSamplingFrequency/1000)) %reference code: 2ms * 30stamps/ms = 60stamps



%% spike detection
time_stamp = []; % 1d array to store the timestamp of spike occurrence.
waveform = []; % nd array to store the waveform of spikes. Each row represents one waveform of spike.
ii = timestampsPrePeak;
count = 0;

while ii < length(test_data)
    tmp = test_data(ii);
    if tmp < threshold
        if timestampsPostPeak+ii < length(test_data) % spike가 뒷쪽에 있을 경우 waveformwidth가 확보될 때만 기록한다.
            count = count + 1;
            time_stamp(count) = ii;
            waveform(count,:) = test_data((-timestampsPrePeak:timestampsPostPeak)+ii);
        end
        ii = ii + timestampsPostPeak;
    else
        ii = ii + 1;
    end
end

[row,column] = size(waveform);
[row2,column2] = size(test_data);


%% Figure 1 shows a time window with all the spikes detected and the average waveform
figure



%plot 1.1: a time window with all the spikes detected
subplot(2,1,1)
plot((-timestampsPrePeak:timestampsPostPeak)*msPerTimestamp, transpose(waveform));
title(['total spike number is ',num2str(row)]);
xlabel('time(ms)');
ylabel('Voltage(uV)');

%plot 1.2: the average waveform of spikes
subplot(2,1,2)
plot((-timestampsPrePeak:timestampsPostPeak)*msPerTimestamp,mean(waveform));
title('mean waveform');
xlabel('time(ms)');
ylabel('Voltage(uV)');

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


%% dimension reduction (PCA)
% Figure 3 shows the waveforms detected in the PC1 - PC2 plane,
% along with the projection of the scores of all eigenvectors

% Standardized data. Commented out in the reference code.
% However, since PCA finds the dimension of the largest variability,
% Non-standardized data might lead the PCA into PCA setting one particular waveform as the first PC.
% Therefore, I de-commented this part.
waveformZ = zscore(waveform); 
figure
[coeff,score,latent,tsquared,explained] = pca(waveformZ);
h = biplot(coeff(:,1:2),'Scores',score(:,1:2)); %biplot, not scatterplot. might look weird.
xlabel('First PC');
ylabel('Second PC');
title('Principal Component Analysis(biplot, not scatterplot)');

%% pca plot
mapcaplot(waveformZ);

%% Figure 4 shows the explained variance of each PC;
figure
bar(explained)
title('Explained Variance')
ylabel('PC')

%% Figure 5 shows the waveforms detected in the PC1 - PC2 space after clustering;
% i.e. retain first two principal components.
yeastPC = score(:,1:2);
figure
[clusters, centroid] = kmeans(yeastPC,clusternum);
gscatter(yeastPC(:,1),yeastPC(:,2),clusters)
xlabel('First PC');
ylabel('Second PC');
title('Principal Component Scatter Plot with Colored Clusters');

%% Figure 6 
% for each cluster (left column is cluster 1), from top to bottom,
% all the waveforms, the average waveform, and the average waveform +/- 1 S.D.;

figure
for c = 1:clusternum
    subplot(3,clusternum,c);
    plot((-timestampsPrePeak:timestampsPostPeak)*msPerTimestamp,waveform((clusters == c),:)','b');
    xlabel('time (ms)');
    ylabel('Voltage (uV)');
    title(['Cluster',num2str(c)]);
    
    subplot(3,clusternum,c+clusternum);
    plot((-timestampsPrePeak:timestampsPostPeak)*msPerTimestamp,mean(waveform((clusters == c),:)),'r');
    title('Mean spikes');
   
    x=(-timestampsPrePeak:timestampsPostPeak)*msPerTimestamp;
    curve1=mean(waveform((clusters == c),:))-std(waveform((clusters == c),:));
    curve2=mean(waveform((clusters == c),:))+std(waveform((clusters == c),:));
    subplot(3,clusternum,c+2*clusternum);
    plot(x, curve1, 'k--', 'LineWidth', 1);
    hold on;
    plot(x, curve2, 'k--', 'LineWidth', 1);
    hold on;                                    % add Paul
    x2 = [x, fliplr(x)];
    inBetween = [curve1, fliplr(curve2)];
%     fill(x2, inBetween, [0.85 0.85 0.85]);
    axis tight   
    title('Spike group (mean+-std)');
    % add mean spike
    plot((-timestampsPrePeak:timestampsPostPeak)*msPerTimestamp,mean(waveform((clusters == c),:)),'Linewidth',2,'Color','k');
    
    %min dVdt
    min(diff(mean(waveform((clusters == c),:)))*30)
end
%suptitle('Clustering of Profiles');

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
