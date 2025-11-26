# Calculate Speed from Position Data

Calculates the instantaneous speed from x, y coordinates and time data.
Speed is computed as the absolute magnitude of velocity (change in
position over time).

## Usage

``` r
calculate_speed(x, y, time)
```

## Arguments

- x:

  Numeric vector of x coordinates

- y:

  Numeric vector of y coordinates

- time:

  Numeric vector of time values

## Value

Numeric vector of speeds. The first value will be NA since speed
requires two positions to calculate.

## Examples

``` r
if (FALSE) { # \dontrun{
# Inside dplyr pipeline
data |>
  group_by(keypoint) |>
  mutate(speed = calculate_speed(x, y, time))
} # }
```
