
function MI = getMI(lo, hi, n_bin)
    if isa(lo, "channel") & isa(hi, "channel")
        phase_lo = lo.bandPhase;
        amp_hi = hi.bandAmplitude;
    elseif isnumeric(lo) & isnumeric(hi)
        phase_lo = angle(lo);
        amp_hi = abs(hi);
    end
 MI = calculateMI(phase_lo, amp_hi, n_bin);
end

