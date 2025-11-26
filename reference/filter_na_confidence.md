# Filter low-confidence values in a dataset

This function replaces values in columns `x`, `y`, and optionally `z`
with `NA` if the confidence values are below a specified threshold. The
`confidence` column is also filtered.

## Usage

``` r
filter_na_confidence(data, threshold = 0.6)
```

## Arguments

- data:

  A data frame containing the columns `x`, `y`, and `confidence`. If a
  `z` column is present, it will also be filtered.

- threshold:

  A numeric value specifying the minimum confidence level to retain
  data. Must be a single value between 0 and 1. Default is 0.6.

## Value

A data frame with the same structure as the input, but where `x`, `y`,
`z` (if present), and `confidence` values are replaced with `NA` if the
confidence is below the threshold.

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
#> # Individuals: NA
#> # Keypoints:   NA
#>   individual keypoint  time     x     y confidence
#>   <fct>      <fct>    <int> <dbl> <dbl>      <dbl>
#> 1 NA         NA           1    NA    NA       NA  
#> 2 NA         NA           2     2     7        0.7
#> 3 NA         NA           3    NA    NA       NA  
#> 4 NA         NA           4     4     9        0.8
#> 5 NA         NA           5     5    10        0.9

# With z column (3D)
data_3d <- aniframe::aniframe(
  time = 1:5,
  x = 1:5,
  y = 6:10,
  z = 11:15,
  confidence = c(0.5, 0.7, 0.4, 0.8, 0.9)
)

filter_na_confidence(data_3d, threshold = 0.6)
#> # Individuals: NA
#> # Keypoints:   NA
#>   individual keypoint  time     x     y     z confidence
#>   <fct>      <fct>    <int> <dbl> <dbl> <dbl>      <dbl>
#> 1 NA         NA           1    NA    NA    NA       NA  
#> 2 NA         NA           2     2     7    12        0.7
#> 3 NA         NA           3    NA    NA    NA       NA  
#> 4 NA         NA           4     4     9    14        0.8
#> 5 NA         NA           5     5    10    15        0.9
```
