# Filter low-confidence values in a dataset

This function replaces spatial coordinate values with `NA` if the
confidence values are below a specified threshold. The `confidence`
column is also filtered.

## Usage

``` r
filter_na_confidence(data, threshold = 0.6, confidence = NULL)
```

## Arguments

- data:

  A data frame of numeric coordinate columns — typically supplied by
  [`dplyr::pick()`](https://dplyr.tidyverse.org/reference/pick.html)
  inside
  [`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html).
  To filter a whole aniframe, use
  [`filter_na_across()`](http://animovement.dev/aniprocess/reference/filter_na_across.md).

- threshold:

  A numeric value specifying the minimum confidence level to retain
  data. Must be a single value between 0 and 1. Default is 0.6.

- confidence:

  Numeric vector of confidence values, one per row.

## Value

`data`, with coordinates replaced by `NA` where confidence is below the
threshold.

## Details

A missing confidence means *not scored*, not *scored badly*, so those
rows are left unfiltered. A human annotator has no natural number to
enter for "I did not assess this", and tracker scores are not bounded at
1 — SLEAP can exceed it — so `NA` is the sensible thing to record rather
than a sentinel value. A warning reports how many were missing, since
silently skipping them would hide that those rows were never checked. To
drop them as well, filter `confidence` directly with
[`filter_na_range()`](http://animovement.dev/aniprocess/reference/filter_na_range.md).

## Input shape

Takes and returns a frame of coordinate columns, so it composes inside
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html):

    data |> mutate(
      filter_na_confidence(pick(all_of(c("x", "y"))), confidence = confidence)
    )

The decision uses all coordinates at once, so this cannot be used with
[`dplyr::across()`](https://dplyr.tidyverse.org/reference/across.html).
`confidence` is not a coordinate and so is never modified here;
[`filter_na_across()`](http://animovement.dev/aniprocess/reference/filter_na_across.md)
filters it as well.

## Examples

``` r
coords <- data.frame(x = 1:5, y = 6:10)
filter_na_confidence(
  coords,
  threshold = 0.6,
  confidence = c(0.5, 0.7, 0.4, 0.8, 0.9)
)
#>    x  y
#> 1 NA NA
#> 2  2  7
#> 3 NA NA
#> 4  4  9
#> 5  5 10
```
