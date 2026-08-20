# Package index

## Work on a whole aniframe

Apply a named method across the spatial columns, within groups.

- [`filter_across()`](https://animovement.dev/aniprocess/reference/filter_across.md)
  **\[experimental\]** : Apply a filter across an aniframe's spatial
  columns
- [`filter_na_across()`](https://animovement.dev/aniprocess/reference/filter_na_across.md)
  **\[experimental\]** : Mask values to NA across an aniframe's spatial
  columns
- [`replace_na_across()`](https://animovement.dev/aniprocess/reference/replace_na_across.md)
  **\[experimental\]** : Fill missing values across an aniframe's
  spatial columns

## Choose a method by name

The same, for a vector or a frame of coordinates inside `mutate()`.

- [`filter_with()`](https://animovement.dev/aniprocess/reference/filter_with.md)
  : Apply a filter by name
- [`filter_na_with()`](https://animovement.dev/aniprocess/reference/filter_na_with.md)
  : Mask values to NA by a named criterion
- [`replace_na_with()`](https://animovement.dev/aniprocess/reference/replace_na_with.md)
  : Fill missing values by a named method

## Mask unreliable observations

Replace values that fail a quality criterion with `NA`.

- [`filter_na_confidence()`](https://animovement.dev/aniprocess/reference/filter_na_confidence.md)
  : Filter low-confidence values in a dataset
- [`filter_na_excursion()`](https://animovement.dev/aniprocess/reference/filter_na_excursion.md)
  : Filter Out Position Excursions That Return
- [`filter_na_range()`](https://animovement.dev/aniprocess/reference/filter_na_range.md)
  : Filter values outside a range to NA
- [`filter_na_roi()`](https://animovement.dev/aniprocess/reference/filter_na_roi.md)
  : Filter coordinates outside a region of interest (ROI)
- [`filter_na_speed()`](https://animovement.dev/aniprocess/reference/filter_na_speed.md)
  : Filter values by speed threshold

## Fill missing values

Fill gaps by interpolation, carrying forward, or a constant.

- [`replace_na_linear()`](https://animovement.dev/aniprocess/reference/replace_na_linear.md)
  : Replace Missing Values Using Linear Interpolation
- [`replace_na_locf()`](https://animovement.dev/aniprocess/reference/replace_na_locf.md)
  : Replace Missing Values Using Last Observation Carried Forward
- [`replace_na_spline()`](https://animovement.dev/aniprocess/reference/replace_na_spline.md)
  : Replace Missing Values Using Spline Interpolation
- [`replace_na_stine()`](https://animovement.dev/aniprocess/reference/replace_na_stine.md)
  : Replace Missing Values Using Stineman Interpolation
- [`replace_na_value()`](https://animovement.dev/aniprocess/reference/replace_na_value.md)
  : Replace Missing Values with a Constant Value

## Smooth and filter signals

Suppress noise while preserving the movement you care about.

- [`filter_ccma()`](https://animovement.dev/aniprocess/reference/filter_ccma.md)
  **\[experimental\]** : Apply Curvature-Corrected Moving Average (CCMA)
- [`filter_gaussian()`](https://animovement.dev/aniprocess/reference/filter_gaussian.md)
  : Apply Gaussian Kernel Smoother
- [`filter_highpass()`](https://animovement.dev/aniprocess/reference/filter_highpass.md)
  : Apply Butterworth Highpass Filter to Signal
- [`filter_highpass_fft()`](https://animovement.dev/aniprocess/reference/filter_highpass_fft.md)
  : Apply FFT-based Highpass Filter to Signal
- [`filter_kalman()`](https://animovement.dev/aniprocess/reference/filter_kalman.md)
  : Kalman Filter for Regular Time Series
- [`filter_kalman_irregular()`](https://animovement.dev/aniprocess/reference/filter_kalman_irregular.md)
  : Kalman Filter for Irregular Time Series with Optional Resampling
- [`filter_lowpass()`](https://animovement.dev/aniprocess/reference/filter_lowpass.md)
  : Apply Butterworth Lowpass Filter to Signal
- [`filter_lowpass_fft()`](https://animovement.dev/aniprocess/reference/filter_lowpass_fft.md)
  : Apply FFT-based Lowpass Filter to Signal
- [`filter_one_euro()`](https://animovement.dev/aniprocess/reference/filter_one_euro.md)
  : Apply the One Euro filter
- [`filter_rollmean()`](https://animovement.dev/aniprocess/reference/filter_rollmean.md)
  : Apply Rolling Mean Filter
- [`filter_rollmedian()`](https://animovement.dev/aniprocess/reference/filter_rollmedian.md)
  : Apply Rolling Median Filter
- [`filter_sgolay()`](https://animovement.dev/aniprocess/reference/filter_sgolay.md)
  : Apply Savitzky-Golay Filter to Movement Data
- [`filter_triangular()`](https://animovement.dev/aniprocess/reference/filter_triangular.md)
  : Apply Triangular Filter

## Find peaks and troughs

Locate local extrema by height, prominence and plateau handling.

- [`find_peaks()`](https://animovement.dev/aniprocess/reference/find_peaks.md)
  : Find Peaks in Time Series Data
- [`find_troughs()`](https://animovement.dev/aniprocess/reference/find_troughs.md)
  : Find Troughs in Time Series Data
