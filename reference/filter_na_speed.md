# Filter values by speed threshold

Filters out observations where the calculated speed exceeds a specified
threshold. Spatial coordinates and confidence values are replaced with
NA where speed is too high. Speed is calculated using numerical
differentiation of position over time.

## Usage

``` r
filter_na_speed(data, threshold = "auto")
```

## Arguments

- data:

  An aniframe containing spatial coordinates and a time column.

- threshold:

  A numeric value specifying the speed threshold, or "auto".

  - If numeric: Observations with speeds greater than this value will
    have their spatial and confidence values replaced with NA.

  - If "auto": Sets threshold at mean speed + 3 standard deviations.

## Value

An aniframe with the same structure as the input, but with spatial and
confidence values replaced by NA where speed exceeds the threshold.

## Details

Speed is calculated as the magnitude of the velocity vector, computed
using numerical differentiation via the `differentiate` function. For 2D
data, speed = sqrt(v_x^2 + v_y^2). For 3D data, speed = sqrt(v_x^2 +
v_y^2 + v_z^2).

When using `threshold = "auto"`, the function calculates the threshold
as the mean speed plus three standard deviations, which assumes
approximately normally distributed speeds.

## Examples

``` r
data <- aniframe::aniframe(
  time = 1:5,
  x = c(1, 2, 4, 7, 11),
  y = c(1, 1, 2, 3, 5),
  confidence = c(0.8, 0.9, 0.7, 0.85, 0.6)
)

# Filter data by a speed threshold of 3
filter_na_speed(data, threshold = 3)
#> Warning: Unknown or uninitialised column: `individual`.
#> # Individuals:
#> # Keypoints:   centroid
#>   keypoint  time     x     y confidence
#>   <fct>    <int> <dbl> <dbl>      <dbl>
#> 1 centroid     1     1     1        0.8
#> 2 centroid     2     2     1        0.9
#> 3 centroid     3     4     2        0.7
#> 4 centroid     4    NA    NA       NA  
#> 5 centroid     5    NA    NA       NA  

# Use automatic threshold
filter_na_speed(data, threshold = "auto")
#> Warning: Unknown or uninitialised column: `individual`.
#> # Individuals:
#> # Keypoints:   centroid
#>   keypoint  time     x     y confidence
#>   <fct>    <int> <dbl> <dbl>      <dbl>
#> 1 centroid     1     1     1       0.8 
#> 2 centroid     2     2     1       0.9 
#> 3 centroid     3     4     2       0.7 
#> 4 centroid     4     7     3       0.85
#> 5 centroid     5    11     5       0.6 
```
