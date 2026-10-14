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

  A data frame of 2 or 3 numeric coordinate columns. The curvature math
  is Cartesian-specific (cross products, Euclidean norms, circumradius),
  so coordinates must be Cartesian. For a whole aniframe use
  [`filter_across()`](https://animovement.dev/aniprocess/reference/filter_across.md),
  which selects the declared position columns and rejects non-Cartesian
  frames.

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
  [`replace_na_with()`](https://animovement.dev/aniprocess/reference/replace_na_with.md)
  (e.g. `value`, `min_gap`, `max_gap`).

## Value

A data frame with the same names and shape as `data`, its coordinates
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
[`filter_across()`](https://animovement.dev/aniprocess/reference/filter_across.md)).
It is most useful for smoothing curved 2D or 3D trajectories where a
plain moving average visibly cuts corners; for general-purpose
time-series smoothing reach for
[`filter_gaussian()`](https://animovement.dev/aniprocess/reference/filter_gaussian.md)
or
[`filter_sgolay()`](https://animovement.dev/aniprocess/reference/filter_sgolay.md).

## Input shape

This is a **column-level** function: it takes a data frame of coordinate
columns and returns one of the same shape. The aniframe tier is
[`filter_across()`](https://animovement.dev/aniprocess/reference/filter_across.md),
which applies it within the frame's existing grouping so each individual
/ track / keypoint is smoothed as its own trajectory.

    filter_across(af, "ccma")                             # a whole aniframe
    data |> mutate(filter_ccma(pick(all_of(c("x", "y")))))  # the columns

[`dplyr::pick()`](https://dplyr.tidyverse.org/reference/pick.html)
supplies the columns and the result is spliced back over them.

CCMA is multivariate — each output coordinate depends on all of them —
so it cannot be used with
[`dplyr::across()`](https://dplyr.tidyverse.org/reference/across.html),
which passes one column at a time.

## References

Steinecker, T. & Wuensche, H.-J. (2023). A Simple and Model-Free Path
Filtering Algorithm for Smoothing and Accuracy. *2023 IEEE Intelligent
Vehicles Symposium (IV)*, 1-7.
[doi:10.1109/IV55152.2023.10186704](https://doi.org/10.1109/IV55152.2023.10186704)
.

Reference Python implementation: <https://github.com/UniBwTAS/ccma>

## Examples

``` r
# The column tier: a data frame of coordinates
coords <- data.frame(x = sin(seq(0, 6, length.out = 40)), y = seq(0, 6, length.out = 40))
head(filter_ccma(coords, window_width_ma = 11, window_width_cc = 7))
#>           x         y
#> 1 0.1335266 0.1323343
#> 2 0.2193066 0.2202318
#> 3 0.3248390 0.3313703
#> 4 0.4431924 0.4611623
#> 5 0.5652973 0.6035949
#> 6 0.6818460 0.7529515

# The aniframe tier
af <- anicore::example_anipoint(n_obs = 60, n_individuals = 1, n_keypoints = 1)
filter_across(af, "ccma", window_width_ma = 11, window_width_cc = 7)
#> # Individuals: 1
#> # Keypoints:   centroid
#> # Sessions:    1
#> # Trials:      1
#>    individual keypoint session trial  time        x        y confidence
#>         <int> <fct>      <int> <int> <int>    <dbl>    <dbl>      <dbl>
#>  1          1 centroid       1     1     1 -0.142    0.860        0.499
#>  2          1 centroid       1     1     2 -0.252    0.507        0.769
#>  3          1 centroid       1     1     3 -0.283    0.209        0.843
#>  4          1 centroid       1     1     4 -0.244    0.00557      0.695
#>  5          1 centroid       1     1     5 -0.0494  -0.108        0.952
#>  6          1 centroid       1     1     6  0.0759   0.0140       0.884
#>  7          1 centroid       1     1     7  0.0621   0.121        0.517
#>  8          1 centroid       1     1     8 -0.00571  0.168        0.689
#>  9          1 centroid       1     1     9 -0.0545   0.154        0.655
#> 10          1 centroid       1     1    10 -0.0552   0.188        0.772
#> # ℹ 50 more rows
```
