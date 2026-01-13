# Filter coordinates outside a region of interest (ROI)

Filters out coordinates that fall outside a specified region of interest
by setting them to NA. The ROI can be either rectangular/cuboid (defined
by min/max coordinates) or circular/spherical (defined by center and
radius). Automatically handles 2D or 3D data based on the spatial
variables in the aniframe metadata.

## Usage

``` r
filter_na_roi(
  data,
  x_min = NULL,
  x_max = NULL,
  y_min = NULL,
  y_max = NULL,
  z_min = NULL,
  z_max = NULL,
  x_center = NULL,
  y_center = NULL,
  z_center = NULL,
  radius = NULL
)
```

## Arguments

- data:

  An aniframe containing spatial coordinates.

- x_min, x_max:

  Bounds for x-coordinate (rectangular/cuboid ROI).

- y_min, y_max:

  Bounds for y-coordinate (rectangular/cuboid ROI).

- z_min, z_max:

  Bounds for z-coordinate (cuboid ROI, 3D only).

- x_center, y_center, z_center:

  Center coordinates for circular/spherical ROI. For 3D data, provide
  all three; for 2D data, only x and y.

- radius:

  Radius of circular (2D) or spherical (3D) ROI.

## Value

An aniframe with coordinates outside ROI set to NA.

## Examples

``` r
# Create sample 2D data
sample_data <- aniframe::aniframe(
  time = 1:9,
  x = rep(c(25, 50, 75), 3),
  y = rep(c(25, 50, 75), each = 3)
)

# Rectangular ROI example
sample_data |>
  filter_na_roi(x_min = 20, x_max = 60, y_min = 20, y_max = 60)
#> Warning: Unknown or uninitialised column: `individual`.
#> # Individuals:
#> # Keypoints:   centroid
#>   keypoint  time     x     y
#>   <fct>    <int> <dbl> <dbl>
#> 1 centroid     1    25    25
#> 2 centroid     2    50    25
#> 3 centroid     3    NA    NA
#> 4 centroid     4    25    50
#> 5 centroid     5    50    50
#> 6 centroid     6    NA    NA
#> 7 centroid     7    NA    NA
#> 8 centroid     8    NA    NA
#> 9 centroid     9    NA    NA

# Circular ROI example
sample_data |>
  filter_na_roi(x_center = 50, y_center = 50, radius = 30)
#> Warning: Unknown or uninitialised column: `individual`.
#> # Individuals:
#> # Keypoints:   centroid
#>   keypoint  time     x     y
#>   <fct>    <int> <dbl> <dbl>
#> 1 centroid     1    NA    NA
#> 2 centroid     2    50    25
#> 3 centroid     3    NA    NA
#> 4 centroid     4    25    50
#> 5 centroid     5    50    50
#> 6 centroid     6    75    50
#> 7 centroid     7    NA    NA
#> 8 centroid     8    50    75
#> 9 centroid     9    NA    NA

# 3D cuboid ROI example
sample_3d <- aniframe::aniframe(
  time = 1:8,
  x = rep(c(25, 75), 4),
  y = rep(c(25, 75), each = 2, times = 2),
  z = rep(c(25, 75), each = 4),
  variables_where = c("x", "y", "z")
)

sample_3d |>
  filter_na_roi(x_min = 20, x_max = 60, y_min = 20, y_max = 60, z_min = 20, z_max = 60)
#> Warning: Unknown or uninitialised column: `individual`.
#> # Individuals:
#> # Keypoints:   centroid
#>   keypoint  time     x     y     z
#>   <fct>    <int> <dbl> <dbl> <dbl>
#> 1 centroid     1    25    25    25
#> 2 centroid     2    NA    NA    NA
#> 3 centroid     3    NA    NA    NA
#> 4 centroid     4    NA    NA    NA
#> 5 centroid     5    NA    NA    NA
#> 6 centroid     6    NA    NA    NA
#> 7 centroid     7    NA    NA    NA
#> 8 centroid     8    NA    NA    NA
```
