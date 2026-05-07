# Calculate per-row outlier speed from 2D position and time

Returns the minimum of the backward and forward step speeds at each row.
Endpoints fall back to the one available side; if either side is NA, the
other is used (`pmin` with `na.rm = TRUE`).

## Usage

``` r
calculate_speed_2d(x, y, time)
```

## Arguments

- x:

  Numeric vector of x coordinates.

- y:

  Numeric vector of y coordinates.

- time:

  Numeric vector of time values.

## Value

Numeric vector of speed values, same length as `x`.
