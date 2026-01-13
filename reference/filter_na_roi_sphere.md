# Filter coordinates outside a circular/spherical ROI

Helper function for filter_na_roi() that handles circular (2D) or
spherical (3D) ROIs. Sets coordinates to NA if they fall outside the
specified circle/sphere.

## Usage

``` r
filter_na_roi_sphere(data, x_center, y_center, z_center, radius, has_z)
```

## Arguments

- data:

  An aniframe containing spatial coordinates.

- x_center, y_center, z_center:

  Center coordinates of the ROI.

- radius:

  Radius of the ROI.

- has_z:

  Logical indicating whether data has z coordinate.

## Value

An aniframe with coordinates outside ROI set to NA.
