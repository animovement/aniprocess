# Apply CCMA to one group's coordinates.

Matrix-in, matrix-out adaptor around
[`ccma_filter_one()`](http://animovement.dev/aniprocess/reference/ccma_filter_one.md)
that takes and returns a data frame, so the result can be spliced back
over the spatial columns by
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html).

## Usage

``` r
ccma_filter_group(coords, ...)
```

## Arguments

- coords:

  A data frame of the group's spatial columns.

## Value

A data frame with the same names and shape as `coords`.
