# Kalman Filter for Regular Time Series

Implements a Kalman filter for regularly sampled time series data with
automatic parameter selection based on sampling rate. The filter handles
missing values (NA) and provides noise reduction while preserving real
signal changes.

## Usage

``` r
filter_kalman(
  measurements,
  sampling_rate,
  base_Q = NULL,
  R = NULL,
  initial_state = NULL,
  initial_P = NULL
)
```

## Arguments

- measurements:

  Numeric vector containing the measurements to be filtered.

- sampling_rate:

  Numeric value specifying the sampling rate in Hz (frames per second).

- base_Q:

  Optional. Process variance. If NULL, automatically calculated based on
  sampling_rate. Represents expected rate of change in the true state.

- R:

  Optional. Measurement variance. If NULL, defaults to 0.1. Represents
  the noise level in your measurements.

- initial_state:

  Optional. Initial state estimate. If NULL, uses first non-NA
  measurement.

- initial_P:

  Optional. Initial state uncertainty. If NULL, calculated based on
  sampling_rate.

## Value

A numeric vector of the same length as measurements containing the
filtered values.

## Details

The function implements a simple Kalman filter with a constant position
model. When parameters are not explicitly provided, they are
automatically configured based on the sampling rate:

- base_Q scales inversely with sampling rate (base_Q ≈
  0.15/sampling_rate)

- R defaults to 0.1 (assuming moderate measurement noise)

- initial_P scales with sampling rate uncertainty

Missing values (NA) are handled by relying on the prediction step
without measurement updates.

## Note

Parameter selection guidelines:

- Increase R or decrease base_Q for smoother output

- Decrease R or increase base_Q for more responsive output

- For high-frequency data (\>100 Hz), consider reducing base_Q

- If you know your sensor's noise characteristics, set R to the square
  of the standard deviation

## See also

filter_kalman_irregular for handling irregularly sampled data

## Examples

``` r
# Basic usage with 60 Hz data
measurements <- c(1, 1.1, NA, 0.9, 1.2, NA, 0.8, 1.1)
filtered <- filter_kalman(measurements, sampling_rate = 60)

# Custom parameters for more aggressive filtering
filtered_custom <- filter_kalman(measurements,
                                sampling_rate = 60,
                                base_Q = 0.001,
                                R = 0.2)
```
