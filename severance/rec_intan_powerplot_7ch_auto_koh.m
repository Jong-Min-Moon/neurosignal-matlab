close all;clear all;clc;

%% Loading the mat file

read_Intan_RHD2000_file;
%choose channel
%4개 채널을 고르세요
channel = [1 2 3 4 5 6 7 8];
raw = [];


figure;
set(0,'defaultfigurepos',[2000 500 1000 400])
for i=1:length(channel)
    subplot(4,2,i);
    raw(i,:) = amplifier_data(channel(i),:);
    plot(t_amplifier, raw(i,:));  
end

%% basic manipulation %%
    Fs = frequency_parameters.amplifier_sample_rate; 
    Trec = 60;
   % Sampling interval, frequency 
    timeline = t_amplifier;

    % Filtering (band pass filter for spike counting)

for i = 1 : size(raw,1)    
    n=7; Wn=[100 3000]; % band pass filter range
    [b, a] = butter(n, Wn/(Fs/2), 'bandpass');
    bpf_data(i,:) = filtfilt(b,a,raw(i,:));
   
end

    % checking bpf_signal
figure; 
for i=1:size(bpf_data,1)    
    subplot(4,2,i);
    plot(t_amplifier, bpf_data(i,:))
end

%     set(gca, 'FontSize',12)
%     xlabel('time(s)','FontSize',10), ylabel('frequency(Hz)','FontSize',10)

%% LFP
figure;
    for i=1:size(raw,1)
        % Filtering (low pass filter for LFP)
        Fc = 300; %300
        [b,a] = butter(4,Fc/(Fs/2),'low');
        lpf_data= filtfilt(b,a,raw(i,:));
        clear a b
        
        % Desampling 1000 Hz
        dFs = 1000;
        lpf_data_de= resample(lpf_data,dFs,Fs);
        x_de= 1/dFs:1/dFs:length(lpf_data_de)/dFs;
        
        % STFT 생성
        R= 500; %500                 % welch window size=  1초
        noverlap = R/2;          % 50 % overlap (1.25로 나누면 좀더 촘촘해짐, 2)
        window1= hanning(R);
        NFFT =2048*4;              %2^nextpow2(L);
        [S, F, T]= spectrogram(lpf_data_de, window1, noverlap, NFFT, dFs);
        %     clear R window1 noverlap NFFT
        %                     figure(), clf
        %                     colorbar = [0 2000];    % color map을 조절하며 원하는 scale 찾음
        %                     imagesc(T,F,abs(S),colorbar);
        %                     axis xy
        %                     xlabel('time(s)'), ylabel('frequency(Hz)'), title('');
        %                     ylim([0 Fc]), xlim([1 Trec])
        %
        % Normalized STFT
        before_fin = floor(double(length(T)*(20/Trec)));
        before_stft = abs(S(:,1:before_fin));
        during_after_stft= abs(S(:,1:end));
        
        baseline_value= mean(before_stft,2);
        mul= ones(1,length(T));
        baseline_matrix= baseline_value*mul;
        
        % Normalizaed: (X-baseline)/baseline
        normalized_stft= (during_after_stft-baseline_matrix)./baseline_matrix;
        
        %     figure(), \%clf
     
        subplot(4,2,i)
        colorbar= [0 1];
%         imagesc((T(1:end)),F,normalized_stft,colorbar);%
%         axis xy
%         xlabel('time(s)'), ylabel('frequency(Hz)'),
%         ylim([0 100])
        
        PSF = fspecial('average',[2 16]);
        Blurred_n = imfilter(normalized_stft,PSF,'conv');
                
        imagesc((T(1:end)),F,Blurred_n,[-0.5 0.5]); ylim([0 100])
        axis xy
         xlabel('time(s)'), ylabel('frequency(Hz)'),
%         clear PSF Blurred_n lpf_data lpf_data_de;

        Blurred_save(i,:,:)=Blurred_n;
    end
    
    clear Blurred_n
%% power-time plot
% a (8 ~ 13 hz)
% b (12 ~ 33 hz)
% theta (3.5 ~ 8 hz)
% delta (1 ~ 3 hz)
% gamma (25~100 hz)

% Frequency 12-33 Hz
gamma_power =[];
Wn2= find(F>25&F<50);
Blurred_1(:,:)=Blurred_save(1,:,:);
Blurred_2(:,:)=Blurred_save(2,:,:);
Blurred_3(:,:)=Blurred_save(3,:,:);
Blurred_4(:,:)=Blurred_save(4,:,:);
Blurred_5(:,:)=Blurred_save(5,:,:);
Blurred_6(:,:)=Blurred_save(6,:,:);
Blurred_7(:,:)=Blurred_save(7,:,:);

gamma_power_1=mean(Blurred_1(Wn2,:));
gamma_power_2=mean(Blurred_2(Wn2,:));
gamma_power_3=mean(Blurred_3(Wn2,:));
gamma_power_4=mean(Blurred_4(Wn2,:));
gamma_power_5=mean(Blurred_5(Wn2,:));
gamma_power_6=mean(Blurred_6(Wn2,:));
gamma_power_7=mean(Blurred_7(Wn2,:));

gamma_power(1) = mean(gamma_power_1);
gamma_power(2) = mean(gamma_power_2);
gamma_power(3) = mean(gamma_power_3);
gamma_power(4) = mean(gamma_power_4);
gamma_power(5) = mean(gamma_power_5);
gamma_power(6) = mean(gamma_power_6);
gamma_power(7) = mean(gamma_power_7);

figure;
subplot(4,4,[1 2]),plot(T,gamma_power_1,'k');
xlabel('time(s)'), ylabel('Power()')
subplot(4,4,[3 4]),plot(T,gamma_power_2,'k');
xlabel('time(s)'), ylabel('Power()')
subplot(4,4,[5 6]),plot(T,gamma_power_3,'k');
xlabel('time(s)'), ylabel('Power()')
subplot(4,4,[7 8]),plot(T,gamma_power_4,'k');
xlabel('time(s)'), ylabel('Power()')
subplot(4,4,[9 10]),plot(T,gamma_power_5,'k');
xlabel('time(s)'), ylabel('Power()')
subplot(4,4,[11 12]),plot(T,gamma_power_6,'k');
xlabel('time(s)'), ylabel('Power()')
subplot(4,4,[13 14]),plot(T,gamma_power_7,'k');
xlabel('time(s)'), ylabel('Power()')

subplot(4,4,[15 16]),bar(gamma_power);
xlabel('channel'), ylabel('Power()');
%subtitle('gamma band')
subtitle('gamma band')

% Frequency 3.5-8 Hz
Wn3= find(F>12&F<33);
Beta_power =[];
Blurred_1(:,:)=Blurred_save(1,:,:);
Blurred_2(:,:)=Blurred_save(2,:,:);
Blurred_3(:,:)=Blurred_save(3,:,:);
Blurred_4(:,:)=Blurred_save(4,:,:);
Blurred_5(:,:)=Blurred_save(5,:,:);
Blurred_6(:,:)=Blurred_save(6,:,:);
Blurred_7(:,:)=Blurred_save(7,:,:);

Beta_power_1=mean(Blurred_1(Wn3,:));
Beta_power_2=mean(Blurred_2(Wn3,:));
Beta_power_3=mean(Blurred_3(Wn3,:));
Beta_power_4=mean(Blurred_4(Wn3,:));
Beta_power_5=mean(Blurred_5(Wn3,:));
Beta_power_6=mean(Blurred_6(Wn3,:));
Beta_power_7=mean(Blurred_7(Wn3,:));
Beta_power(1) = mean(Beta_power_1);
Beta_power(2) = mean(Beta_power_2);
Beta_power(3) = mean(Beta_power_3);
Beta_power(4) = mean(Beta_power_4);
Beta_power(5) = mean(Beta_power_5);
Beta_power(6) = mean(Beta_power_6);
Beta_power(7) = mean(Beta_power_7);

figure;
subplot(4,4,[1 2]),plot(T,Beta_power_1,'k');
xlabel('time(s)'), ylabel('Power()')
subplot(4,4,[3 4]),plot(T,Beta_power_2,'k');
xlabel('time(s)'), ylabel('Power()')
subplot(4,4,[5 6]),plot(T,Beta_power_3,'k');
xlabel('time(s)'), ylabel('Power()')
subplot(4,4,[7 8]),plot(T,Beta_power_4,'k');
xlabel('time(s)'), ylabel('Power()')
subplot(4,4,[9 10]),plot(T,Beta_power_5,'k');
xlabel('time(s)'), ylabel('Power()')
subplot(4,4,[11 12]),plot(T,Beta_power_6,'k');
xlabel('time(s)'), ylabel('Power()')
subplot(4,4,[13 14]),plot(T,Beta_power_7,'k');
xlabel('time(s)'), ylabel('Power()')

subplot(4,4,[15 16]),bar(Beta_power);
xlabel('channel'), ylabel('Power()');
subtitle('beta band')

%% save the figures 
print(figure(1),'-djpeg','1_raw_signal');
print(figure(2),'-djpeg','2_filtered_raw_signal');
print(figure(3),'-djpeg','3_STFT');
print(figure(4),'-djpeg','4_Gamma');
print(figure(5),'-djpeg','5_Beta');

%close all; clear all; clc