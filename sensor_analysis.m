
            
[nSpikes, column] = size(waveform);
[row2, column2] = size(data);










%% Figure 2 shows the time series and the corresponding raster plot (before clustering)
% plot 2.1: the time series
figure
time_for_plot = binTimeStart(1) + (1:length(yFiltered))/desiredSamplingFrequency; %timestamp to ms conversion
subplot(2,1,1)
plot(time_for_plot, yFiltered);
xlimYFiltered = binTimeStart(1) + [0, 1 + (length(yFiltered))/desiredSamplingFrequency]
xlim(xlimYFiltered);
peaks = findpeaks(yFiltered, 'MinPeakHeight', -3);
title('plot 2.1. Filtered data')
xlabel('time(s)')
ylabel('Voltage(uV)')

%plot 2.2: raster plot
subplot(2,1,2)
hold on
for ii = 1:nSpikes
    spikeTimestampTuple = binTimeStart(1) + [time_stamp(ii), time_stamp(ii)]/desiredSamplingFrequency
    plot(spikeTimestampTuple, [-1,1], 'k');
end
xlim(xlimYFiltered)
ylim([-10,10])
title('plot 2.2. Raster plot');
xlabel('time(s)');
ylabel('Raster');


%% Figure 3 shows the waveforms detected in the PC1 - PC2 plane,
% along with the projection of the scores of all eigenvectors
%% dimension reduction (PCA)
waveformZ = zscore(waveform)
figure
[coeff, score, latent, tsquared, explained] = pca(waveformZ);
h = biplot(coeff(:,1:2), 'Scores', score(:, 1:2)); 
xlabel('First PC');
ylabel('Second PC');
title('plot 3.1. Principal Component Analysis(biplot, not scatterplot)')


%% cluster(kmean)
figure
bar(explained)
title('plot 3.2. Explained Variance')
ylabel('PC')

%% Retain first two principal components
yeastPC = score(:, 1:2);
figure
[clusters, centroid] = kmeans(yeastPC, clusternum);
gscatter(yeastPC(:,1), yeastPC(:,2), clusters)
xlabel('First PC');
ylabel('Second PC');
title('plot 3.3. Principal Component Scatter Plot with Colored Clusters');
