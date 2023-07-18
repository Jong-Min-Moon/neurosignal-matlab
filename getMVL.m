
function meanVectorLength = getMVL(lo, hi, isDirect)
    if isa(lo, "channel") & isa(hi, "channel")
        phase_lo = lo.bandPhase;
        amp_hi = hi.bandAmplitude;
    elseif isnumeric(lo) & isnumeric(hi)
        phase_lo = angle(lo);
        amp_hi = abs(hi);
    end
    meanVectorLength = calculateMVL(phase_lo, amp_hi, isDirect);
end

