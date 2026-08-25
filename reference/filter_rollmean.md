# Apply Rolling Mean Filter

Applies a rolling mean filter to a numeric vector using
[`data.table::frollmean()`](https://rdrr.io/pkg/data.table/man/froll.html).

## Usage

``` r
filter_rollmean(
  x,
  window_width = 5,
  min_obs = 1,
  align = c("right", "left", "center"),
  keep_na = TRUE
)
```

## Arguments

- x:

  Numeric vector to filter.

- window_width:

  Integer specifying window size for the rolling calculation.

- min_obs:

  Minimum number of non-NA values required in the window. Positions with
  fewer non-NA values return `NA`. Defaults to `1`.

- align:

  Window alignment. One of `"right"` (default), `"left"`, or `"center"`.

- keep_na:

  Logical. If `TRUE` (default), positions that were `NA` in the input
  are `NA` in the output — gaps stay gaps. If `FALSE`, the values used
  to fill those gaps are kept, so the output has **fewer `NA`s than the
  input** and genuinely-missing stretches come back as interpolated
  estimates.

## Value

Filtered numeric vector, same length as `x`.

## Details

`keep_na` and `min_obs` control different things and are usually worth
setting together. `keep_na` governs positions that were `NA` in the
*input*; `min_obs` governs positions that were observed but whose
*window* is too sparse to trust. Neither substitutes for the other: with
`min_obs = 1`, positions next to a gap still produce values drawn from
very few observations, and no `min_obs` setting blanks the input gaps
without also blanking their neighbours and the series edges.

For `align = "right"` or `"left"`, partial windows at the edges of the
series are computed (so position 1 with a width-5 right-aligned window
returns the value at position 1, not `NA`). For `align = "center"`,
edges are not partial: the first and last `(window_width - 1) %/% 2`
positions return `NA`. This is a limitation of the underlying
[`data.table::frollmean()`](https://rdrr.io/pkg/data.table/man/froll.html)
implementation.

## Examples

``` r
x <- c(1, 2, 100, 4, 5, 6, 7)
filter_rollmean(x, window_width = 3)
#> [1]  1.00000  1.50000 34.33333 35.33333 36.33333  5.00000  6.00000

# Centring the window changes which samples are averaged, and leaves NA at
# both edges rather than one
filter_rollmean(x, window_width = 3, align = "center")
#> [1]       NA 34.33333 35.33333 36.33333  5.00000  6.00000       NA
```
