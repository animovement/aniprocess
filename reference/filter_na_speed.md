# Filter values by speed threshold

Filters out single-frame outliers based on movement speed. Spatial
coordinates and confidence values at flagged rows are replaced with NA.

## Usage

``` r
filter_na_speed(data, threshold = "auto", time = NULL)
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

  A numeric value specifying the speed threshold, or "auto".

  - If numeric: Rows whose speed exceeds this value have their spatial
    and confidence values replaced with NA.

  - If "auto": Sets threshold at mean speed + 3 standard deviations.

- time:

  Numeric vector of time values, one per row.

## Value

`data`, with coordinates replaced by `NA` where speed exceeds the
threshold.

## Details

For each row, two step speeds are computed: the backward step (from the
previous row to this one) and the forward step (from this row to the
next), each as the magnitude of the position change divided by the time
step. The row's speed is the **minimum** of the two — so a row is only
flagged when both the step in *and* the step out are fast. This isolates
single-frame outliers (a position that jumps away and comes back) from
legitimate state changes (a sustained move to a new region), which only
have one fast step.

Endpoints have only one neighbor; their speed falls back to the
available one-sided step. NAs in inputs do not contaminate adjacent
rows: a missing coordinate at row `i` only affects row `i`'s speed
estimate.

Every row of `data` is treated as one continuous track: a step is formed
between each consecutive pair. Called via
[`filter_na_across()`](http://animovement.dev/aniprocess/reference/filter_na_across.md)
or with
[`dplyr::pick()`](https://dplyr.tidyverse.org/reference/pick.html)
inside a grouped
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html),
that means one group, so a step is never formed across a track boundary.

When using `threshold = "auto"`, the threshold is the mean speed plus
three standard deviations of the rows given. Called through
[`filter_na_across()`](http://animovement.dev/aniprocess/reference/filter_na_across.md)
that means one threshold per group; pass `threshold = "pooled"` there to
estimate a single threshold from every group at once instead.

## Input shape

Takes and returns a frame of coordinate columns, so it composes inside
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html):

    data |> mutate(filter_na_speed(pick(all_of(c("x", "y"))), time = time))

Speed depends on all coordinates jointly, so this cannot be used with
[`dplyr::across()`](https://dplyr.tidyverse.org/reference/across.html).
`confidence` is not a coordinate and so is never modified here;
[`filter_na_across()`](http://animovement.dev/aniprocess/reference/filter_na_across.md)
blanks it on masked rows.

## Examples

``` r
coords <- data.frame(x = c(1, 2, 4, 7, 11), y = c(1, 1, 2, 3, 5))

filter_na_speed(coords, threshold = 3, time = 1:5)
#>    x  y
#> 1  1  1
#> 2  2  1
#> 3  4  2
#> 4 NA NA
#> 5 NA NA
filter_na_speed(coords, threshold = "auto", time = 1:5)
#>    x y
#> 1  1 1
#> 2  2 1
#> 3  4 2
#> 4  7 3
#> 5 11 5
```
