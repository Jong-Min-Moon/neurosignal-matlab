function meanVectorLength = getMVL(chLow, chHigh)
    phase = chLow.bandPhase;
    amplitude = chHigh.bandAmplitude;
    meanVector = mean(amplitude .* exp(i*phase));
    meanVectorLength = abs(meanVector);
end
