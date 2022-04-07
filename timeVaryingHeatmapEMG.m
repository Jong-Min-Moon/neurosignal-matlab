classdef timeVaryingHeatmapEMG < timeVaryingHeatmap
    properties
        maxSignalFiltered
        maxSignalRaw
    
    methods
        function apm = timeVaryingHeatmapEMG(nRow, nCol)
           apm@timeVaryingHeatmap(nRow, nCol) %explicitly call the constructor of the superclass       
        end
        
        
        % Redefine Inherited methods
        function addPixel(apm, rowNum, colNum, channelObject)
            fprintf("\n In the (%d, %d)th slot, added channel %d \n", rowNum, colNum, channelObject.channelNum)  
            apm.pixels{rowNum, colNum} = channelObject;
        end
        
        function applyBandPassFilter(apm, bandRange)
            for i = 1 : apm.pixelsNRow
                for j = 1 : apm.pixelsNCol
                    apm.pixels{i,j}.bandPass(bandRange);
                end
            end
        end %applyBandPathFilter
        
        
           
        function cutTime(apm, timeInterval)
            cutStart = timeInterval(1);
            cutEnd = timeInterval(2);
                        
            % take max and min of startTimes and endTimes pixels,
            % to create a single timerange
            apm.setEndTimeMin();
            apm.setStartTimeMax();
            
            if apm.startTimeMax >= apm.endTimeMin
                error("startTimeMax > endTimeMin")
            end
            if apm.startTimeMax > cutStart
                error("cut start time을 더 뒤쪽으로 조정하세요.")
            end
            if apm.endTimeMin < cutEnd
                error("cut end time을 더 앞쪽으로 조정하세요.")
            end
            
            % apply the single timerange to each pixel
            for i = 1 : apm.pixelsNRow
                for j = 1 : apm.pixelsNCol
                    fprintf("\ncutting the time of (%d, %d)th element = channel %d\n", i, j, apm.pixels{i,j}.channelNum)
                    apm.pixels{i,j}.cutTime(timeInterval);
                end
            end
            
            % check if everything's okay
            startTimeCheck = apm.pixels{i,j}.startTime;
            endTimeCheck = apm.pixels{i,j}.endTimeApprox;
            for i = 1 : apm.pixelsNRow
                for j = 1 : apm.pixelsNCol
                    if startTimeCheck ~= apm.pixels{i,j}.startTime
                        error("starTime not synchronized")
                    end % startTime check
                    if endTimeCheck ~= apm.pixels{i,j}.endTimeApprox
                        error("endTime not synchronized")
                    end % endTime check
                end % loop over columns
            end % loop over rows           
        end % end for the function
        
        function setEndTimeMin(apm) 
            minNow = apm.pixels{1,1}.endTimeApprox;
            for i = 1 : apm.pixelsNRow
                for j = 1 : apm.pixelsNCol    
                    valNow = apm.pixels{i,j}.endTimeApprox;
                    if valNow < minNow
                        minNow = valNow;
                    end
                end
            end
            apm.endTimeMin = minNow;
        end
        
        function setStartTimeMax(apm) %step 4
            maxNow = apm.pixels{1,1}.startTime;
            for i = 1 : apm.pixelsNRow
                for j = 1 : apm.pixelsNCol    
                    valNow = apm.pixels{i,j}.startTime;
                    if valNow > maxNow
                        maxNow = valNow;
                    end
                end
            end
            apm.startTimeMax = maxNow;
        end
        
        function rectify(apm)
          for i = 1 : apm.pixelsNRow
                for j = 1 : apm.pixelsNCol
                    apm.pixels{i,j}.rectify()
                end
          end 
        end
        
        function envelope(apm, windowSize)
          for i = 1 : apm.pixelsNRow
                for j = 1 : apm.pixelsNCol
                    apm.pixels{i,j}.envelope(windowSize)
                end
          end
          
          % get max signal
                      
          maxSignalFiltered = apm.pixels{1,1}.signalFilteredEnvelopedMax;
          maxSignalRaw = apm.pixels{1,1}.signalRawEnvelopedMax;
                
          for j = 1 : apm.pixelsNRow % loop over 
              for k = 1 : apm.pixelsNCol
                  
                  % update max filtered signal
                  signalFilteredEnvelopedMaxNow = apm.pixels{j,k}.signalFilteredEnvelopedMax;
                  if signalFilteredEnvelopedMaxNow > maxSignalFiltered
                      maxSignalFiltered = signalFilteredEnvelopedMaxNow;
                  end
                  
                  % update max raw signal
                  signalRawEnvelopedMaxNow = apm.pixels{j,k}.signalRawEnvelopedMax;
                  if signalRawEnvelopedMaxNow > maxSignalRaw
                      maxSignalRaw = signalRawEnvelopedMaxNow;
                  end     
              end % loop over columns
          end % loop over rows
          apm.maxSignalFiltered = maxSignalFiltered;
          apm.maxSignalRaw = maxSignalRaw;
        end % end of method envelope
        
            
            
            
        function makeTimeVaryingHeatmap(apm, timeInterval, filtered, colormap)
            msPerTs = apm.pixels{1,1}.msPerTs
            nTimestamps = apm.pixels{1,1}.nTimestamps
            stepSize = round(timeInterval / msPerTs)
            nSteps = nTimestamps/stepSize
            
            % print info for the user
            fprintf("step size = %d timestamps = %f miliseconds\n", stepSize, stepSize*msPerTs)
            fprintf("Total %d steps\n", nSteps)
            
            
            % create matrices
            apm.matrices = cell(1, nSteps);
            
            for i = 1:nSteps % loop over each step
                matrixNow = zeros(apm.pixelsNRow, apm.pixelsNCol);%initialize a matrix for this step
                
                for j = 1 : apm.pixelsNRow % loop over 
                    for k = 1 : apm.pixelsNCol
                        if filtered
                            envelopeValueNow = apm.pixels{j,k}.signalFilteredEnveloped(i);
                        else
                            envelopeValueNow = apm.pixels{j,k}.signalRawEnveloped(i);
                        end
                        matrixNow(j, k) = envelopeValueNow;
                    end % loop over columns
                end % loop over rows
                apm.matrices{i} = matrixNow;
            end % loop over steps
                
            
            % draw a time-varying heatmap
            
            if filtered
                maxSignal = apm.maxSignalFiltered;
            else
                maxSignal = apm.maxSignalRaw;
            end
            
                
            
            fprintf("max signal value = %f, ColorLimits is set w.r.t this value.", maxSignal)
                        
            figure;
            for i = 1:nSteps
                 %%% heatmap 옵션 수정 시 아래 라인을 수정하세요 %%%
                heatmap(apm.matrices{i}, 'ColorLimits',[0 maxSignal], 'Colormap', colormap);
                drawnow;
            end
            
            
            
        end
        
        function recordTimeVaryingHeatmap(apm, colormap, filename, framerate )
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
                %%% heatmap 옵션 수정 시 아래 라인을 수정하세요 %%%
                heatmap(apm.matrices{i}, 'ColorLimits',[0 thMax], 'Colormap', colormap);
                F(i) = getframe(gcf);
            end
            
            v = VideoWriter(filename, 'MPEG-4');
            v.FrameRate = framerate; %1초에 xframe. 총 100 frame이라면 100/x 초짜리가 될 것.
            v.Quality = 100;

            open(v);
            writeVideo(v, F);
            close(v);
            
            
            
        end
    
            
            
       
    end % methods
end %class
