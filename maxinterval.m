function bursts = detectBurstsMI(ch, begISI, endISI, minIBI, minDurn, minSpikes)
% input:
% - one spike train
% - begISI : maximum interval to start burst; max ISI at start of burst; Beginning inter spike interval
% - endISI : maximum interval to end burst; max ISI in burst; Ending inter spike interval
% - minIBI: minimum interval between bursts (threshold for combining bursts)
% - minDurn: minimum duration of a burst; minimum duration to consider as burst
% - minSpikes: minimum number of spikes in burst; minimum number of spikes to consider as burst

% output: bursts found using max interval method.
  
  ## .find.bursts(s$spikes[[5]])
  ## init.
  ## params currently in MI.PAR
  

  %%noBursts = NA;                       #value to return if no bursts found.
  noBursts = [];

  nspikes = ch.nSpikes;
  spikes = ch.spikeTimestamps;
  % Create a temp array for the storage of the bursts.  Assume that
  % it will not be longer than Nspikes/2 since we need at least two
  % spikes to be in a burst.
  
  maxBursts = floor(nspikes/2);
  bursts = NaN(maxBursts, 3)
  bursts = array2table(bursts, 'VariableNames',{'beg','end','IBI'});

  burst = 0;                            % current burst number


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Phase 1 -- burst detection.
  % 
  % parameters used: begISI, endISI
  %
  % when two consecutive spikes have an ISI *less* than begISI apart.
  % i.e. if nextISI < begISI,
  % a burst is defined as starting.
  %
  % The end of the burst is given  
  % when two spikes have an ISI *greater* than endISI,
  % i.e. if nextISI > endISI.
  % 
  
  % Find ISIs closer than begISI, and end with endISI.


  % lastEnd is the time of the last spike in the previous burst.
  % This is used to calculate the IBI.
  % For the first burst, this is no previous IBI
  lastEnd = NaN;                        #for first burst, there is no IBI.

  n = 2;
  isInBurst = FALSE;
  
  while n <= nspikes

    nextISI = spikes(n) - spikes(n-1)
    if isInBurst
      
      % end of burst
      if nextISI > endISI
        endStamp = n - 1;
        isInBurst = FALSE;
        ibi =  spikes(beg) - lastEnd;
        lastEnd = spikes(endStamp);
        res = [beg, endStamp, ibi];
        burst = burst + 1;

        % fail case
        if burst > maxBursts
          print("too many bursts!!! algorithm failed.")
          return
        end %end of {if burst > maxBursts}
        

        bursts(burst,) = res;
      end % end of {nextISI > endISI}
        
    else % else of {if isInBurst}, i.e. not yet in burst
      
      % Found the start of a new burst.
      if nextISI < begISI  
        beg = n - 1;
        isInBurst = TRUE;
      end % end of {nextISI < begISI}

    end % end of {if isInBurst}
    n = n + 1;
  end %end of while n <= nspikes

  %% At the end of the burst, check if we were in a burst when the train finished.
  if isInBurst
    endStamp = nspikes;
    ibi =  spikes[beg] - lastEnd;
    res = [beg, endStamp, ibi];
    burst = burst + 1;

    % fail case
    if burst > maxBursts
      print("too many bursts!!! algorithm failed.")
      return
    end % end of if burst > maxBursts

    bursts[burst,] <- res
    end % end of if isInBurst

  % Check if any bursts were found.
  if burst > 0 
    % truncate to right length, as bursts will typically be very long.
    % (since we initated bursts with nrow = maxBursts)
    bursts = bursts(1:burst, :);
  else
    %% no bursts were found, so return an empty structure.
    return(noBursts)
  end %end of {burst > 0} 
  





  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %% Phase 2 -- merging of bursts.
  %%
  %% parameters used : minIBI
  %%
  %% Here we see if any pair of bursts have an IBI *less* than minIBI; 
  %% if so, we then merge the bursts.
  %% We specifically need to check when say three bursts are merged into one.

  
  ibis = bursts( ,"IBI") %%수정 필요
  isMergeNeeded = ibis < minIBI;
  isAnyMergeNeeded = sum(isMergeNeeded)
  if isAnyMergeNeeded > 1
    % Merge bursts efficiently.
    % Work backwards through the list, 
    % and then delete the merged lines afterwards.  
    % This works when we have say 3+ consecutive bursts that merge into one.
    mergeIndex = find(isMergeNeeded);
    mergeIndexRev = flip(mergeIndex)

    for burst in mergeIndexRev
      bursts(burst-1, "end") = bursts(burst, "end") %move the information one step forward.
      bursts(burst  , "end") = NaN         %not needed, but helpful.
    end %end or for loop

    bursts = bursts(not(isMergeNeeded) , : ) % delete the unwanted info.
  end % end of {sum(mergeBursts) > 1}



  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %% Phase 3 -- remove small bursts
  %% 
  %% parameters used : minDurn, minSpikes
  %% 
  %% delete small bursts i.e.
  %% less than min duration (minDurn), or
  %% having too few spikes (less than minSpikes).
  %% In this phase we have the possibility of deleting all spikes.

  % LEN = number of spikes in a burst.
  % DURN = duration of burst.
  len = bursts( , "end") - bursts( , "beg") + 1;
  durn = spikes(bursts( , "end")) - spikes(bursts( , "beg"));
  bursts = table2array(bursts);
  bursts = [bursts, len, durn];
  bursts = array2table(bursts, 'VariableNames',{'beg','end','IBI', 'len', 'durn'});

  IsReject = ((durn < minDurn) | ( len < minSpikes));
  isAnyRejects = sum(IsReject);
  rejectsIndex = find(IsReject);

  % delete small bursts
  if isAnyRejects > 1
    bursts = bursts(not(rejectsIndex) , : );
  end % end of if isAnyRejects

  nBursts = size(bursts);
  nBursts = nBursts(1);
  if nBursts == 0 % if all the bursts were removed during phase 3.
    bursts = noBursts
  else % else of {nBursts == 0}
    % Compute mean ISIS
    len = bursts( , "end") - bursts( , "beg") + 1;
    durn = spikes( bursts( , "end") ) - spikes( bursts( , "beg") );
    meanISI = durn / (len-1);

    % Recompute IBI (only needed if phase 3 deleted some cells).
    if nBursts > 1 
      ibiBeg = spikes( bursts( , "beg") );
      ibiBeg = ibiBeg(2:nBursts);
      ibiEnd = spikes( bursts( , "end");
      ibiEnd = ibiEnd(1:(nBursts-1));

      ibi2 = ibiBeg - ibiEnd;
      ibi2 = [NaN, ibi2]
    else
      ibi2 = NaN;
    end
    bursts(,"IBI") = ibi2;
    
    SI = ones(length(meanISI))

    bursts = table2array(bursts);
    bursts = [bursts, meanISI, SI];
    bursts = array2table(bursts, 'VariableNames',{'beg','end','IBI', 'len', 'durn', 'meanISI', 'SI'});
    end %end of {if nBursts == 0}


