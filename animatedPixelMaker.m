classdef animatedPixelMaker < handle
    properties
        pixels
        pixelsNRow
        pixelsNCol
        endTimeMin
        startTimeMax
        matrices
        timeLength
    end
    
    methods
        function apm = animatedPixelMaker(nRow, nCol)
           
            %initialize properties
           apm.pixels = cell(nRow, nCol);
           apm.pixelsNRow = nRow;
           apm.pixelsNCol = nCol;
           apm.endTimeMin = 0;
           apm.startTimeMax = 0;
           apm.matrices = {};
       
        end
        
        function addPixel(apm, rowNum, colNum, varargin)
            fprintf("\n In the (%d, %d)th pixel,\n", rowNum, colNum)
            fireRateMakerNow = fireRateMaker();
            for i = 1:(length(varargin))
                channelObjectNow = varargin{i};
                fireRateMakerNow.addChannel(channelObjectNow);
            apm.pixels{rowNum, colNum} = fireRateMakerNow;
            end
        end
        
        function applyBandPassFilter(apm, bandRange)
            for i = 1 : apm.pixelsNRow
                for j = 1 : apm.pixelsNCol
                    apm.pixels{i,j}.applyBandpassFilter(bandRange);
                end
            end
        end %applyBandPathFilter
        
        
        function detectSpikes(apm, thres, preTime, postTime) 
            for i = 1 : apm.pixelsNRow
                for j = 1 : apm.pixelsNCol
                    apm.pixels{i,j}.detectSpikes(thres, preTime, postTime);
                end % j loop
            end % i loop
        end % function detectSpikes
        
        
        function preProcess(apm, cutoffVal, binWidth)
            % first do the preprocessing
            % cutoff and setting startTime and endTime
            for i = 1 : apm.pixelsNRow
                for j = 1 : apm.pixelsNCol
                   
                    apm.pixels{i,j}.processing(cutoffVal);
                end
            end
            
            % take max and min of startTimes and endTimes pixels,
            % to create a single timerange
            apm.setEndTimeMin();
            apm.setStartTimeMax();
            
            if apm.startTimeMax >= apm.endTimeMin
                disp("error: startTimeMax > endTimeMin")
                return
            end
            % apply the single timerange to each pixel, and calculate
            % fireing rate
            for i = 1 : apm.pixelsNRow
                for j = 1 : apm.pixelsNCol
                     
                    apm.pixels{i,j}.startTimeMax = apm.startTimeMax;
                    apm.pixels{i,j}.endTimeMin = apm.endTimeMin;
                    apm.pixels{i,j}.getFireRate(binWidth);
                end
            end
            
            sampleTH  = apm.pixels{1,1}.th;
            apm.timeLength = length(sampleTH);
            apm.matrices = cell(1, apm.timeLength);
                 
        end
        
        function setEndTimeMin(apm) 
            minNow = apm.pixels{1,1}.endTimeMin;
            for i = 1 : apm.pixelsNRow
                for j = 1 : apm.pixelsNCol    
                    valNow = apm.pixels{i,j}.endTimeMin;
                    if valNow < minNow
                        minNow = valNow;
                    end
                end
            end
            apm.endTimeMin = minNow;
        end
        
        function setStartTimeMax(apm) %step 4
            maxNow = apm.pixels{1,1}.startTimeMax;
            for i = 1 : apm.pixelsNRow
                for j = 1 : apm.pixelsNCol    
                    valNow = apm.pixels{i,j}.startTimeMax;
                    if valNow > maxNow
                        maxNow = valNow;
                    end
                end
            end
            apm.startTimeMax = maxNow;
        end
        
            
        function makeAnimatedPixels(apm, colormap)
            thMax = 0;
            for i = 1:apm.timeLength
                matrixNow = zeros(apm.pixelsNRow, apm.pixelsNCol);
                for j = 1 : apm.pixelsNRow
                    for k = 1 : apm.pixelsNCol
                        thNow = apm.pixels{j,k}.th;
                        matrixNow(j,k) = thNow(i) ;
                        
                        if apm.pixels{j,k}.thMax > thMax
                            thMax = apm.pixels{j,k}.thMax;
                        end % loop: get thMax over all pixel
                    end % k loop: over columns
                end % l loop: over rows
                apm.matrices{i} = matrixNow;
            end
            
            figure;
            for i = 1:apm.timeLength
                heatmap(apm.matrices{i}, 'ColorLimits',[0 thMax], 'Colormap', colormap);
                drawnow;
            end
            
            
            
        end% makeAnimatedPixels(apm, colormap)
        
        function RecordAnimatedPixels(apm, colormap, filename, framerate )
            thMax = 0;
            for i = 1:apm.timeLength
                matrixNow = zeros(apm.pixelsNRow, apm.pixelsNCol);
                for j = 1 : apm.pixelsNRow
                    for k = 1 : apm.pixelsNCol
                        thNow = apm.pixels{j,k}.th;
                        matrixNow(j,k) = thNow(i) ;
                        
                        if apm.pixels{j,k}.thMax > thMax
                            thMax = apm.pixels{j,k}.thMax;
                        end % loop: get thMax over all pixel
                    end % k loop: over columns
                end % l loop: over rows
                apm.matrices{i} = matrixNow;
            end
            
            figure;
            for i = 1:apm.timeLength
                heatmap(apm.matrices{i}, 'ColorLimits',[0 thMax], 'Colormap', colormap);
                F(i) = getframe(gcf);
            end
            
            v = VideoWriter(filename, 'MPEG-4');
            v.FrameRate = framerate; %1초에 xframe. 총 100 frame이라면 100/x 초짜리가 될 것.
            v.Quality = 100;

            open(v);
            writeVideo(v, F);
            close(v);
            
            
            
        end% makeAnimatedPixels(apm, colormap)
    
            
            
       
    end % methods
end %class
