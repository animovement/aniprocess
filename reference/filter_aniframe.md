# Smooth Movement Data

**\[experimental\]**

Applies smoothing filters to movement tracking data to reduce noise.

## Usage

``` r
filter_aniframe(
  data,
  method = c("rollmedian", "rollmean", "triangular", "gaussian", "kalman", "sgolay",
    "lowpass", "highpass", "lowpass_fft", "highpass_fft"),
  use_derivatives = FALSE,
  ...
)
```

## Arguments

- data:

  An aniframe. Spatial columns to filter are taken from the metadata
  field `variables_where` (e.g. `c("x", "y")` or `c("x", "y", "z")`).
  Filtering is applied within the aniframe's existing grouping, which is
  driven by `variables_what` (e.g. `c("individual", "keypoint")`,
  `"track"`, or `character(0)` for a single trajectory). Single-track
  data without an `individual` column is supported.

- method:

  Character string specifying the smoothing method. Options:

  - `"kalman"`: Kalman filter (see
    [`filter_kalman()`](http://animovement.dev/aniprocess/reference/filter_kalman.md))

  - `"sgolay"`: Savitzky-Golay filter (see
    [`filter_sgolay()`](http://animovement.dev/aniprocess/reference/filter_sgolay.md))

  - `"lowpass"`: Low-pass filter (see
    [`filter_lowpass()`](http://animovement.dev/aniprocess/reference/filter_lowpass.md))

  - `"highpass"`: High-pass filter (see
    [`filter_highpass()`](http://animovement.dev/aniprocess/reference/filter_highpass.md))

  - `"lowpass_fft"`: FFT-based low-pass filter (see
    [`filter_lowpass_fft()`](http://animovement.dev/aniprocess/reference/filter_lowpass_fft.md))

  - `"highpass_fft"`: FFT-based high-pass filter (see
    [`filter_highpass_fft()`](http://animovement.dev/aniprocess/reference/filter_highpass_fft.md))

  - `"rollmean"`: Rolling mean filter (see
    [`filter_rollmean()`](http://animovement.dev/aniprocess/reference/filter_rollmean.md))

  - `"rollmedian"`: Rolling median filter (see
    [`filter_rollmedian()`](http://animovement.dev/aniprocess/reference/filter_rollmedian.md))

  - `"triangular"`: Triangular filter (see
    [`filter_triangular()`](http://animovement.dev/aniprocess/reference/filter_triangular.md))

  - `"gaussian"`: Gaussian kernel smoother (see
    [`filter_gaussian()`](http://animovement.dev/aniprocess/reference/filter_gaussian.md))

- use_derivatives:

  Filter on the derivative values instead of coordinates (important for
  e.g. trackball or accelerometer data)

- ...:

  Additional arguments passed to the specific filter function

## Value

An aniframe with the same structure as the input, but with smoothed
spatial coordinates.

## Details

This function is a wrapper that applies the chosen filter to every
spatial coordinate listed in `variables_where`, respecting the
aniframe's existing grouping. Each filtering method has its own specific
parameters - see the documentation of the individual filter functions
for details:

- [`filter_kalman()`](http://animovement.dev/aniprocess/reference/filter_kalman.md):
  Kalman filter parameters

- [`filter_sgolay()`](http://animovement.dev/aniprocess/reference/filter_sgolay.md):
  Savitzky-Golay filter parameters

- [`filter_lowpass()`](http://animovement.dev/aniprocess/reference/filter_lowpass.md):
  Low-pass filter parameters

- [`filter_highpass()`](http://animovement.dev/aniprocess/reference/filter_highpass.md):
  High-pass filter parameters

- [`filter_lowpass_fft()`](http://animovement.dev/aniprocess/reference/filter_lowpass_fft.md):
  FFT-based low-pass filter parameters

- [`filter_highpass_fft()`](http://animovement.dev/aniprocess/reference/filter_highpass_fft.md):
  FFT-based high-pass filter parameters

- [`filter_rollmean()`](http://animovement.dev/aniprocess/reference/filter_rollmean.md):
  Rolling mean parameters (window_width, min_obs)

- [`filter_rollmedian()`](http://animovement.dev/aniprocess/reference/filter_rollmedian.md):
  Rolling median parameters (window_width, min_obs)

- [`filter_triangular()`](http://animovement.dev/aniprocess/reference/filter_triangular.md):
  Triangular filter parameters (window_width, min_obs)

- [`filter_gaussian()`](http://animovement.dev/aniprocess/reference/filter_gaussian.md):
  Gaussian kernel parameters (sigma, window_width)

## See also

- [`filter_kalman()`](http://animovement.dev/aniprocess/reference/filter_kalman.md)

- [`filter_sgolay()`](http://animovement.dev/aniprocess/reference/filter_sgolay.md)

- [`filter_lowpass()`](http://animovement.dev/aniprocess/reference/filter_lowpass.md)

- [`filter_highpass()`](http://animovement.dev/aniprocess/reference/filter_highpass.md)

- [`filter_lowpass_fft()`](http://animovement.dev/aniprocess/reference/filter_lowpass_fft.md)

- [`filter_highpass_fft()`](http://animovement.dev/aniprocess/reference/filter_highpass_fft.md)

- [`filter_rollmean()`](http://animovement.dev/aniprocess/reference/filter_rollmean.md)

- [`filter_rollmedian()`](http://animovement.dev/aniprocess/reference/filter_rollmedian.md)

- [`filter_triangular()`](http://animovement.dev/aniprocess/reference/filter_triangular.md)

- [`filter_gaussian()`](http://animovement.dev/aniprocess/reference/filter_gaussian.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Apply rolling median with window of 5
filter_aniframe(tracking_data, "rollmedian", window_width = 5, min_obs = 1)
} # }
```
