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

  An aniframe containing a `confidence` column and spatial columns as
  defined in the metadata's `variables_where`, or a data frame of
  numeric coordinate columns.

- threshold:

  A numeric value specifying the minimum confidence level to retain
  data. Must be a single value between 0 and 1. Default is 0.6.

- confidence:

  Numeric vector of confidence values, one per row. Required when `data`
  is a coordinate frame. When `data` is an aniframe this defaults to its
  `confidence` column.

## Value

The same shape as the input, with spatial values replaced by `NA` where
confidence is below the threshold. For an aniframe the `confidence`
column is filtered too.

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

Returns the same shape it is given.

- Given an **aniframe**, the columns named by `variables_where` are
  masked, along with `confidence`.

- Given a **data frame of coordinate columns**, that frame is masked and
  returned — the form to use inside
  [`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html):

    data |> mutate(
      filter_na_confidence(pick(all_of(c("x", "y"))), confidence = confidence)
    )

`confidence` is not a coordinate, so it is only filtered by the aniframe
form; the coordinate-frame form returns just the masked coordinates.

## Examples

``` r
# 2D example
data <- aniframe::aniframe(
  time = 1:5,
  x = 1:5,
  y = 6:10,
  confidence = c(0.5, 0.7, 0.4, 0.8, 0.9)
)

filter_na_confidence(data, threshold = 0.6)
#> # Keypoints: centroid
#>   keypoint  time     x     y confidence
#>   <fct>    <int> <dbl> <dbl>      <dbl>
#> 1 centroid     1    NA    NA       NA  
#> 2 centroid     2     2     7        0.7
#> 3 centroid     3    NA    NA       NA  
#> 4 centroid     4     4     9        0.8
#> 5 centroid     5     5    10        0.9

# With z column (3D)
data_3d <- aniframe::aniframe(
  time = 1:5,
  x = 1:5,
  y = 6:10,
  z = 11:15,
  confidence = c(0.5, 0.7, 0.4, 0.8, 0.9),
  variables_where = c("x", "y", "z")
)

filter_na_confidence(data_3d, threshold = 0.6)
#> # Keypoints: centroid
#>   keypoint  time     x     y     z confidence
#>   <fct>    <int> <dbl> <dbl> <dbl>      <dbl>
#> 1 centroid     1    NA    NA    NA       NA  
#> 2 centroid     2     2     7    12        0.7
#> 3 centroid     3    NA    NA    NA       NA  
#> 4 centroid     4     4     9    14        0.8
#> 5 centroid     5     5    10    15        0.9
```
