


%% 원 위를 움직이는 점

%
theta = linspace(0, 2*pi, 100);


x = cos(theta); % 벡터
y = sin(theta); % 벡터 
plot(x,y)
axis square  
hold on;

% 움직이는 점 

for i = 1:length(theta)
        plot(x,y, 'b')
        axis square
        
        hold on;
        plot(x(i), y(i), 'o', 'markerfacecolor', 'r', 'markersize', 15)
        axis square 
        pause(0.1)
        hold off;
end

% drawnow는 pause를 대체함.


%% sine wave 위를 지나는 점

figure;

t = linspace(0, 3, 100);
x = sin(2*pi*1*t)
plot(t, x, 'b');

hold on;
for i = 1:length(t)
    plot(t, x, 'b');
    hold on;
    plot(t(i), x(i), 'o', 'markerfacecolor', 'r', 'markersize', 15)
    drawnow;
    hold off;
end

%% sine wave 자체가 움직이는 그림

figure;

t = linspace(0, 3, 100);
delay = linspace(0, 2*pi, 100) %점 개수 늘려주면 더 천천히 움직
x = sin(2*pi*1*t)
        %2pi곱해주면 주기가 1이 됨  
        % pi 뒤의 값은 주파수. 2를 곱하면 1초에 두 번 진동.
for i = 1:length(delay)
    x = sin(2*pi*1*t - delay(i))
    plot(t, x, 'b')
    drawnow;
    hold off;
end


%% 녹화하기

%% sine wave 자체가 움직이는 그림

figure;

t = linspace(0, 3, 100);
delay = linspace(0, 2*pi, 100) %점 개수 늘려주면 더 천천히 움직
x = sin(2*pi*1*t)
        %2pi곱해주면 주기가 1이 됨  
        % pi 뒤의 값은 주파수. 2를 곱하면 1초에 두 번 진동.
for i = 1:length(delay)
    x = sin(2*pi*1*t - delay(i))
    plot(t, x, 'b')
    %drawnow;
    F(i) = getframe(gcf);
    hold off;
end

v = VideoWriter('test.mp4', 'MPEG-4');
v.FrameRate = ;%1초에 30frame. 위에서 100 frame으로 했으니까 3.3초짜리가 될 것.
v.Quality = 100;

open(v);
writeVideo(v, F);
close(v);


%%
x = [1,2,3;2,4,7;3,7,6];
y = [9,3,2;1,3,5;4,4,7];
M = cell(2, 1);

M{1} = x
M{2} = y


figure;
for i = 1:length(matrices)
    j = mod(i,2) + 1
    heatmap(M{j})
    drawnow;
end