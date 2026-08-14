# Excursion mask for one group of coordinates.

Dispatches to the per-axis or joint state machine. Groups too short to
contain a step are never flagged.

## Usage

``` r
excursion_mask(coords, outlier_sd, return_sd, by_axis)
```

## Arguments

- coords:

  A data frame of the group's spatial columns.

- outlier_sd, return_sd:

  Thresholds, in units of the spatial SD.

- by_axis:

  If `TRUE`, run the per-axis machine; otherwise the joint one.

## Value

Logical vector of length `nrow(coords)`.
