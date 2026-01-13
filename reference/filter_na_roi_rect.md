# Filter coordinates outside a rectangular/cuboid ROI

Helper function for filter_na_roi() that handles rectangular (2D) or
cuboid (3D) ROIs. Sets coordinates to NA if they fall outside the
specified bounds.

## Usage

``` r
filter_na_roi_rect(data, x_min, x_max, y_min, y_max, z_min, z_max, has_z)
```

## Arguments

- data:

  An aniframe containing spatial coordinates.

- x_min, x_max, y_min, y_max, z_min, z_max:

  Bounds of the ROI.

- has_z:

  Logical indicating whether data has z coordinate.

## Value

An aniframe with coordinates outside ROI set to NA.
