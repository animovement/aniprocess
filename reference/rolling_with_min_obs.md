# Apply a data.table rolling function with a `min_obs` threshold

Wraps
[`data.table::frollmean()`](https://rdrr.io/pkg/data.table/man/froll.html)
/
[`data.table::frollmedian()`](https://rdrr.io/pkg/data.table/man/froll.html)
(or any compatible `frollX` function) and masks results where the window
contains fewer than `min_obs` non-NA values.

## Usage

``` r
rolling_with_min_obs(x, fn, window_width, min_obs, align)
```

## Arguments

- x:

  Numeric vector.

- fn:

  A `data.table` rolling function such as `frollmean` or `frollmedian`.

- window_width:

  Integer window width.

- min_obs:

  Minimum number of non-NA values per window.

- align:

  One of `"right"`, `"left"`, `"center"`.

## Value

Numeric vector of the same length as `x`.

## Details

For `align = "right"` or `"left"`, the underlying function runs with
`partial = TRUE` so positions near the edge use whatever values are
available. For `align = "center"`, `partial = TRUE` is not supported by
data.table, so partial windows at the edges return `NA`.
