# Apply Rolling Median Filter

Applies a rolling median filter to a numeric vector using
[`data.table::frollmedian()`](https://rdrr.io/pkg/data.table/man/froll.html).

## Usage

``` r
filter_rollmedian(
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

Edge handling matches
[`filter_rollmean()`](https://animovement.dev/aniprocess/reference/filter_rollmean.md):
partial windows at the edges for `align = "right"`/`"left"`; `NA` at the
edges for `align = "center"`.
