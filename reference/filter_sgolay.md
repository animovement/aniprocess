# Apply Savitzky-Golay Filter to Movement Data

This function applies a Savitzky-Golay filter to smooth movement data
while preserving higher moments (peaks, valleys) better than moving
average filters. The implementation uses zero-phase filtering to prevent
temporal shifts in the data.

## Usage

``` r
filter_sgolay(
  x,
  sampling_rate,
  window_width = ceiling(sampling_rate/10) * 2 + 1,
  order = 3,
  na_action = "linear",
  keep_na = TRUE,
  ...
)
```

## Arguments

- x:

  Numeric vector containing the movement data to be filtered

- sampling_rate:

  Sampling rate of the data in Hz. Must match your data collection rate
  (e.g., 60 for 60 FPS motion capture).

- window_width:

  Window size in samples (must be odd). Controls the amount of
  smoothing. Larger windows give more smoothing but may over-attenuate
  genuine movement features. Default is automatically calculated as
  sampling_rate/10 (rounded up to nearest odd number).

- order:

  Polynomial order (default = 3). Controls how well the filter preserves
  higher-order moments in the data:

  - order=2: Preserves position, velocity (good for smooth movements)

  - order=3: Also preserves acceleration (good for most movement data)

  - order=4: Also preserves jerk (good for quick movements)

  - order=5: Maximum preservation (may retain too much noise)

- na_action:

  Method used to fill `NA` values *before* filtering, so the filter sees
  a complete series. One of `"linear"` (default), `"spline"`, `"stine"`,
  `"locf"`, `"value"`, or `"error"` to abort when `NA`s are present.
  Filling is internal: whether the filled values reach the output is
  controlled by `keep_na`.

- keep_na:

  Logical. If `TRUE` (default), positions that were `NA` in the input
  are `NA` in the output — gaps stay gaps. If `FALSE`, the values used
  to fill those gaps are kept, so the output has **fewer `NA`s than the
  input** and genuinely-missing stretches come back as interpolated
  estimates.

- ...:

  Additional arguments passed to replace_na_with()

## Value

Numeric vector containing the filtered movement data

## Details

The Savitzky-Golay filter fits successive polynomials to sliding windows
of the data. This approach preserves higher moments of the data better
than simple moving averages or Butterworth filters, making it
particularly suitable for movement data where preserving features like
peaks and valleys is important.

Edges are handled by
[`signal::sgolayfilt()`](https://rdrr.io/pkg/signal/man/sgolayfilt.html)
using extrapolation from the nearest interior polynomial fit, which is
the standard Savitzky-Golay edge convention.

Parameter Selection Guidelines:

- window_width:

  - For 60 FPS: 5-15 frames (83-250ms) for quick movements, 15-31 for
    slow movements

  - For 120 FPS: 7-21 frames (58-175ms) for quick movements, 21-51 for
    slow movements

  - For 500 FPS: 25-75 frames (50-150ms) for quick movements, 75-151 for
    slow movements The default window_width = sampling_rate/10 works
    well for typical human movement.

- order:

  - order=2: Smooth movements, position analysis

  - order=3: Most movement analysis (default)

  - order=4: Quick movements, sports analysis

  - order=5: Very quick movements, impact analysis Note: order must be
    less than window_width

Common values by application:

- Gait analysis (60 FPS): window_width=15, order=3

- Sports biomechanics (120 FPS): window_width=21, order=4

- Impact analysis (500 FPS): window_width=51, order=4

- Posture analysis (60 FPS): window_width=31, order=2

## References

Savitzky, A., & Golay, M.J.E. (1964). Smoothing and Differentiation of
Data by Simplified Least Squares Procedures. Analytical Chemistry,
36(8), 1627-1639.

## See also

[`filter_lowpass`](https://animovement.dev/aniprocess/reference/filter_lowpass.md)
for frequency-based filtering
[`replace_na_with()`](https://animovement.dev/aniprocess/reference/replace_na_with.md)
for details on NA handling methods

## Examples

``` r
# Generate example movement data: smooth motion + noise
t <- seq(0, 5, by = 1/60)  # 60 FPS data
x <- sin(2*pi*0.5*t) + rnorm(length(t), 0, 0.1)

# Basic filtering with default parameters (60 FPS)
filtered <- filter_sgolay(x, sampling_rate = 60)

# Adjusting parameters for quick movements
filtered_quick <- filter_sgolay(x, sampling_rate = 60,
                               window_width = 11, order = 4)

# High-speed camera data (500 FPS) with larger window
filtered_high <- filter_sgolay(x, sampling_rate = 500,
                              window_width = 51, order = 3)
```
