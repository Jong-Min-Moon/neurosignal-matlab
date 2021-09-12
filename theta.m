[tResampled, yResampled, msPerTimestamp, desiredSamplingFrequency] = loadResample("raw data.csv");

%apply 4-8 Hz frequency band
passbandFrequency = [4, 8];
yFiltered = bandpass(yResampled, passbandFrequency, desiredSamplingFrequency);

%phase caculation through Hilbert transform
yHilbert = hilbert(yFiltered);
thetaPhase = angle(yHilbert);


plot(tResampled, thetaPhase)

%figure 2.k
plot(tResampled, yResampled)
hold on
plot(tResampled, yFiltered)
hold off
legend('Raw trace', 'Theta waves')