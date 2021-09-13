a = averageWave(1:(end-1))
a = a - min(a)
dvdt
hold on
for i = 1: (length(dvdt)-1)
    plot([a(i), a(i+1)], [dvdt(i), dvdt(i+1)], 'k');
end
hold off