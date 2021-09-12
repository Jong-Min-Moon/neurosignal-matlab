ch8 = channel("ch8.csv");
ch8.bandPass([300,3000]);
ch8.detectSpikes(5,2,2);
ch8.getPCScores();
ch8.getKmeansClusters(3, 2022);
ch8.getThetas();
ch8.uniformTest()
%%
figure
subplot(2,1,1)
ch8.drawPCA()
subplot(2,1,2)
ch8.drawClusterMeanSpikes()

figure
ch8.drawRaster()

figure
ch8.drawColoredRaster()

figure
ch8.drawISI()

figure
ch8.drawCircularTheta()