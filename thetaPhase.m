function theta = thetaPhase(yResampled, desiredSamplingFrequency)

%apply 4-8 Hz frequency band
passbandFrequency = [4, 8];
yFiltered = bandpass(yResampled, passbandFrequency, desiredSamplingFrequency);

%phase caculation through Hilbert transform
yHilbert = hilbert(yFiltered);
theta = angle(yHilbert);

%figure 2.k
%plot(tResampled, yResampled)
%hold on
%plot(tResampled, yFiltered)
%hold off
%legend('Raw trace', 'Theta waves')