# Mask low-confidence values to NA

This function replaces spatial coordinate values with `NA` if the
confidence values are below a specified threshold. The `confidence`
column is also masked.

## Usage

``` r
mask_na_confidence(data, threshold = 0.6, confidence = NULL)
```

## Arguments

- data:

  A data frame of numeric coordinate columns — typically supplied by
  [`dplyr::pick()`](https://dplyr.tidyverse.org/reference/pick.html)
  inside
  [`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html).
  To mask a whole aniframe, use
  [`mask_na_across()`](https://animovement.dev/aniprocess/reference/mask_na_across.md).

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
rows are left unmasked. A human annotator has no natural number to enter
for "I did not assess this", and tracker scores are not bounded at 1 —
SLEAP can exceed it — so `NA` is the sensible thing to record rather
than a sentinel value. A warning reports how many were missing, since
silently skipping them would hide that those rows were never checked. To
drop them as well, mask `confidence` directly with
[`mask_na_range()`](https://animovement.dev/aniprocess/reference/mask_na_range.md).

## Input shape

Takes and returns a frame of coordinate columns, so it composes inside
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html):

    data |> mutate(
      mask_na_confidence(pick(all_of(c("x", "y"))), confidence = confidence)
    )

The decision uses all coordinates at once, so this cannot be used with
[`dplyr::across()`](https://dplyr.tidyverse.org/reference/across.html).
`confidence` is not a coordinate and so is never modified here;
[`mask_na_across()`](https://animovement.dev/aniprocess/reference/mask_na_across.md)
masks it as well.

## Examples

``` r
coords <- data.frame(x = 1:5, y = 6:10)
mask_na_confidence(
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
