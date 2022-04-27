function [meanPeakToPeak, localMaxValueSelected, localMaxLocSelected, localMinValueSelected, localMinLocSelected] = meanLocalPeakToPeak(t, signal, threshold)
    [localMaxValue, localMaxLoc] = findpeaks(signal, t);
    [localMinValue, localMinLoc] = findpeaks(-signal, t);
    
    localMaxValueSelected = localMaxValue(localMaxValue > threshold);
    localMaxLocSelected   = localMaxLoc(localMaxValue > threshold);
    localMinValueSelected = localMinValue(localMinValue > threshold);
    localMinLocSelected   = localMinLoc(localMinValue > threshold);
    
    meanPeakToPeak = mean(localMaxValueSelected) + mean(localMinValueSelected);

    localMinValueSelected = -localMinValueSelected;
end