# Filter coordinates outside a circular ROI

Helper function for filter_na_roi() that handles circular ROIs. Sets
coordinates to NA if they fall outside the specified circle.

## Usage

``` r
filter_na_roi_circle(data, x_center, y_center, radius)
```

## Arguments

- data:

  A data frame containing 'x' and 'y' coordinates

- x_center, y_center:

  Center coordinates of the circular ROI

- radius:

  Radius of the circular ROI

## Value

A data frame with coordinates outside circular ROI set to NA
