# Package index

## Remove observations of poor quality

These functions ensure that your data is ready for analysis.

- [`filter_na_confidence()`](http://animovement.dev/aniprocess/reference/filter_na_confidence.md)
  : Filter low-confidence values in a dataset
- [`filter_na_speed()`](http://animovement.dev/aniprocess/reference/filter_na_speed.md)
  : Filter values by speed threshold
- [`filter_na_roi()`](http://animovement.dev/aniprocess/reference/filter_na_roi.md)
  : Filter coordinates outside a region of interest (ROI)
- [`filter_na_range()`](http://animovement.dev/aniprocess/reference/filter_na_range.md)
  : Filter values outside a range to NA

## Interpolate over missing values

These functions ensure that your data is ready for analysis.

- [`replace_na()`](http://animovement.dev/aniprocess/reference/replace_na.md)
  : Replace Missing Values Using Various Methods
- [`replace_na_linear()`](http://animovement.dev/aniprocess/reference/replace_na_linear.md)
  : Replace Missing Values Using Linear Interpolation
- [`replace_na_locf()`](http://animovement.dev/aniprocess/reference/replace_na_locf.md)
  : Replace Missing Values Using Last Observation Carried Forward
- [`replace_na_spline()`](http://animovement.dev/aniprocess/reference/replace_na_spline.md)
  : Replace Missing Values Using Spline Interpolation
- [`replace_na_stine()`](http://animovement.dev/aniprocess/reference/replace_na_stine.md)
  : Replace Missing Values Using Stineman Interpolation
- [`replace_na_value()`](http://animovement.dev/aniprocess/reference/replace_na_value.md)
  : Replace Missing Values with a Constant Value

## Smoothing/filtering functions

These functions ensure that your data is ready for analysis.

- [`filter_aniframe()`](http://animovement.dev/aniprocess/reference/filter_aniframe.md)
  **\[experimental\]** : Smooth Movement Data
- [`filter_lowpass()`](http://animovement.dev/aniprocess/reference/filter_lowpass.md)
  : Apply Butterworth Lowpass Filter to Signal
- [`filter_highpass()`](http://animovement.dev/aniprocess/reference/filter_highpass.md)
  : Apply Butterworth Highpass Filter to Signal
- [`filter_lowpass_fft()`](http://animovement.dev/aniprocess/reference/filter_lowpass_fft.md)
  : Apply FFT-based Lowpass Filter to Signal
- [`filter_highpass_fft()`](http://animovement.dev/aniprocess/reference/filter_highpass_fft.md)
  : Apply FFT-based Highpass Filter to Signal
- [`filter_kalman()`](http://animovement.dev/aniprocess/reference/filter_kalman.md)
  : Kalman Filter for Regular Time Series
- [`filter_kalman_irregular()`](http://animovement.dev/aniprocess/reference/filter_kalman_irregular.md)
  : Kalman Filter for Irregular Time Series with Optional Resampling
- [`filter_rollmean()`](http://animovement.dev/aniprocess/reference/filter_rollmean.md)
  : Apply Rolling Mean Filter
- [`filter_rollmedian()`](http://animovement.dev/aniprocess/reference/filter_rollmedian.md)
  : Apply Rolling Median Filter
- [`filter_sgolay()`](http://animovement.dev/aniprocess/reference/filter_sgolay.md)
  : Apply Savitzky-Golay Filter to Movement Data

## Other functions

These functions ensure that your data is ready for analysis.

- [`find_peaks()`](http://animovement.dev/aniprocess/reference/find_peaks.md)
  : Find Peaks in Time Series Data
- [`find_troughs()`](http://animovement.dev/aniprocess/reference/find_troughs.md)
  : Find Troughs in Time Series Data
