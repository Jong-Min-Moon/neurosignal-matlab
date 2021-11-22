---
title: spike and burst detection for neurosignal
author: Jongmin Mun
---




# spike detection
## Cyborg-Brain-Organoids-ePhys;
Single channel spike detection and clustering using "kmeans" on MATLAB;
The code is generating 8 figures based on the analysis performed on a filtered electrophysiological recording;
Figure 1 shows a time window with all the spikes detected and the average waveform;
Figure 2 shows the time series and the corresponding raster plot (before clustering);
Figure 3 shows the waveforms detected in the PC1 - PC2 plane, along with the projection of the scores of all eigenvectors;
Figure 4 shows the explained variance of each PC;
Figure 5 shows the waveforms detected in the PC1 - PC2 space after clustering;
Figure 6 shows, for each cluster (left column is cluster 1), from top to bottom, all the waveforms, the average waveform, and the average waveform +/- 1 S.D.;
Figure 7 shows the colored raster plot accordingly to the clustering results;
Figure 8 shows (top line) the inverted average waveform for each cluster and the local maximum and corresponding FWHM. Bottom line shows Interspike Intervals histogram for each cluster;
[^fn1]

# burst detection.

## method detectBurstsMI

### input:

1.  one spike train

2. parameters
   - **begISI** : maximum interval to start burst; max ISI at start of burst; Beginning inter spike interval

   - **endISI**: maximum interval to end burst; max ISI in burst; Ending inter spike interval

   - **minIBI**: minimum interval between bursts (threshold for combining bursts)
   
   - **minDurn**: minimum duration of a burst; minimum duration to consider as burst

   - **minSpikes**: minimum number of spikes in burst; minimum number of spikes to consider as burst

### output:
bursts found using max interval method.

```
[^fn1]: https://github.com/CyBrainOrg