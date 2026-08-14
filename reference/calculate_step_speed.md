# Calculate per-row outlier speed from position and time

Returns the minimum of the backward and forward step speeds at each row.
Endpoints fall back to the one available side; if either side is NA, the
other is used (`pmin` with `na.rm = TRUE`).

## Usage

``` r
calculate_step_speed(coords, time)
```

## Arguments

- coords:

  A data frame of numeric coordinate columns.

- time:

  Numeric vector of time values, same length as `nrow(coords)`.

## Value

Numeric vector of speed values, of length `nrow(coords)`.

## Details

Dimension-agnostic: the Euclidean step is summed over whatever columns
`coords` holds, so the same function serves 1D, 2D and 3D data. Intended
to be called inside
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
with [`dplyr::pick()`](https://dplyr.tidyverse.org/reference/pick.html),
which supplies one group's coordinates at a time.
