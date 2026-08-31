# Apply Rolling Median Filter

Applies a rolling median filter to a numeric vector using
[`data.table::frollmedian()`](https://rdrr.io/pkg/data.table/man/froll.html).

## Usage

``` r
filter_rollmedian(
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

Edge handling matches
[`filter_rollmean()`](https://animovement.dev/aniprocess/reference/filter_rollmean.md):
partial windows at the edges for `align = "right"`/`"left"`; `NA` at the
edges for `align = "center"`.

## Examples

``` r
x <- c(1, 2, 100, 4, 5, 6, 7)
filter_rollmedian(x, window_width = 3)
#> [1] NA  2  4  5  5  6 NA

# The median discards the spike; a rolling mean smears it across three
# neighbouring samples instead
filter_rollmean(x, window_width = 3)
#> [1]       NA 34.33333 35.33333 36.33333  5.00000  6.00000       NA
```
