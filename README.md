---
title: spike and burst detection for neurosignal
author: Jongmin Mun
---

# Channel Class Explanation and Paper Data Processing Reproduction 

filename: summary_examples_multichannel.mlx

Single channel spike detection and clustering using "kmeans" on MATLAB;
The core procedure is implemented as a **`channel`** class object, which can be created by importing **`.xlsx`** files that follow the specific structure used in this lab.

Based on the MATLAB Live Script provided, here is a summary documentation for the custom classes and functions implemented in the analysis pipeline.

---

# API Documentation: CyborgBrainOrg Analysis

## 1. Class: `channelReader`
**Purpose:** Handles file I/O operations for reading Brain and Retina multi-channel data files.

### Methods

| Method | Inputs | Description |
| :--- | :--- | :--- |
| **`readMultiChannelFile`** | `filename`, `channelColIdx`, `timeColIdx`, `startRowIdx`, `startColIdx`, `sampleRate` | Reads the raw Excel/Text file to identify available channels and file structure. Initializes the reader. |
| **`readSingleChannelFromFile`** | `organoidID`, `channelID`, `monthID` | Extracts data for a specific channel. **Returns:** A `channel` object containing the raw data and sampling frequency. |
| **`readManyChannelsFromFile`** | *(Various)* | *New in v2022-01-15.* Reads multiple channels simultaneously and returns a list of `channel` objects. |

---

## 2. Class: `channel`
**Purpose:** The core class encapsulating data for a single electrode channel. It stores raw signals, filtered signals, spike timestamps, and analysis results (PCA, Clustering).

### Signal Processing Methods

* **`bandPass(passBand)`**
    * **Input:** `passBand` (Array `[minHz, maxHz]`, e.g., `[300, 3000]`).
    * **Action:** Applies a bandpass filter to the raw data and stores it in the `.filtered` property.
    * **Note:** Includes uniform resampling logic.

* **`getBand(freqBand)`**
    * **Input:** `freqBand` (Array `[minHz, maxHz]`, e.g., `[4, 8]` for Theta).
    * **Output:** `voltage`, `phase`.
    * **Action:** Filters data to the specific band and uses the **Hilbert transform** to calculate the phase angle.

### Spike Detection & Burst Analysis

* **`detectSpikes(thres, preTime, postTime)`**
    * **Inputs:**
        * `thres`: Threshold multiplier (e.g., 5). *Note: Logic detects local minima (Mean - 5*SD).*
        * `preTime`: Window size before peak (ms).
        * `postTime`: Window size after peak (ms).
    * **Action:** Populates `.spikeTimestamps` and `.spikeWaveforms`.

* **`detectBurstsMI(begISI, endISI, minSpikes, minDurn, minIBI)`**
    * **Inputs:** Parameters for the **MaxInterval** method (based on Fair et al. 2020).
    * **Output:** Table containing Burst ID, Spike Count, Duration, IBI, etc.
    * **Action:** Performs 3-phase burst detection (Finding candidates -> Merging close bursts -> Pruning invalid bursts).

* **`getISIvaluesBeforePCA()`**
    * **Output:** Array of Inter-Spike Intervals (ms).
    * **Action:** Calculates ISI for *all* detected spikes prior to any sorting/clustering.

### Spike Sorting (PCA & Clustering)

* **`getPCScores()`**
    * **Action:** Performs Standard Scaling (z-score) on spike waveforms, then executes Principal Component Analysis (PCA). Stores scores in `.PCScores`.

* **`getKmeansClusters(clusternum, seednum)`**
    * **Inputs:** `clusternum` (Target k), `seednum` (Random seed for reproducibility).
    * **Action:** Performs k-means clustering on the first two Principal Components. Assigns `.clusters` membership.

* **`mahalanobis_metrics(clusterID)`**
    * **Input:** `clusterID` (Integer).
    * **Output:** `Isolation Distance`, `L-ratio`.
    * **Action:** Calculates cluster quality metrics based on Mahalanobis distance.

### Phase Analysis

* **`getBandPhaseByClusterNum(clusterID)`**
    * **Output:** Phase angles (radians) for spikes belonging to the specified cluster.
* **`uniformTest()`**
    * **Output:** p-values per cluster.
    * **Action:** Performs a **Rayleigh test** for non-uniformity to detect phase-locking (significance threshold usually p < 0.05).

### Plotting & Data Retrieval Helpers

* **`drawRaster(color)`**: Draws a standard raster plot of spike times.
* **`drawColoredRaster(colorArray)`**: Draws a raster plot where spikes are colored by their cluster assignment.
* **`getClusterMeanSpike(clusterID)`**: Returns mean waveform, standard deviation, and time range for a specific cluster.
* **`getTotalMeanSpike()`**: Returns the mean waveform for *all* spikes in the channel.
* **`getISIvalues(clusterID)`**: Returns ISI data specific to a single cluster.

---

## 3. Class: `longtermAnalyzer`
**Purpose:** Manages longitudinal data across different organoids, channels, and months for aggregate statistical analysis.

### Methods

* **`addChannel(channelObj)`**
    * **Input:** A processed `channel` object.
    * **Action:** Adds the channel data to the analyzer's internal storage for batch processing.

* **`getFWHmHistByMonth(monthID, channelID)`**
    * **Inputs:** `monthID`, `channelID`.
    * **Output:** FWHM data points, Organoid labels, Mean FWHM.
    * **Action:** Aggregates data from all stored organoids matching the criteria and calculates the **Full Width Half Minimum** (FWHM) for spike waveforms.

* **`FWHm(waveform, msPerTs)`** *(Internal)*
    * **Action:** Calculates the width of a single spike waveform at half of its minimum amplitude.

* **`getFWHmsForChannel()`** *(Internal)*
    * **Action:** Iterates FWHM calculation over all spikes in a channel.
 

## Figure generations
The code is generating 8 figures based on the analysis performed on a filtered electrophysiological recording;
1. Figure 1 shows a time window with all the spikes detected and the average waveform;
2. Figure 2 shows the time series and the corresponding raster plot (before clustering);
3. Figure 3 shows the waveforms detected in the PC1 - PC2 plane, along with the projection of the scores of all eigenvectors;
4. Figure 4 shows the explained variance of each PC;
5. Figure 5 shows the waveforms detected in the PC1 - PC2 space after clustering;
6. Figure 6 shows, for each cluster (left column is cluster 1), from top to bottom, all the waveforms, the average waveform, and the average waveform +/- 1 S.D.;
7. Figure 7 shows the colored raster plot accordingly to the clustering results;
8. Figure 8 shows (top line) the inverted average waveform for each cluster and the local maximum and corresponding FWHM. Bottom line shows Interspike Intervals histogram for each cluster;
[^fn1]
Here is the MATLAB Live Editor file content converted into a clean, structured Markdown document.

-----

# 

**Date:** October 19, 2022
**Format:** MATLAB Live Script

## Table of Contents

1.  [0. Data Loading and Preprocessing](https://www.google.com/search?q=%230-data-loading-and-preprocessing)
      * [0.1. Data Loading](https://www.google.com/search?q=%2301-data-loading)
      * [0.1 (misc). Bandpass Filter & Data Export](https://www.google.com/search?q=%2301-misc-bandpass-filter-preview--data-export)
      * [0.1. Bandpass Filter Application](https://www.google.com/search?q=%2301-bandpass-filter-application)
      * [0.2. Spike Detection](https://www.google.com/search?q=%2302-spike-detection)
      * [0.2. ISI Calculation](https://www.google.com/search?q=%2302-isi-calculation)
      * [0.3. Burst Detection (MaxInterval)](https://www.google.com/search?q=%2303-burst-detection-maxinterval)
      * [0.4. PCA](https://www.google.com/search?q=%2304-pca)
      * [0.5. K-means Clustering](https://www.google.com/search?q=%2305-k-means-clustering)
      * [0.5.1. Spike Sorting Quality Metrics](https://www.google.com/search?q=%23051-spike-sorting-quality-metrics)
2.  [1. Figure 2 Reproduction and Comments](https://www.google.com/search?q=%231-figure-2-reproduction-and-comments)
      * [Figure 2.f (Traces & Raster)](https://www.google.com/search?q=%23figure-2f)
      * [Figure 2.g (Zoomed Spike)](https://www.google.com/search?q=%23figure-2g)
      * [Figure 2.g.1 (Many Spikes)](https://www.google.com/search?q=%23figure-2g1-many-spikes)
      * [Figure 2.h (PCA & Clustering)](https://www.google.com/search?q=%23figure-2h)
      * [Figure 2.h.1 (3D PCA Plot)](https://www.google.com/search?q=%23figure-2h1-3d-pca-plot)
      * [Figure 2.h.2 (Export Scatter Data)](https://www.google.com/search?q=%23figure-2h2-scatterplot-data-export)
      * [Figure 2.h Part 2 (Mean Spikes)](https://www.google.com/search?q=%23figure-2h-part-2)
      * [Figure 2.h.3 (Colored Traces)](https://www.google.com/search?q=%23figure-2h31-many-spikes-colored-by-cluster)
      * [Figure 2.i (Colored Raster)](https://www.google.com/search?q=%23figure-2i)
      * [Figure 2.j (ISI Histogram)](https://www.google.com/search?q=%23figure-2j)
      * [Figure 2.k, m, n (Phase Analysis)](https://www.google.com/search?q=%23figure-2k-m-n-phase-analysis)
3.  [Figure 2 Part 2: LongtermAnalyzer Class](https://www.google.com/search?q=%23figure-2-part-2-longtermanalyzer-class-introduction)
      * [Figure 2.o (Monthly Histogram)](https://www.google.com/search?q=%23figure-2o)
      * [Figure 4.b (Comparisons)](https://www.google.com/search?q=%23figure-4b)
      * [Figure 4.c (Spectrogram)](https://www.google.com/search?q=%23figure-4c)
      * [Figure 4.d (Power Spectrum)](https://www.google.com/search?q=%23figure-4d)
      * [Figure 4.f (Phase-Space)](https://www.google.com/search?q=%23figure-4f)

-----

## 0\. Data Loading and Preprocessing

### 0.1. Data Loading

Create a channel object and process data. Refer to `reading_method_guide.mlx` for details.

```matlab
reader = channelReader();
tic 
% Arguments: filename, channelColumnIdx, timeColumnIdx, startRowIdx, startColIdx, sampleRate
reader.readMultiChannelFile("./data/1_singleunit wave.xlsx", 1, 3, 7, 4, nan); 
% Output: This file has 16 channels.

toc 
% Elapsed time is ~79 seconds.

% Arguments: organoid, channel, month 
o1_ch8_m1 = reader.readSingleChannelFromFile(1, 8, 1); 
% Output: channel number = 8, sampling rate = 24414Hz, duration = 23.15s, timestamps = 565248
```

### 0.1 (misc). Bandpass Filter Preview & Data Export

**Bandpass Filter Preview Graph:**
Check the raw data and the effect of the bandpass filter visually.

```matlab
% apply bandpass filter 300-3000hz
figure
bandpass(o1_ch8_m1.raw, [300,3000], o1_ch8_m1.sf)
sgtitle("bandpass filter preview")
```

**Figure Data Export Basics (Line Graph):**
To export data from a MATLAB figure to Excel:

1.  Access the figure and axes objects.
2.  Drill down to the `Children` to find the specific chart object (Line).
3.  Extract `XData` and `YData`.

<!-- end list -->

```matlab
h = gcf; % Get current figure
axesObjs = get(h, 'Children'); 
dataObjs = get(axesObjs(5), 'Children'); % Access specific axes
lineObj = dataObjs(2); % Access specific line
lineX = (lineObj.XData)';
lineY = (lineObj.YData)';
lineData = table(lineX, lineY);
writetable(lineData, "lineData.xlsx"); % Save as Excel
```

### 0.1. Bandpass Filter Application

**Method:** `bandPass`

  * **Parameter:** `passBand` (Format: `[low, high]` in Hz).
  * Applies the filter and saves it within the channel object.

<!-- end list -->

```matlab
o1_ch8_m1.bandPass([300,3000]); 
```

### 0.2. Spike Detection

**Method:** `detectSpikes`

  * **Parameters:** `thres` (Threshold, e.g., 5 sigmas), `preTime` (ms), `postTime` (ms).
  * *Note:* The code uses a negative threshold (detects local minima).

<!-- end list -->

```matlab
% thres=5, preTime=2ms, postTime=2ms
o1_ch8_m1.detectSpikes(5,2,2);
% Output: number of spikes found : 113
```

### 0.2. ISI Calculation

**Method:** `getISIvaluesBeforePCA`
Calculates Inter-Spike Interval (ISI) for all detected spikes before clustering.

```matlab
ISIvaluesBeforePCA = o1_ch8_m1.getISIvaluesBeforePCA(); 
nSpikes = o1_ch8_m1.nSpikes;

figure
h1 = histogram(ISIvaluesBeforePCA, 20); 
title('ISI histogram, n = ' + string(nSpikes) ); 
xlabel('ISI (ms)'); 
h1.FaceColor = "green";
```

**0.2.1. Histogram Figure Export:**
Similar to line graph export, but accessing `histogram` objects.

```matlab
h = gcf; 
axesObjs = get(h, 'Children');
dataObjs = get(axesObjs(1), 'Children');
histogramBinEdges = (dataObjs.BinEdges)';
histogramBinEdges(end) = []; % Remove last edge
histogramValues = (dataObjs.Values)';
writetable(table(histogramBinEdges, histogramValues), "histoData.xlsx");
```

### 0.3. Burst Detection (MaxInterval)

**Method:** `detectBurstsMI`
Based on the MaxInterval method from [Fair et al. (2020)](https://doi.org/10.1016/j.stemcr.2020.08.017) and [Cotterill & Eglen (2019)](https://doi.org/10.1007/978-3-030-11135-9_8).

  * **Parameters:** `begISI`, `endISI`, `minSpikes`, `minDurn` (ms), `minIBI` (ms).
  * **Steps:** 1. Finding (using ISI thresholds), 2. Merging (using IBI), 3. Deleting (using duration/count thresholds).

<!-- end list -->

```matlab
% begISI=300, endISI=301, minSpikes=10, minDurn=50, minIBI=200
burstDetectionResult = o1_ch8_m1.detectBurstsMI(300, 301, 10, 50, 200);
```

### 0.4. PCA

**Method:** `getPCScores`

  * **Caution:** Standard scaling is essential to prevent high-amplitude waveforms from dominating the variance.
  * **Note:** The warning "Columns of X are linearly dependent" is expected due to flat start/end points of waveforms.

<!-- end list -->

```matlab
o1_ch8_m1.getPCScores();
```

### 0.5. K-means Clustering

**Method:** `getKmeansClusters`

  * **Parameters:** `clusternum` (Number of clusters), `seednum` (Random seed).
  * **Note:** Since K-means depends on initialization, users should try multiple seed numbers and cluster counts.

<!-- end list -->

```matlab
o1_ch8_m1.getKmeansClusters(3, 2212323231);
% Output: number of spikes per cluster: 80, 12, 21
```

### 0.5.1. Spike Sorting Quality Metrics

**Method:** `mahalanobis_metrics`

  * Calculates Isolation Distance and L-ratio.

<!-- end list -->

```matlab
[isol_1, lratio_1] = o1_ch8_m1.mahalanobis_metrics(1);
% Output: Isolation distance: NaN (if cluster is too large relative to noise), L_ratio: 0.000005
```

-----

## 1\. Figure 2 Reproduction and Comments

### Figure 2.f

Raw trace, Filtered trace, and Raster plot.

```matlab
figure
subplot(3,1,1); plot(o1_ch8_m1.t, o1_ch8_m1.raw); title('ch8, raw');
subplot(3,1,2); plot(o1_ch8_m1.t, o1_ch8_m1.filtered); title('ch8, filtered');
subplot(3,1,3); o1_ch8_m1.drawRaster('red');
sgtitle("figure 2.f. raw trace, filtered trace, raster plot")
```

### Figure 2.g

Zoom in on specific spikes in raw and filtered traces.

```matlab
ts = o1_ch8_m1.spikeTimestamps(1); 
tsInterval = ts + (-o1_ch8_m1.timestampsPrePeak : o1_ch8_m1.timestampsPostPeak);

figure
subplot(2,1,1); plot(o1_ch8_m1.t(tsInterval), o1_ch8_m1.raw(tsInterval)); title('raw trace zoom');
subplot(2,1,2); plot(o1_ch8_m1.t(tsInterval), o1_ch8_m1.filtered(tsInterval)); title('filtered trace zoom');
```

### Figure 2.g.1 (Many Spikes)

Overlays all detected spikes aligned by peak.

```matlab
% Set window (e.g., -0.5ms to +1.0ms)
ms_pre_peak = 0.5; ms_post_peak = 1.0;
% ... calculate timestamp indices ...

figure
subplot(2,1,1); hold on; % Raw traces
for i = 1:o1_ch8_m1.nSpikes
    % ... plot loop ...
end
subplot(2,1,2); hold on; % Filtered traces
for i = 1:o1_ch8_m1.nSpikes
    % ... plot loop ...
end
```

### Figure 2.h

PCA Explained Variance and Cluster Scatter Plot.

```matlab
subplot(2,1,1); bar(o1_ch8_m1.explainedVar);
subplot(2,1,2); 
% Scatter plot loop by cluster
for c = 1 : o1_ch8_m1.nClusters
    scatter(PC1((o1_ch8_m1.clusters == c),:), PC2((o1_ch8_m1.clusters == c),:), ...);
    hold on;
end
```

### Figure 2.h.1 (3D PCA Plot)

A complex example involving reading multiple channels, pooling spikes, and plotting in 3D (PC1, PC2, Channel ID). See source code for the full implementation of pooling and color gradient generation.

### Figure 2.h.2 (Scatterplot Data Export)

Extracts X/Y data from the scatter plot children objects and saves to Excel.

### Figure 2.h Part 2

Mean spike waveform of each cluster with standard deviation bands.

```matlab
[meanSpike, std_dev, tRange, ~] = o1_ch8_m1.getClusterMeanSpike(1);
% Plot Mean +/- STD
plot(tRange, meanSpike + std_dev, 'k--');
plot(tRange, meanSpike - std_dev, 'k--');
% Fill area (optional)
% Plot Mean
plot(tRange, meanSpike, 'k');
```

### Figure 2.h.3.1 (Many Spikes, Colored by Cluster)

Similar to 2.g.1 but colors traces based on their cluster assignment.

### Figure 2.i

**Colored Raster Plot.**
Method: `drawColoredRaster`

```matlab
o1_ch8_m1.drawColoredRaster(["red", "blue", "green"]);
```

### Figure 2.j

**ISI Histogram per Cluster.**
Method: `getISIvalues(clusterNum)`

```matlab
[ISI_1, ~] = o1_ch8_m1.getISIvalues(1);
histogram(ISI_1, 20);
```

### Figure 2.k, m, n: Phase Analysis

**Theta Waves and Phase:**
Method: `getBand([low, high])` uses Hilbert transform.

```matlab
[theta_volt, theta_phase] = o1_ch8_m1.getBand([4,8]);
```

**Figure 2.m (Circular Distribution):**
Uses `circ_plot` from the Circular Statistics toolbox.

```matlab
[phase_1, ~] = o1_ch8_m1.getBandPhaseByClusterNum(1);
circ_plot(phase_1, 'hist', [], 20, true, false);
```

**Uniform Test (Phase-Locking):**
Method: `uniformTest`. Uses Rayleigh criterion (p \< 0.05 implies phase locking).

```matlab
o1_ch8_m1.uniformTest()
```

-----

## Figure 2 Part 2: LongtermAnalyzer Class Introduction

Use `longtermAnalyzer` for aggregating data across months/channels.

```matlab
la = longtermAnalyzer();
la.addChannel(o1_ch1_m1); 
la.addChannel(o1_ch2_m2);
% ... add all channels
```

### Figure 2.o

Monthly FWHM (Full Width Half Minimum) Histogram.
Method: `getFWHmHistByMonth`.

```matlab
[FWHmPoints_1, labels_1, mean_1] = la.getFWHmHistByMonth(1, 1); % Month 1, Channel 1
% Plot bar graph of means and scatter plot of individual points
```

### Figure 4.b

Comparisons of Mean Spikes across channels and months.
Uses `getTotalMeanSpike()` on different channel objects plotted in subplots.

### Figure 4.c

Spectrogram using MATLAB's Signal Processing Toolbox.

```matlab
spectrogram(o1_ch1_m2.raw, [], [], [], o1_ch1_m2.sf, 'yaxis');
```

### Figure 4.d

Power Spectrum using `pspectrum` on a timetable.

### Figure 4.f

**Phase-Space Plot.**
Plots Voltage ($V$) vs Derivative ($dV/dt$). Data is normalized by dividing by the minimum value.

```matlab
avgWave = mean(o1_ch1_m1.spikeWaveforms);
dVdt = diff(avgWave) / o1_ch1_m1.msPerTs;
% Normalize
avgWave = avgWave / min(avgWave);
dVdt = dVdt / min(dVdt);
% Plot
plot(avgWave(1:end-1), dVdt);
```

```
[^fn1]: https://github.com/CyBrainOrg
