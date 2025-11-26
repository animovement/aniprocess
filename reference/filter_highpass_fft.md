# Apply FFT-based Highpass Filter to Signal

This function implements a highpass filter using the Fast Fourier
Transform (FFT). It provides a sharp frequency cutoff but may introduce
ringing artifacts (Gibbs phenomenon).

## Usage

``` r
filter_highpass_fft(
  x,
  cutoff_freq,
  sampling_rate,
  na_action = c("linear", "spline", "stine", "locf", "value", "error"),
  keep_na = FALSE,
  ...
)
```

## Arguments

- x:

  Numeric vector containing the signal to be filtered

- cutoff_freq:

  Cutoff frequency in Hz. Frequencies above this value are passed, while
  frequencies below are attenuated. Should be between 0 and
  sampling_rate/2.

- sampling_rate:

  Sampling rate of the signal in Hz. Must be at least twice the highest
  frequency component in the signal (Nyquist criterion).

- na_action:

  Method to handle NA values before filtering. One of: - "linear":
  Linear interpolation (default) - "spline": Spline interpolation for
  smoother curves - "stine": Stineman interpolation preserving data
  shape - "locf": Last observation carried forward - "value": Replace
  with a constant value - "error": Raise an error if NAs are present

- keep_na:

  Logical indicating whether to restore NAs to their original positions
  after filtering (default = FALSE)

- ...:

  Additional arguments passed to replace_na(). Common options include: -
  value: Numeric value for replacement when na_action = "value" -
  min_gap: Minimum gap size to interpolate/fill - max_gap: Maximum gap
  size to interpolate/fill

## Value

Numeric vector containing the filtered signal

## Details

FFT-based filtering applies a hard cutoff in the frequency domain. This
can be advantageous for:

- Precise frequency selection

- Batch processing of long signals

- Cases where sharp frequency cutoffs are desired

Common Applications:

- Removing baseline drift: Use low cutoff (0.1-1 Hz)

- EMG analysis: Use moderate cutoff (10-20 Hz)

- Motion artifact removal: Use application-specific cutoff

Limitations:

- May introduce ringing artifacts

- Assumes periodic signal (can cause edge effects)

- Less suitable for real-time processing

Missing Value Handling: The function uses replace_na() internally for
handling missing values. See ?replace_na for detailed information about
each method and its parameters. NAs can optionally be restored to their
original positions after filtering using keep_na = TRUE.

## See also

[`replace_na`](http://animovement.dev/aniprocess/reference/replace_na.md)
for details on NA handling methods
[`filter_lowpass_fft`](http://animovement.dev/aniprocess/reference/filter_lowpass_fft.md)
for FFT-based low-pass filtering
[`filter_highpass`](http://animovement.dev/aniprocess/reference/filter_highpass.md)
for Butterworth-based filtering

## Examples

``` r
# Generate example signal with drift
t <- seq(0, 1, by = 0.001)
drift <- 0.5 * t  # Linear drift
signal <- sin(2*pi*10*t)  # 10 Hz signal
x <- signal + drift

# Add some NAs
x[sample(length(x), 10)] <- NA

# Basic filtering with linear interpolation for NAs
filtered <- filter_highpass_fft(x, cutoff_freq = 2, sampling_rate = 1000)

# Using spline interpolation with max gap constraint
filtered <- filter_highpass_fft(x, cutoff_freq = 2, sampling_rate = 1000,
                               na_action = "spline", max_gap = 3)

# Replace NAs with zeros before filtering
filtered <- filter_highpass_fft(x, cutoff_freq = 2, sampling_rate = 1000,
                               na_action = "value", value = 0)

# Filter but keep NAs in their original positions
filtered <- filter_highpass_fft(x, cutoff_freq = 2, sampling_rate = 1000,
                               na_action = "linear", keep_na = TRUE)

# Compare with Butterworth filter
butter_filtered <- filter_highpass(x, 2, 1000)
```
