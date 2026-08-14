# Apply Curvature-Corrected Moving Average (CCMA)

**\[experimental\]**

Smooths a trajectory while undoing the inward "corner-cutting" bias that
a plain moving average introduces on curved paths.

## Usage

``` r
filter_ccma(
  data,
  window_width_ma = 11,
  window_width_cc = 7,
  kernel = c("hanning", "uniform"),
  boundary = c("padding"),
  cc_mode = TRUE,
  na_action = c("linear", "spline", "stine", "locf", "value", "error"),
  keep_na = TRUE,
  ...
)
```

## Arguments

- data:

  An aniframe in Cartesian coordinates with 2 or 3 spatial columns (set
  via the `variables_where` metadata field). The curvature math is
  Cartesian-specific (cross products, Euclidean norms, circumradius), so
  polar / cylindrical / spherical aniframes are rejected.

- window_width_ma:

  Integer width of the moving-average kernel (must be odd; even values
  are rounded up). Larger = more smoothing. Default `11`.

- window_width_cc:

  Integer width of the curvature-correction kernel (must be odd). Larger
  = smoother correction but uses curvature info from further away.
  Default `7`.

- kernel:

  Kernel shape for both stages. One of `"hanning"` (default; raised
  cosine) or `"uniform"` (boxcar).

- boundary:

  Edge-handling strategy. Currently only `"padding"` (repeat the first
  and last point so output length equals input length).

- cc_mode:

  If `FALSE`, returns just the moving-average result without curvature
  correction. Useful for comparison.

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

  Additional arguments passed to
  [`replace_na()`](http://animovement.dev/aniprocess/reference/replace_na.md)
  (e.g. `value`, `min_gap`, `max_gap`).

## Value

An aniframe of the same shape as the input, with the spatial columns
smoothed.

## Details

A plain moving average pulls each point toward the chord between its
neighbours, which lies *inside* the curve — so smoothed circles shrink
inward. CCMA (Steinecker & Wuensche, 2023) estimates how much shrinkage
the moving average caused at each point — from the local curvature and
the kernel — and pushes the result back outward by exactly that amount.

The algorithm has two stages:

1.  **Moving average** of the spatial coordinates with a kernel of width
    `window_width_ma`.

2.  **Curvature correction**: at each output position, sum a kernel of
    width `window_width_cc` of curvature-derived shifts and apply them
    outward in the curve's plane.

Because curvature is intrinsically multi-dimensional, this filter
operates on all spatial coordinates jointly (unlike the per-column
filters dispatched through
[`filter_aniframe()`](http://animovement.dev/aniprocess/reference/filter_aniframe.md)).
It is most useful for smoothing curved 2D or 3D trajectories where a
plain moving average visibly cuts corners; for general-purpose
time-series smoothing reach for
[`filter_gaussian()`](http://animovement.dev/aniprocess/reference/filter_gaussian.md)
or
[`filter_sgolay()`](http://animovement.dev/aniprocess/reference/filter_sgolay.md).

Smoothing is applied within the aniframe's existing grouping (driven by
`variables_what`), so each individual / track / keypoint is smoothed as
its own trajectory.

## References

Steinecker, T. & Wuensche, H.-J. (2023). A Simple and Model-Free Path
Filtering Algorithm for Smoothing and Accuracy. *2023 IEEE Intelligent
Vehicles Symposium (IV)*.

Reference Python implementation: <https://github.com/UniBwTAS/ccma>

## Examples

``` r
if (FALSE) { # \dontrun{
filter_ccma(tracking_data, window_width_ma = 11, window_width_cc = 7)
} # }
```
