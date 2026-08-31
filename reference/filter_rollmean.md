# Apply Rolling Mean Filter

Applies a rolling mean filter to a numeric vector using
[`data.table::frollmean()`](https://rdrr.io/pkg/data.table/man/froll.html).

## Usage

``` r
filter_rollmean(
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

  Integer specifying window size for the rolling calculation.

- min_obs:

  Minimum number of non-NA values required in the window. Positions with
  fewer non-NA values return `NA`. Defaults to `1`.

- align:

  Window alignment. One of `"center"` (default), `"right"`, or `"left"`.
  A centred window is symmetric about the point, so the filtered signal
  keeps its timing; `"right"` looks only backwards, which is what you
  want when the next sample does not exist yet, at the cost of lagging
  the signal by `(window_width - 1) / 2` samples.

- keep_na:

  Logical. If `TRUE` (default), positions that were `NA` in the input
  are `NA` in the output — gaps stay gaps. If `FALSE`, the values used
  to fill those gaps are kept, so the output has **fewer `NA`s than the
  input** and genuinely-missing stretches come back as interpolated
  estimates.

## Value

Filtered numeric vector, same length as `x`.

## Details

A centred window is symmetric about the point it replaces, so the
filtered signal keeps its timing. A right-aligned one looks only
backwards, which is what you want when the next sample does not exist
yet — real-time tracking, closed-loop experiments — and lags the signal
by `(window_width - 1) / 2` samples in exchange. Smoothing before
`animetric::calculate_kinematics()` with a lagging filter moves every
event later by that much.

The trade runs the other way at the edges: a centred window has no data
beyond the ends of the series, so the first and last
`(window_width - 1) / 2` values are `NA`, where a right-aligned window
fills them from a partial window.

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
#> [1]       NA 34.33333 35.33333 36.33333  5.00000  6.00000       NA

# Centring the window changes which samples are averaged, and leaves NA at
# both edges rather than one
filter_rollmean(x, window_width = 3, align = "center")
#> [1]       NA 34.33333 35.33333 36.33333  5.00000  6.00000       NA
```
