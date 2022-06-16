classdef timeVaryingHeatmapEMG < timeVaryingHeatmap
    properties
        maxRaw                       
        maxFiltered
        maxSignalRawLowBaseline    
        maxSignalRawNoBaseline     
        maxSignalFilteredLowBaseline 
        maxSignalFilteredNoBaseline  
        datatypeInfo
        videoNow
    end
    
    methods
        function apm = timeVaryingHeatmapEMG(nRow, nCol)
           apm@timeVaryingHeatmap(nRow, nCol); %explicitly call the constructor of the superclass   


           % save datatype info
           keySet = {
            'raw',
            'filtered',
            'signalRawLowBaseline',
            'signalRawNoBaseline',
            'signalFilteredLowBaseline',
            'signalFilteredNoBaseline'
            };
           valueSet = {
            'baseline filtering 하지 않음, butterworth filtering도 하지 않음',
            'baseline filtering 하지 않고, butterworth filtering은 함',
            'baseline filtering 하고, butterworth filtering은 안함',
            'baseline filtering 해서 baseline 부분 0으로 만들고, butterworth filtering은 안함',
            'baseline filtering 하고, butterworth filtering 함',
            'baseline filtering 해서 baseline 부분 0으로 만들고, butterworth filtering 함'
            };
           
           apm.datatypeInfo = containers.Map(keySet,valueSet);
           fprintf("created an object with %d rows and %d columns", nRow, nCol)
        end
        
        
        % Redefine Inherited methods
        function addPixel(apm, rowNum, colNum, channelObject)
            fprintf("\n In the (%d, %d)th slot, added channel %d \n", rowNum, colNum, channelObject.channelNum)  
            apm.pixels{rowNum, colNum} = channelObject;
        end
        
        %% filters
        function bandPass(apm, bandRange)
            for i = 1 : apm.pixelsNRow
                for j = 1 : apm.pixelsNCol
                    apm.pixels{i,j}.bandPass(bandRange);
                end
            end
        end 
        
        function highPassButterworth(apm, order, cutoff)
            %cutoff of high-pass filter = lower bound
            for i = 1 : apm.pixelsNRow
                for j = 1 : apm.pixelsNCol
                    apm.pixels{i,j}.highPassButterworth(order, cutoff);
                end
            end
        end 
        
        function notchButterworth(apm, order, notch)
            %cutoff of high-pass filter = lower bound
            for i = 1 : apm.pixelsNRow
                for j = 1 : apm.pixelsNCol
                    apm.pixels{i,j}.notchButterworth(order, notch);
                end
            end
        end
        
        function normalizeEnvelope(apm, maxEnvValue)
            for i = 1 : apm.pixelsNRow
                for j = 1 : apm.pixelsNCol
                    apm.pixels{i,j}.normalizeEnvelope(maxEnvValue);
                end
            end
        end
        %%
        
        
        
        
        
        function filterBaseline(apm, baselineTimeIntervals, passBand)
            for i = 1 : apm.pixelsNRow
                for j = 1 : apm.pixelsNCol
                    apm.pixels{i,j}.filterBaseline(baselineTimeIntervals, passBand);
                end
            end
        end
                      

       



        
        
        
        
        %%
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
                    apm.pixels{i,j}.rectify();
                end
          end 
        end
        















        
        function envelope(apm, parameter, method)
          for i = 1 : apm.pixelsNRow
                for j = 1 : apm.pixelsNCol
                    apm.pixels{i,j}.envelope(parameter, method);
                end
          end
          
          % get max signal for each of six.
                      
          maxRaw                       = apm.pixels{1,1}.rawEnvelopedMax
          maxFiltered                  = apm.pixels{1,1}.filteredEnvelopedMax  
          maxSignalRawLowBaseline      = apm.pixels{1,1}.signalRawLowBaselineEnvelopedMax
          maxSignalRawNoBaseline       = apm.pixels{1,1}.signalRawNoBaselineEnvelopedMax
          maxSignalFilteredLowBaseline = apm.pixels{1,1}.signalFilteredLowBaselineEnvelopedMax
          maxSignalFilteredNoBaseline  = apm.pixels{1,1}.signalFilteredNoBaselineEnvelopedMax

          %1. update max raw signal
for j = 1 : apm.pixelsNRow % loop over 
    for k = 1 : apm.pixelsNCol
        maxNow = apm.pixels{j,k}.rawEnvelopedMax;
        if maxNow > maxRaw
            maxRaw = maxNow;
        end 
    end % loop over columns
end % loop over rows
apm.maxRaw = maxRaw %save results

%2. filtered
  
  for j = 1 : apm.pixelsNRow % loop over 
    for k = 1 : apm.pixelsNCol
        maxNow = apm.pixels{j,k}.filteredEnvelopedMax;
        if maxNow > maxFiltered
            maxFiltered = maxNow;
        end 
    end % loop over columns
end % loop over rows
apm.maxFiltered = maxFiltered %save results

%3
for j = 1 : apm.pixelsNRow % loop over 
    for k = 1 : apm.pixelsNCol
        maxNow = apm.pixels{j,k}.signalRawLowBaselineEnvelopedMax;
        if maxNow > maxSignalRawLowBaseline
            maxSignalRawLowBaseline = maxNow;
        end 
    end % loop over columns
end % loop over rows
apm.maxSignalRawLowBaseline = maxSignalRawLowBaseline %save results
     
%4
for j = 1 : apm.pixelsNRow % loop over 
    for k = 1 : apm.pixelsNCol
        maxNow = apm.pixels{j,k}.signalRawNoBaselineEnvelopedMax;
        if maxNow > maxSignalRawNoBaseline
            maxSignalRawNoBaseline = maxNow;
        end 
    end % loop over columns
end % loop over rows
apm.maxSignalRawNoBaseline = maxSignalRawNoBaseline %save results
         


%5
% update max raw signal
for j = 1 : apm.pixelsNRow % loop over 
    for k = 1 : apm.pixelsNCol
        maxNow = apm.pixels{j,k}.signalFilteredLowBaselineEnvelopedMax;
        if maxNow > maxSignalFilteredLowBaseline
            maxSignalFilteredLowBaseline = maxNow;
        end 
    end % loop over columns
end % loop over rows
apm.maxSignalFilteredLowBaseline = maxSignalFilteredLowBaseline%save results

%6
% update max raw signal
for j = 1 : apm.pixelsNRow % loop over 
    for k = 1 : apm.pixelsNCol
        maxNow = apm.pixels{j,k}.signalFilteredNoBaselineEnvelopedMax;
        if maxNow > maxSignalFilteredNoBaseline
            maxSignalFilteredNoBaseline = maxNow;
        end 
    end % loop over columns
end % loop over rows
apm.maxSignalFilteredNoBaseline = maxSignalFilteredNoBaseline %save results


        end % end of method envelope
        % 
        % 
















    function makeTimeVaryingHeatmap(apm, timeInterval, datatype, displaynumber, colormap)
        msPerTs = apm.pixels{1,1}.msPerTs;
        nTimestamps = apm.pixels{1,1}.nTimestamps;
        stepSize = round(timeInterval / msPerTs);
        nSteps = fix(nTimestamps/stepSize);
        duration = apm.pixels{1,1}.durationApprox; %second
        realTimeFramerate = (nTimestamps/(timeInterval / msPerTs))/(duration);
        
        
        
        % numberofFrames = duration * framerate

        % print info for the user
        fprintf("* datatype = ")
        fprintf(datatype)
        fprintf(" (" + apm.datatypeInfo(datatype) + ")")
        fprintf("\n* Each step consists of %d timestamps = %f miliseconds\n", stepSize, stepSize*msPerTs)
        fprintf("* Total %d steps\n", nSteps)
        fprintf("* Total timelength = %d seconds\n", duration)
        fprintf("* realtime framerate per second = %d \n", realTimeFramerate)
        
        % create matrices
        apm.matrices = cell(1, nSteps);
    
        for i = 1:nSteps % loop over each step
            matrixNow = zeros(apm.pixelsNRow, apm.pixelsNCol);%initialize a matrix for this step
            timestampNow = 1 + (i-1)*stepSize;
            for j = 1 : apm.pixelsNRow % loop over 
                for k = 1 : apm.pixelsNCol
                    %%%%%%%
                    if datatype == "raw"
                        envelopeValueNow = apm.pixels{j,k}.rawEnveloped(timestampNow);
                    elseif datatype == "filtered"
                        envelopeValueNow = apm.pixels{j,k}.filteredEnveloped(timestampNow);
                    elseif datatype == "signalRawLowBaseline"
                        envelopeValueNow = apm.pixels{j,k}.signalRawLowBaselineEnveloped(timestampNow);
                    elseif datatype == "signalRawNoBaseline"
                        envelopeValueNow = apm.pixels{j,k}.signalRawNoBaselineEnveloped(timestampNow);
                    elseif datatype == "signalFilteredLowBaseline"
                        envelopeValueNow = apm.pixels{j,k}.signalFilteredLowBaselineEnveloped(timestampNow);
                    elseif datatype == "signalFilteredNoBaseline"
                        envelopeValueNow = apm.pixels{j,k}.signalFilteredNoBaselineEnveloped(timestampNow);
                    end %end of if statements
            
                    
                    %%%%%%%%
                    matrixNow(j, k) = envelopeValueNow;
                end % loop over columns
            end % loop over rows
            apm.matrices{i} = matrixNow;
        end % loop over steps
        
    
        % draw a time-varying heatmap
        %%%%%%
        if datatype == "raw"
            maxSignal = apm.maxRaw;
        elseif datatype == "filtered"
            maxSignal = apm.maxFiltered;
        elseif datatype == "signalRawLowBaseline"
            maxSignal = apm.maxSignalRawLowBaseline;
        elseif datatype == "signalRawNoBaseline"
            maxSignal = apm.maxSignalRawNoBaseline;
        elseif datatype == "signalFilteredLowBaseline"
            maxSignal = apm.maxSignalFilteredLowBaseline;
        elseif datatype == "signalFilteredNoBaseline"
            maxSignal = apm.maxSignalFilteredNoBaseline;
        end %end of if statements
    
    
                                       
                
                %%%%%%
        fprintf("* max signal value = %f, ColorLimits is set w.r.t this value.", maxSignal)
          

 
   

        figure;
        for i = 1:nSteps
             %%% heatmap 옵션 수정 시 아래 라인을 수정하세요 %%%
             if displaynumber
                heatmap(apm.matrices{i}, 'ColorLimits',[0 maxSignal], 'Colormap', colormap);
                
                %frame을 이미지 파일로 저장
                exportgraphics(gcf, "step" + i + ".jpg");
                
                %frame을 비디오에 저장
             else
                 heatmap(apm.matrices{i}, 'ColorLimits',[0 maxSignal], 'Colormap', colormap, 'CellLabelColor','none');

                 %frame을 이미지 파일로 저장
                 exportgraphics(gcf, "step" + i + ".jpg");
                 %frame을 비디오에 저장
             end % end of if statements
            
            drawnow;

    
        end % end for for loops
                    

        
        
        

    end      % end of this method

        function saveTimeVaryingHeatmap(apm, timeInterval, datatype, displaynumber, colormap, filename)
        msPerTs = apm.pixels{1,1}.msPerTs;
        nTimestamps = apm.pixels{1,1}.nTimestamps;
        stepSize = round(timeInterval / msPerTs);
        nSteps = fix(nTimestamps/stepSize);
        duration = apm.pixels{1,1}.durationApprox; %second
        realTimeFramerate = (nTimestamps/(timeInterval / msPerTs))/(duration);
        
        
        
        % numberofFrames = duration * framerate

        % print info for the user
        fprintf("* datatype = ")
        fprintf(datatype)
        fprintf(" (" + apm.datatypeInfo(datatype) + ")")
        fprintf("\n* Each step consists of %d timestamps = %f miliseconds\n", stepSize, stepSize*msPerTs)
        fprintf("* Total %d steps\n", nSteps)
        fprintf("* Total timelength = %d seconds\n", duration)
        fprintf("* realtime framerate per second = %d \n", realTimeFramerate)
        
        % create matrices
        apm.matrices = cell(1, nSteps);
    
        for i = 1:nSteps % loop over each step
            matrixNow = zeros(apm.pixelsNRow, apm.pixelsNCol);%initialize a matrix for this step
            timestampNow = 1 + (i-1)*stepSize;
            for j = 1 : apm.pixelsNRow % loop over 
                for k = 1 : apm.pixelsNCol
                    %%%%%%%
                    if datatype == "raw"
                        envelopeValueNow = apm.pixels{j,k}.rawEnveloped(timestampNow);
                    elseif datatype == "filtered"
                        envelopeValueNow = apm.pixels{j,k}.filteredEnveloped(timestampNow);
                    elseif datatype == "signalRawLowBaseline"
                        envelopeValueNow = apm.pixels{j,k}.signalRawLowBaselineEnveloped(timestampNow);
                    elseif datatype == "signalRawNoBaseline"
                        envelopeValueNow = apm.pixels{j,k}.signalRawNoBaselineEnveloped(timestampNow);
                    elseif datatype == "signalFilteredLowBaseline"
                        envelopeValueNow = apm.pixels{j,k}.signalFilteredLowBaselineEnveloped(timestampNow);
                    elseif datatype == "signalFilteredNoBaseline"
                        envelopeValueNow = apm.pixels{j,k}.signalFilteredNoBaselineEnveloped(timestampNow);
                    end %end of if statements
            
                    
                    %%%%%%%%
                    matrixNow(j, k) = envelopeValueNow;
                end % loop over columns
            end % loop over rows
            apm.matrices{i} = matrixNow;
        end % loop over steps
        
    
        % draw a time-varying heatmap
        %%%%%%
        if datatype == "raw"
            maxSignal = apm.maxRaw;
        elseif datatype == "filtered"
            maxSignal = apm.maxFiltered;
        elseif datatype == "signalRawLowBaseline"
            maxSignal = apm.maxSignalRawLowBaseline;
        elseif datatype == "signalRawNoBaseline"
            maxSignal = apm.maxSignalRawNoBaseline;
        elseif datatype == "signalFilteredLowBaseline"
            maxSignal = apm.maxSignalFilteredLowBaseline;
        elseif datatype == "signalFilteredNoBaseline"
            maxSignal = apm.maxSignalFilteredNoBaseline;
        end %end of if statements
    
    
                                       
                
                %%%%%%
        fprintf("* max signal value = %f, ColorLimits is set w.r.t this value.", maxSignal)
          

 
   

        figure;
        for i = 1:nSteps
             %%% heatmap 옵션 수정 시 아래 라인을 수정하세요 %%%
             if displaynumber
                heatmap(apm.matrices{i}, 'ColorLimits',[0 maxSignal], 'Colormap', colormap);
                
                %frame을 비디오에 저장
                frame(i) = getframe(gcf);
             else
                 heatmap(apm.matrices{i}, 'ColorLimits',[0 maxSignal], 'Colormap', colormap, 'CellLabelColor','none');

                 %frame을 비디오에 저장
                 frame(i) = getframe(gcf);
             end % end of if statements
            
            
        
    
        end % end for for loops
        v = VideoWriter(filename, 'MPEG-4');
        v.FrameRate = realTimeFramerate;
        open(v);
        writeVideo(v,frame);
        fprintf("* video duration = %d seconds\n", v.Duration )

        close(v);
  

        
        
        
        

    end      % end of this method
        
    


%     
%     v.FrameRate = realTimeFramerate;
%     v.Quality = 100;
% 
%     open(v);
%     writeVideo(v, F);
%     close(v);


    

        
    
            
            
       
    end % methods
end %class
