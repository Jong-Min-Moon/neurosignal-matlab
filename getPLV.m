function phaseLockingValue = getPLV(lo, hi)
    if isa(lo, "channel") & isa(hi, "channel")
        phase_lo = lo.bandPhase;
        amp_hi = hi.bandAmplitude;
    elseif isnumeric(lo) & isnumeric(hi)
        phase_lo = angle(lo);
        amp_hi = abs(hi);
    end

    phaseLockingValue = calculatePLV(phase_lo, amp_hi);
end