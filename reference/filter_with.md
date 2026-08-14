# Apply a filter by name

Generic entry point to the `filter_*()` family: pick the method with an
argument rather than by choosing a function. Useful when the method is
itself a parameter — comparing filters, or driving one from a config.

## Usage

``` r
filter_with(
  x,
  method = c("gaussian", "rollmean", "rollmedian", "triangular", "sgolay", "lowpass",
    "highpass", "lowpass_fft", "highpass_fft", "kalman", "kalman_irregular", "one_euro",
    "ccma"),
  ...
)
```

## Arguments

- x:

  A numeric vector, or a data frame of numeric coordinate columns.

- method:

  Filter to apply. One of `"gaussian"`, `"rollmean"`, `"rollmedian"`,
  `"triangular"`, `"sgolay"`, `"lowpass"`, `"highpass"`,
  `"lowpass_fft"`, `"highpass_fft"`, `"kalman"`, `"kalman_irregular"`,
  `"one_euro"` or `"ccma"`.

- ...:

  Arguments passed to the underlying filter.

## Value

The same shape as `x`, filtered.

## Details

Returns the same shape it is given. A numeric vector gives a numeric
vector; a data frame of coordinate columns gives a data frame.

Most methods are univariate and are applied one column at a time when
given a frame. `"ccma"` is multivariate — each output coordinate depends
on all of them — so it requires a frame and cannot be used with
[`dplyr::across()`](https://dplyr.tidyverse.org/reference/across.html).

Method-specific arguments are passed through `...`, so a required one
still has to be supplied: `sampling_rate` for `"sgolay"`, `"lowpass"`,
`"highpass"`, the `_fft` variants and `"kalman"`; `times` for
`"kalman_irregular"`; `cutoff_freq` for the frequency filters.

## See also

[`filter_across()`](http://animovement.dev/aniprocess/reference/filter_across.md)
to apply a filter across an aniframe's spatial columns.

## Examples

``` r
x <- c(1, 2, 3, 100, 5, 6, 7, 8, 9)

filter_with(x, "gaussian", sigma = 1)
#> [1]  2.127792  7.635157 26.352299 42.308827 28.235478 11.184536  7.414109
#> [8]  7.871160  8.480581
filter_with(x, "rollmean", window_width = 3)
#> [1]  1.0  1.5  2.0 35.0 36.0 37.0  6.0  7.0  8.0

# A frame is filtered column by column
filter_with(data.frame(x = x, y = rev(x)), "rollmean", window_width = 3)
#>      x    y
#> 1  1.0  9.0
#> 2  1.5  8.5
#> 3  2.0  8.0
#> 4 35.0  7.0
#> 5 36.0  6.0
#> 6 37.0 37.0
#> 7  6.0 36.0
#> 8  7.0 35.0
#> 9  8.0  2.0
```
