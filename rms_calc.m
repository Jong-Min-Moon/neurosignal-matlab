%%INPUT:
% data ... 1xn (or nx1) vector, EMG signal of length n
% window (optional): window length in frames, must be an uneven number so there is a mid-point
% 
% OUTPUT:
% rms: root-mean-square of the signal
% 
% USAGE:
% Calculates the rms of a signal. The rms is calculated for the midpoint of
% a specific window size

function rms = rms_calc(data, window)

[r, c] = size(data);
if r > c
    data = data.';
end
[r, ~] = size(data);

rms = zeros(r, length(data));


if nargin < 2
    if length(data) > 100
        window = 20; 
    else
        window = 1;
    end
end

if window > length(data)
    window = 1;
    disp('Window size is bigger then data length!');
end

if ~mod(window,2)
    window = window +1;
    disp('Window size must be uneven so there is a midpoint');
end

window_RU = ceil(window/2);

for ii = 1:r
    rms_helpy = zeros(1,length(data));

    for i = window_RU:length(data) - window_RU + 1
      help_data = data(ii,i-window_RU+1 : i+window_RU-1).^2;
      rms_helpy(i) = sqrt(mean(help_data));
    end
    rms(ii,:) = rms_helpy;
end