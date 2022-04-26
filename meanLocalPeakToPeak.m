function result = meanLocalPeakToPeak(t, signal)
    [localMaxValues, ] = findpeaks(signal, t);
    [localMinValues, ] = findpeaks(-signal, t);
    result = mean(localMaxValues) + mean(localMinValues);
end