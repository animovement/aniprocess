# Apply Triangular Filter

Applies a triangular smoothing filter — a rolling mean of width
`window_width` applied twice. The composition of two boxcars is a
triangular kernel, so the effective kernel width is
`2 * window_width - 1` with peak weight at the centre.

## Usage

``` r
filter_triangular(
  x,
  window_width = 5,
  min_obs = 1,
  align = c("center", "right", "left"),
  keep_na = TRUE
)
```

## Arguments

- x:

  Numeric vector to filter.

- window_width:

  Integer width of each rolling-mean pass. The effective triangular
  kernel has width `2 * window_width - 1`.

- min_obs:

  Minimum number of non-NA values required per window per pass. Defaults
  to `1`.

- align:

  Window alignment, passed to
  [`filter_rollmean()`](http://animovement.dev/aniprocess/reference/filter_rollmean.md).
  One of `"center"` (default), `"right"`, or `"left"`.

- keep_na:

  Logical. If `TRUE` (default), positions that were `NA` in the input
  are `NA` in the output — gaps stay gaps. If `FALSE`, the values used
  to fill those gaps are kept, so the output has **fewer `NA`s than the
  input** and genuinely-missing stretches come back as interpolated
  estimates.

## Value

Filtered numeric vector, same length as `x`.

## Details

For `align = "center"`, the underlying
[`filter_rollmean()`](http://animovement.dev/aniprocess/reference/filter_rollmean.md)
returns `NA` at the first and last `(window_width - 1) %/% 2` positions
of each pass, so the output has roughly `window_width - 1` `NA` values
at each edge.

`keep_na = TRUE` restores the positions that were `NA` in the input, but
note that this filter fills gaps more aggressively than a single
[`filter_rollmean()`](http://animovement.dev/aniprocess/reference/filter_rollmean.md)
pass: because the second pass smooths the output of the first, values
interpolated across a gap propagate outward. `keep_na` blanks the
original gap positions; it does not undo that spread into neighbouring
positions. Raise `min_obs` to suppress it.

Triangular smoothing is sometimes useful as a lightweight alternative to
a Gaussian kernel when the kernel shape is less critical than the
simplicity of the implementation.

## Examples

``` r
x <- c(1, 2, 3, 100, 5, 6, 7, 8, 9)
filter_triangular(x, window_width = 3)
#> [1]       NA 18.50000 24.33333 36.00000 26.33333 16.66667  7.00000  7.50000
#> [9]       NA
```
