%% Read data
% load dataset 
data=channel_XX(1:999999); %change channel_XX to desired dataset and timestamps boundaries

%% parameter definition
% import data
test_data = data;

thres = 5; %define multiple of sigma (for threshold settings)
threshold = -thres.*median(abs(data)/0.6745);

sf = 30000; % define sample frequency
clusternum = 2; %define number of cluster in analysis
pre_time =2; post_time = 2; %in ms, acquisition time before (pre_time) and after (post_time)detection of a waveform peak
time_stamp = [];
waveform = [];
ii = pre_time*30;

%% spike detection
count = 0;
while ii < length(test_data)
    tmp = test_data(ii);
    if tmp < threshold
        if post_time*30+ii < length(test_data)
            count = count + 1;
            time_stamp(count) = ii;
            waveform(count,:) = test_data((-pre_time*30:post_time*30)+ii);
        end
        ii = ii + post_time * 30;
    else
        ii = ii + 1;
    end
end
[row,column] = size(waveform);
[row2,column2] = size(data);
figure
subplot(2,1,1)
plot((-pre_time*30:post_time*30)/30,waveform');
title(['total spike number is ',num2str(row)]);
xlabel('time(ms)');
ylabel('Voltage(uV)');

subplot(2,1,2)
plot((-pre_time*30:post_time*30)/30,mean(waveform));
title('mean waveform');
xlabel('time(ms)');
ylabel('Voltage(uV)');

figure
time_for_plot = (1:length(test_data))/sf;
subplot(2,1,1)
plot(time_for_plot,test_data);
xlim([0,column2/sf]);
peaks=findpeaks(test_data,'MinPeakHeight',-threshold);
title('Filtered data');
xlabel('time(s)');
ylabel('Voltage(uV)');

subplot(2,1,2)
hold on
for ii = 1:length(time_stamp)
plot([time_stamp(ii),time_stamp(ii)]/sf,[-1,1],'k');
end
xlim([0,length(data)/sf]);
ylim([-10,10]);
title('Raster plot');
xlabel('time(s)');
ylabel('Raster');

%% dimension reduction (PCA)
% waveform = zscore(waveform); % Standardized data
figure
[coeff,score,latent,tsquared,explained] = pca(waveform);
h = biplot(coeff(:,1:2),'Scores',score(:,1:2));
xlabel('First PC');
ylabel('Second PC');
title('Principal Component Analysis');

% pca plot
% mapcaplot(waveform);

%% cluster (kmean)
figure
bar(explained)
title('Explained Variance')
ylabel('PC')

% Retain first two principal components
yeastPC = score(:,1:2);
figure
[clusters, centroid] = kmeans(yeastPC,clusternum);
gscatter(yeastPC(:,1),yeastPC(:,2),clusters)
xlabel('First PC');
ylabel('Second PC');
title('Principal Component Scatter Plot with Colored Clusters');

%% Plot result
figure
for c = 1:clusternum
    subplot(3,clusternum,c);
    plot((-pre_time*30:post_time*30)/30,waveform((clusters == c),:)','b');
    xlabel('time (ms)');
    ylabel('Voltage (uV)');
    title(['Cluster',num2str(c)]);
    
    subplot(3,clusternum,c+clusternum);
    plot((-pre_time*30:post_time*30)/30,mean(waveform((clusters == c),:)),'r');
    title('Mean spikes');
   
    x=(-pre_time*30:post_time*30)/30;
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
    plot((-pre_time*30:post_time*30)/30,mean(waveform((clusters == c),:)),'Linewidth',2,'Color','k');
    
    %min dVdt
    min(diff(mean(waveform((clusters == c),:)))*30)
end
% suptitle('Clustering of Profiles');

%% Color raster plot
figure
for i=1:clusternum
    Snumb(i)=0;%counting spikes in each cluster
end

for ii = 1:length(clusters)
    if clusters(ii)==1
        Snumb(1)=Snumb(1)+1;
        time_stamps(1,Snumb(1))=time_stamp(ii);
        plot([time_stamp(ii),time_stamp(ii)]/sf,[-1,1],'b');
        hold on
    elseif clusters(ii)==2
        Snumb(2)=Snumb(2)+1;
        time_stamps(2,Snumb(2))=time_stamp(ii);
        plot([time_stamp(ii),time_stamp(ii)]/sf,[-1,1],'r');
        hold on
    elseif clusters(ii)==3
     Snumb(3)=Snumb(3)+1;
        time_stamps(3,Snumb(3))=time_stamp(ii);
        plot([time_stamp(ii),time_stamp(ii)]/sf,[-1,1],'g');
        hold on
    elseif clusters(ii)==4
        Snumb(4)=Snumb(4)+1;
        time_stamps(4,Snumb(4))=time_stamp(ii);
        plot([time_stamp(ii),time_stamp(ii)]/sf,[-1,1],'y');
        hold on
    elseif clusters(ii)==5
        Snumb(5)=Snumb(5)+1;
        time_stamps(5,Snumb(5))=time_stamp(ii);
        plot([time_stamps(ii),time_stamp(ii)]/sf,[-1,1],'p');
        hold on
        end
end
xlim([0,length(data)/sf]);
ylim([-10,10]);
title('Colored Raster plot');
xlabel('time(s)');
ylabel('Raster');

%% Additional analysis for each cluster
figure 
for c = 1:clusternum
    subplot(2,clusternum,c);
        %Half-width
        findpeaks(-mean(waveform((clusters == c),:)),(-pre_time*30:post_time*30)/30,'Annotate','extents','WidthReference','halfheight');
        title('Signal Peak Widths')
        hold on
        curve1=mean(waveform((clusters == c),:))-std(waveform((clusters == c),:));
        curve2=mean(waveform((clusters == c),:))+std(waveform((clusters == c),:));
        findpeaks(-curve1,(-pre_time*30:post_time*30)/30,'Annotate','extents','WidthReference','halfheight');
        hold on
        findpeaks(-curve2,(-pre_time*30:post_time*30)/30,'Annotate','extents','WidthReference','halfheight');
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
