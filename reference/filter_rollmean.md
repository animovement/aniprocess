# Apply Rolling Mean Filter

Applies a rolling mean filter to a numeric vector using
[`data.table::frollmean()`](https://rdrr.io/pkg/data.table/man/froll.html).

## Usage

``` r
filter_rollmean(
  x,
  window_width = 5,
  min_obs = 1,
  align = c("right", "left", "center")
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

## Value

Filtered numeric vector, same length as `x`.

## Details

For `align = "right"` or `"left"`, partial windows at the edges of the
series are computed (so position 1 with a width-5 right-aligned window
returns the value at position 1, not `NA`). For `align = "center"`,
edges are not partial: the first and last `(window_width - 1) %/% 2`
positions return `NA`. This is a limitation of the underlying
[`data.table::frollmean()`](https://rdrr.io/pkg/data.table/man/froll.html)
implementation.
