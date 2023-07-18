function phaseLockingValue = calculatePLV(phase_lo, amp_hi)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
    second_analytic_signal = hilbert(amp_hi);
    phase_high = angle(second_analytic_signal);
    phase_diff = phase_lo - phase_high;
    meanVector = mean( exp(1i * phase_diff) );
    phaseLockingValue = abs(meanVector);
end