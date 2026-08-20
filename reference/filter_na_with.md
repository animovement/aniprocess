# Mask values to NA by a named criterion

Generic entry point to the `filter_na_*()` family: pick the criterion
with an argument rather than by choosing a function. Every method
replaces values that fail its criterion with `NA`; none of them fill or
smooth.

## Usage

``` r
filter_na_with(
  x,
  method = c("range", "speed", "excursion", "roi", "confidence"),
  ...
)
```

## Arguments

- x:

  A numeric vector, or a data frame of numeric coordinate columns.

- method:

  Criterion to apply. One of `"range"`, `"speed"`, `"excursion"`,
  `"roi"` or `"confidence"`.

- ...:

  Arguments passed to the underlying function.

## Value

The same shape as `x`, with failing values replaced by `NA`.

## Details

Returns the same shape it is given.

Only `"range"` is univariate, and it is applied one column at a time
when given a frame. The rest decide per row using all coordinates at
once, so they require a frame of coordinate columns and cannot be used
with
[`dplyr::across()`](https://dplyr.tidyverse.org/reference/across.html).

Method-specific arguments go through `...`: `min_value`/`max_value` for
`"range"`, `threshold` and `time` for `"speed"`,
`outlier_sd`/`return_sd` for `"excursion"`, the ROI bounds for `"roi"`,
and `threshold` plus `confidence` for `"confidence"`.

## See also

[`filter_with()`](https://animovement.dev/aniprocess/reference/filter_with.md)
for the smoothing and frequency filters,
[`replace_na_with()`](https://animovement.dev/aniprocess/reference/replace_na_with.md)
for filling gaps.

## Examples

``` r
filter_na_with(c(1, 5, 10, 15), "range", min_value = 3, max_value = 12)
#> [1] NA  5 10 NA

coords <- data.frame(x = c(0, 1, 2, 50, 4), y = c(0, 0, 0, 0, 0))
filter_na_with(coords, "speed", threshold = 10, time = 1:5)
#>    x  y
#> 1  0  0
#> 2  1  0
#> 3  2  0
#> 4 NA NA
#> 5 NA NA
```
