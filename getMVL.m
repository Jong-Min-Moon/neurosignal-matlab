
function meanVectorLength = getMVL(chLow, chHigh, direct)
    phase_low = chLow.bandPhase;
    ampl_high = chHigh.bandAmplitude;
    
    if direct
        ampl_high = ampl_high / max(ampl_high);
    end
    meanVector = mean(ampl_high .* exp(i*phase_low));
    meanVectorLength = abs(meanVector);
end

