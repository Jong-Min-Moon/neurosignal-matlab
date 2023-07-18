function meanVectorLength = calculateMVL(phase_lo, amp_hi, isDirect)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here   
    if isDirect
        amp_hi = amp_hi / max(amp_hi);
    end
    meanVector = mean(amp_hi .* exp(1i*phase_lo));
    meanVectorLength = abs(meanVector);
end