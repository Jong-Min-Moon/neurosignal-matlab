
function MI = getMI(chLow, chHigh, n_bin)
    phase_low = chLow.bandPhase;
    amp_high = chHigh.bandAmplitude;
 
    N = length(phase_low);
    edges = -pi:(2*pi/n_bin):pi;
    p = repelem(0,n_bin);
    
    phase_low_disc = discretize(phase_low, edges);
    for k = 1:n_bin
        p(k) = mean(amp_high(phase_low_disc==k));
    end
    p = p /sum(p);
    Hp = -dot(p, log(p));
    KL = log(N) - Hp;
    MI = KL / log(N);
end

