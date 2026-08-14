# Filter coordinates outside a region of interest (ROI)

Filters out coordinates that fall outside a specified region of interest
by setting them to NA. The ROI can be either rectangular/cuboid (defined
by min/max coordinates) or circular/spherical (defined by center and
radius). Handles 2D or 3D data according to whether a `z` column is
present.

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

  A data frame with numeric `x` and `y` columns (and optionally `z`) —
  typically supplied by
  [`dplyr::pick()`](https://dplyr.tidyverse.org/reference/pick.html)
  inside
  [`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html).
  To filter a whole aniframe, use
  [`filter_na_across()`](http://animovement.dev/aniprocess/reference/filter_na_across.md).

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

`data`, with coordinates outside the ROI set to `NA`.

## Examples

``` r
coords <- data.frame(
  x = rep(c(25, 50, 75), 3),
  y = rep(c(25, 50, 75), each = 3)
)

# Rectangular ROI
filter_na_roi(coords, x_min = 20, x_max = 60, y_min = 20, y_max = 60)
#>    x  y
#> 1 25 25
#> 2 50 25
#> 3 NA NA
#> 4 25 50
#> 5 50 50
#> 6 NA NA
#> 7 NA NA
#> 8 NA NA
#> 9 NA NA

# Circular ROI
filter_na_roi(coords, x_center = 50, y_center = 50, radius = 30)
#>    x  y
#> 1 NA NA
#> 2 50 25
#> 3 NA NA
#> 4 25 50
#> 5 50 50
#> 6 75 50
#> 7 NA NA
#> 8 50 75
#> 9 NA NA

# 3D cuboid ROI
coords_3d <- data.frame(
  x = rep(c(25, 75), 4),
  y = rep(c(25, 75), each = 2, times = 2),
  z = rep(c(25, 75), each = 4)
)

filter_na_roi(
  coords_3d,
  x_min = 20, x_max = 60,
  y_min = 20, y_max = 60,
  z_min = 20, z_max = 60
)
#>    x  y  z
#> 1 25 25 25
#> 2 NA NA NA
#> 3 NA NA NA
#> 4 NA NA NA
#> 5 NA NA NA
#> 6 NA NA NA
#> 7 NA NA NA
#> 8 NA NA NA
```
