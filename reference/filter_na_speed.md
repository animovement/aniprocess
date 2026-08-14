# Filter values by speed threshold

Filters out single-frame outliers based on movement speed. Spatial
coordinates and confidence values at flagged rows are replaced with NA.

## Usage

``` r
filter_na_speed(data, threshold = "auto")
```

## Arguments

- data:

  An aniframe containing spatial coordinates and a time column.

- threshold:

  A numeric value specifying the speed threshold, or "auto".

  - If numeric: Rows whose speed exceeds this value have their spatial
    and confidence values replaced with NA.

  - If "auto": Sets threshold at mean speed + 3 standard deviations.

## Value

An aniframe with the same structure as the input, but with spatial and
confidence values replaced by NA where speed exceeds the threshold.

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

Speed is computed **within each group** of a grouped aniframe, so a step
is never formed between the last row of one track and the first row of
the next. Each group's first and last rows are treated as endpoints. On
ungrouped data the whole frame is a single track.

When using `threshold = "auto"`, the threshold is set to the mean speed
plus three standard deviations, pooled across groups. Because no
cross-track step is ever formed, the estimate uses within-track speeds
only.

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
#> # Keypoints: centroid
#>   keypoint  time     x     y confidence
#>   <fct>    <int> <dbl> <dbl>      <dbl>
#> 1 centroid     1     1     1        0.8
#> 2 centroid     2     2     1        0.9
#> 3 centroid     3     4     2        0.7
#> 4 centroid     4    NA    NA       NA  
#> 5 centroid     5    NA    NA       NA  

# Use automatic threshold
filter_na_speed(data, threshold = "auto")
#> # Keypoints: centroid
#>   keypoint  time     x     y confidence
#>   <fct>    <int> <dbl> <dbl>      <dbl>
#> 1 centroid     1     1     1       0.8 
#> 2 centroid     2     2     1       0.9 
#> 3 centroid     3     4     2       0.7 
#> 4 centroid     4     7     3       0.85
#> 5 centroid     5    11     5       0.6 
```
