# Filter values by speed threshold

This function filters out values in a dataset where the calculated speed
exceeds a specified threshold. Values for `x`, `y`, and `confidence` are
replaced with `NA` if their corresponding speed exceeds the threshold.
Speed is calculated using the `calculate_kinematics` function.

## Usage

``` r
filter_na_speed(data, threshold = "auto")
```

## Arguments

- data:

  A data frame containing the following required columns:

  - `x`: x-coordinates

  - `y`: y-coordinates

  - `time`: time values Optional column:

  - `confidence`: confidence values for each observation

- threshold:

  A numeric value specifying the speed threshold, or "auto".

  - If numeric: Observations with speeds greater than this value will
    have their `x`, `y`, and `confidence` values replaced with `NA`

  - If "auto": Sets threshold at mean speed + 3 standard deviations

## Value

A data frame with the same columns as the input `data`, but with values
replaced by `NA` where the speed exceeds the threshold.

## Details

The speed is calculated using the `calculate_kinematics` function, which
computes translational velocity (`v_translation`) and other kinematic
parameters. When using `threshold = "auto"`, the function calculates the
threshold as the mean speed plus three standard deviations, which
assumes normally distributed speeds.

## Examples

``` r
if (FALSE) { # \dontrun{
data <- dplyr::tibble(
  time = 1:5,
  x = c(1, 2, 4, 7, 11),
  y = c(1, 1, 2, 3, 5),
  confidence = c(0.8, 0.9, 0.7, 0.85, 0.6)
)

# Filter data by a speed threshold of 3
filter_by_speed(data, threshold = 3)

# Use automatic threshold
filter_by_speed(data, threshold = "auto")
} # }
```
