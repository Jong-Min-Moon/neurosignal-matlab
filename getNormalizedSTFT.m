function [normalized_stft, F, T] = getNormalizedSTFT(rawSignalNow, Fs_float)    
    %아래는 LFP_severance.mlx 파일의 처리 과정을 그대로 진행합니다. 단, lowe pass filtering은 이미 데이터
    %불러오기 단계에서 했으므로 생략하겠습니다.
    Fs = double(int16(Fs_float));
    % Filtering (low pass filter for LFP)
    Trec = 60;
    %Fc = 300; %300
    %[b,a] = butter(4,Fc/(Fs/2),'low');
    %lpf_data= filtfilt(b,a,rawSignalNow);
    %clear a b
            
    % Desampling 1000 Hz
    dFs = 1000;
    lpf_data_de = resample(rawSignalNow, dFs, Fs);
    x_de= 1/dFs:1/dFs:length(lpf_data_de)/dFs;
            
    % STFT 생성
    R= 500; %500                 % welch window size=  1초
    noverlap = R/2;          % 50 % overlap (1.25로 나누면 좀더 촘촘해짐, 2)
    window1= hanning(R);
    NFFT =2048*4;              %2^nextpow2(L);
    
    [S, F, T]= spectrogram(lpf_data_de, window1, noverlap, NFFT, dFs);
    
    before_fin = floor(double(length(T)*(20/Trec)));
    before_stft = abs(S(:,1:before_fin));
    during_after_stft= abs(S(:,1:end));
            
    baseline_value= mean(before_stft,2);
    mul= ones(1,length(T));
    baseline_matrix= baseline_value*mul;
            
    % Normalizaed STFT: (X-baseline)/baseline
    normalized_stft= (during_after_stft-baseline_matrix)./baseline_matrix;
end