function phaseLockingValue = getPLV(chLow, chHigh)
    phase_low = chLow.bandPhase;
    amp_high = chHigh.bandAmplitude;

    second_analytic_signal = hilbert(amp_high);
    phase_high = angle(second_analytic_signal);
    phase_diff = phase_low - phase_high;
    meanVector = mean( exp(i * phase_diff) );
    phaseLockingValue = abs(meanVector);