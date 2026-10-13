# Apply a filter across an aniframe's spatial columns

**\[experimental\]**

The aniframe-level entry point to the `filter_*()` family. Applies a
named filter to the frame's declared position columns, within its
existing grouping.

## Usage

``` r
filter_across(
  data,
  method = c("gaussian", "rollmean", "rollmedian", "triangular", "sgolay", "lowpass",
    "highpass", "lowpass_fft", "highpass_fft", "kalman", "kalman_irregular", "one_euro",
    "ccma", "deadband"),
  variables = NULL,
  ...,
  on_deltas = FALSE
)
```

## Arguments

- data:

  An aniframe.

- method:

  Filter to apply. One of `"gaussian"`, `"rollmean"`, `"rollmedian"`,
  `"triangular"`, `"sgolay"`, `"lowpass"`, `"highpass"`,
  `"lowpass_fft"`, `"highpass_fft"`, `"kalman"`, `"kalman_irregular"`,
  `"one_euro"`, `"ccma"` or `"deadband"`.

- variables:

  Columns to filter, as a tidyselect expression. Defaults to the
  declared position columns.

- ...:

  Arguments passed to the underlying filter.

- on_deltas:

  If `TRUE`, difference each column, filter the differences, and
  re-integrate from the original starting value. For trackball data,
  where the raw measurements are per-frame displacements and the
  coordinates were integrated from them, smoothing belongs on the
  displacements rather than on the integrated positions.

  A `NA` among the filtered differences counts as no movement when
  accumulating, and is restored as `NA` at its own position, so one
  missing step does not blank the rest of the series.

## Value

An aniframe of the same shape, with the selected columns filtered.

## Details

This is the aniframe tier of the interface:

- [`filter_gaussian()`](https://animovement.dev/aniprocess/reference/filter_gaussian.md)
  and friends filter one vector — use them inside
  [`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html).

- [`filter_with()`](https://animovement.dev/aniprocess/reference/filter_with.md)
  does the same but picks the method by name.

- `filter_across()` applies a method to a whole aniframe.

Beyond looping over columns, it fills in what the frame already knows:
`sampling_rate` comes from metadata for the methods that need it, and
`"kalman_irregular"` takes its `times` from the index column
([`anicore::get_index()`](https://animovement.dev/anicore/reference/get_index.html)).
Either can still be passed explicitly to override.

`"ccma"` and `"deadband"` are multivariate — each output coordinate
depends on all of them — so they are applied jointly rather than column
by column, and need a Cartesian frame. `on_deltas` does not apply to
them.

## See also

[`filter_with()`](https://animovement.dev/aniprocess/reference/filter_with.md)
for the vector-level generic.

## Examples

``` r
tracking_data <- anicore::example_anipoint() |>
  anicore::set_metadata(sampling_rate = 30)

# sampling_rate is taken from the aniframe's metadata
filter_across(tracking_data, "lowpass", cutoff_freq = 5)
#> # Individuals:   1, 2, 3
#> # Keypoints:     head, neck, shoulder_right, shoulder_left, abdomen, hip_right,
#> #   hip_left, knee_right, knee_left, foot_right, foot_left
#> # Sessions:      1
#> # Trials:        1
#> # Sampling rate: 30 Hz
#> # Time:          00:00:00 to 00:00:02
#>    individual keypoint session trial  time       x       y confidence
#>         <int> <fct>      <int> <int> <int>   <dbl>   <dbl>      <dbl>
#>  1          1 head           1     1     1 -1.19   -0.361       0.774
#>  2          1 head           1     1     2 -1.02   -0.244       0.802
#>  3          1 head           1     1     3 -0.665  -0.0440      0.516
#>  4          1 head           1     1     4 -0.197   0.199       0.725
#>  5          1 head           1     1     5  0.128   0.430       0.484
#>  6          1 head           1     1     6  0.0956  0.569       0.779
#>  7          1 head           1     1     7 -0.248   0.538       0.566
#>  8          1 head           1     1     8 -0.602   0.313       0.931
#>  9          1 head           1     1     9 -0.654  -0.0415      0.578
#> 10          1 head           1     1    10 -0.314  -0.391       0.806
#> # ℹ 1,640 more rows

# restrict to some of the spatial columns
filter_across(tracking_data, "gaussian", variables = c(x, y), sigma = 2)
#> # Individuals:   1, 2, 3
#> # Keypoints:     head, neck, shoulder_right, shoulder_left, abdomen, hip_right,
#> #   hip_left, knee_right, knee_left, foot_right, foot_left
#> # Sessions:      1
#> # Trials:        1
#> # Sampling rate: 30 Hz
#> # Time:          00:00:00 to 00:00:02
#>    individual keypoint session trial  time      x        y confidence
#>         <int> <fct>      <int> <int> <int>  <dbl>    <dbl>      <dbl>
#>  1          1 head           1     1     1 -0.846 -0.135        0.774
#>  2          1 head           1     1     2 -0.736 -0.0350       0.802
#>  3          1 head           1     1     3 -0.573  0.0691       0.516
#>  4          1 head           1     1     4 -0.384  0.178        0.725
#>  5          1 head           1     1     5 -0.241  0.273        0.484
#>  6          1 head           1     1     6 -0.204  0.317        0.779
#>  7          1 head           1     1     7 -0.250  0.277        0.566
#>  8          1 head           1     1     8 -0.294  0.160        0.931
#>  9          1 head           1     1     9 -0.261  0.00314      0.578
#> 10          1 head           1     1    10 -0.142 -0.141        0.806
#> # ℹ 1,640 more rows
```
