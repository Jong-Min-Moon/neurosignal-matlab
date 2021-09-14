
%% Figure 4.b.

                             %organoid, channel, month     
o1_ch1_m1 = channel("rawData.csv", 1, 1, 1);
o1_ch2_m1 = channel("rawData.csv", 1, 2, 1);
o1_ch1_m2 = channel("rawData.csv", 1, 1, 2);
o1_ch2_m2 = channel("rawData.csv", 1, 2, 2);

%%

o1_ch1_m1.bandPass([100,3000])
o1_ch2_m1.bandPass([100,3000])
o1_ch1_m2.bandPass([100,3000])
o1_ch2_m2.bandPass([100,3000])

o1_ch1_m1.detectSpikes(3,2,2)
o1_ch2_m1.detectSpikes(3,2,2)
o1_ch1_m2.detectSpikes(3,2,2)
o1_ch2_m2.detectSpikes(3,2,2)

