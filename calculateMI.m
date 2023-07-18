
function MI = calculateMI(phase_lo, amp_hi, n_bin)
    N = length(phase_lo);
    edges = -pi:(2*pi/n_bin):pi;
    p = repelem(0,n_bin);
    
    phase_low_disc = discretize(phase_lo, edges);
    for k = 1:n_bin
        p(k) = mean(amp_hi(phase_low_disc==k));
    end
    p = p /sum(p);
    Hp = -dot(p, log(p));
    KL = log(N) - Hp;
    MI = KL / log(N);
end

