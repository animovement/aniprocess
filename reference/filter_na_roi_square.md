# Filter coordinates outside a rectangular ROI

Helper function for filter_na_roi() that handles rectangular ROIs. Sets
coordinates to NA if they fall outside the specified bounds.

## Usage

``` r
filter_na_roi_square(data, x_min, x_max, y_min, y_max)
```

## Arguments

- data:

  A data frame containing 'x' and 'y' coordinates

- x_min, x_max, y_min, y_max:

  Bounds of the rectangular ROI

## Value

A data frame with coordinates outside rectangular ROI set to NA
