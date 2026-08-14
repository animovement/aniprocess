#' Kalman Filter for Regular Time Series
#'
#' @description
#' Implements a Kalman filter for regularly sampled time series data with automatic
#' parameter selection based on sampling rate. The filter handles missing values (NA)
#' and provides noise reduction while preserving real signal changes.
#'
#' @param x Numeric vector of measurements to be filtered.
#' @param sampling_rate Numeric value specifying the sampling rate in Hz (frames per second).
#' @param base_Q Optional. Process variance. If NULL, automatically calculated based on sampling_rate.
#'          Represents expected rate of change in the true state.
#' @param R Optional. Measurement variance. If NULL, defaults to 0.1.
#'          Represents the noise level in your measurements.
#' @param initial_state Optional. Initial state estimate. If NULL, uses first non-NA measurement.
#' @param initial_P Optional. Initial state uncertainty. If NULL, calculated based on sampling_rate.
#' @param keep_na Logical. If `TRUE`, positions that were `NA` in
#'   `x` are `NA` in the output. Defaults to `FALSE`, unlike the
#'   rest of the filter family: a Kalman filter's predict step is designed
#'   to carry the state estimate through missing observations, so inferring
#'   across gaps is the intended behaviour rather than an accident. Set
#'   `TRUE` when you want gaps left as gaps.
#'
#' @return
#' A numeric vector of the same length as x containing the filtered values.
#'
#' @details
#' The function implements a simple Kalman filter with a constant position model.
#' When parameters are not explicitly provided, they are automatically configured based
#' on the sampling rate:
#'
#' * `base_Q` defaults to `var(x) / sampling_rate` (so the
#'   per-step process noise `Q = base_Q / sampling_rate` shrinks at higher
#'   sampling rates, where consecutive samples are closer together).
#' * `R` defaults to `min(mean(diff(x)^2) / 2, var(x) / 4)` if there are
#'   enough observations, else `0.1`.
#' * `initial_P` defaults to `var(x)` if there are enough
#'   observations, else `1`.
#'
#' Missing values (NA) are handled by relying on the prediction step without measurement updates.
#'
#' @examples
#' # Basic usage with 60 Hz data
#' x <- c(1, 1.1, NA, 0.9, 1.2, NA, 0.8, 1.1)
#' filtered <- filter_kalman(x, sampling_rate = 60)
#'
#' # Custom parameters for more aggressive filtering
#' filtered_custom <- filter_kalman(x,
#'                                 sampling_rate = 60,
#'                                 base_Q = 0.001,
#'                                 R = 0.2)
#'
#' @seealso
#' filter_kalman_irregular for handling irregularly sampled data
#'
#' @note
#' Parameter selection guidelines:
#' * Increase R or decrease base_Q for smoother output
#' * Decrease R or increase base_Q for more responsive output
#' * For high-frequency data (>100 Hz), consider reducing base_Q
#' * If you know your sensor's noise characteristics, set R to the square of the standard deviation
#'
#' @export
filter_kalman <- function(
  x,
  sampling_rate,
  base_Q = NULL,
  R = NULL,
  initial_state = NULL,
  initial_P = NULL,
  keep_na = FALSE
) {
  # Input validation
  if (!is.numeric(sampling_rate) || length(sampling_rate) != 1) {
    stop("sampling_rate must be a single numeric value")
  }
  ensure_keep_na(keep_na)
  if (
    sampling_rate <= 0 || is.infinite(sampling_rate) || is.na(sampling_rate)
  ) {
    stop("sampling_rate must be finite and positive")
  }
  if (length(x) == 0) {
    stop("x cannot be empty")
  }
  if (all(is.na(x))) {
    stop("At least one non-NA measurement is required")
  }

  # Get valid x for parameter estimation
  valid_measurements <- x[!is.na(x)]

  # Improved parameter auto-configuration
  if (is.null(base_Q)) {
    # If we have enough valid x for variance
    if (length(valid_measurements) > 1) {
      signal_var <- stats::var(valid_measurements)
    } else {
      signal_var <- 1 # Default if we can't compute variance
    }
    base_Q <- signal_var / sampling_rate
  }

  if (is.null(R)) {
    # If we have enough x for local differences
    if (length(valid_measurements) > 1) {
      local_diff_var <- mean(diff(valid_measurements)^2) / 2
      R <- min(local_diff_var, stats::var(valid_measurements) / 4)
    } else {
      R <- 0.1 # Default if we can't estimate noise
    }
  }

  if (is.null(initial_P)) {
    if (length(valid_measurements) > 1) {
      initial_P <- stats::var(valid_measurements)
    } else {
      initial_P <- 1 # Default if we can't compute variance
    }
  }

  n <- length(x)
  filtered <- numeric(n)

  # Initialize state
  x_hat <- if (is.null(initial_state)) {
    first_valid <- valid_measurements[1]
    x_hat <- first_valid # We know this exists due to earlier check
  } else {
    initial_state
  }

  P <- initial_P

  dt <- 1 / sampling_rate
  Q <- base_Q * dt

  # Process each measurement
  for (i in 1:n) {
    # Predict step
    x_hat_minus <- x_hat
    P_minus <- P + Q

    # Update step
    if (!is.na(x[i])) {
      # Kalman gain
      K <- P_minus / (P_minus + R)

      # Update state estimate
      x_hat <- x_hat_minus + K * (x[i] - x_hat_minus)

      # Update error covariance
      P <- (1 - K) * P_minus
    } else {
      # For NA values, just use prediction
      x_hat <- x_hat_minus
      P <- P_minus
    }

    filtered[i] <- x_hat
  }

  restore_na(filtered, is.na(x), keep_na)
}

#' Kalman Filter for Irregular Time Series with Optional Resampling
#'
#' @description
#' Implements a Kalman filter for irregularly sampled time series data with optional
#' resampling to regular intervals. Handles variable sampling rates, missing values,
#' and automatically adjusts process variance based on time intervals.
#'
#' @param x Numeric vector of measurements to be filtered.
#' @param times Numeric vector of timestamps corresponding to x.
#' @param base_Q Optional. Base process variance per second. If NULL, automatically calculated.
#' @param R Optional. Measurement variance. If NULL, defaults to 0.1.
#' @param initial_state Optional. Initial state estimate. If NULL, uses first non-NA measurement.
#' @param initial_P Optional. Initial state uncertainty. If NULL, calculated from median sampling rate.
#' @param resample Logical. Whether to return regularly resampled data (default: FALSE).
#' @param resample_freq Numeric. Desired sampling frequency in Hz for resampling (required if resample=TRUE).
#' @param keep_na Logical. If `TRUE`, positions that were `NA` in
#'   `x` are `NA` in the values reported on the original
#'   timestamps. Defaults to `FALSE`, for the reason given in
#'   [filter_kalman()]. When `resample = TRUE` this applies to
#'   `original_values` only — the resampled `values` sit on a different
#'   time grid, where input positions have no counterpart, so they are
#'   always interpolated from the complete filtered series.
#'
#' @return
#' If resample=FALSE:
#'   A numeric vector of filtered values corresponding to original timestamps
#' If resample=TRUE:
#'   A list containing:
#'   * time: Vector of regular timestamps
#'   * values: Vector of filtered values at regular timestamps
#'   * original_time: Original irregular timestamps
#'   * original_values: Filtered values at original timestamps
#'
#' @details
#' The function implements an adaptive Kalman filter that accounts for irregular
#' sampling intervals. Process variance is scaled by the time difference between
#' measurements, allowing proper uncertainty handling for variable sampling rates.
#'
#' Key features:
#' * Handles irregular sampling intervals
#' * Scales process variance with time gaps
#' * Optional resampling to regular intervals
#' * Automatic parameter selection based on median sampling rate
#' * Missing value (NA) handling
#'
#' When resampling, the function uses linear interpolation and warns if the requested
#' sampling frequency exceeds twice the median original sampling rate (Nyquist frequency).
#'
#' @examples
#' # Example with irregular sampling
#' x <- c(1, 1.1, NA, 0.9, 1.2, NA, 0.8, 1.1)
#' times <- c(0, 0.1, 0.3, 0.35, 0.5, 0.8, 0.81, 1.0)
#'
#' # Basic filtering with irregular samples
#' filtered <- filter_kalman_irregular(x, times)
#'
#' # Filtering with resampling to 50 Hz
#' filtered_resampled <- filter_kalman_irregular(x, times,
#'                                              resample = TRUE,
#'                                              resample_freq = 50)
#'
#' # Plot results
#' plot(times, x, type="p", col="blue")
#' lines(filtered_resampled$time, filtered_resampled$values, col="red")
#'
#' @note
#' Resampling considerations:
#' * Avoid resampling above twice the median original sampling rate
#' * Consider the physical meaning of your data when choosing resample_freq
#' * Be cautious of creating artifacts through high-frequency resampling
#'
#' Parameter selection guidelines:
#' * base_Q controls the expected rate of change per second
#' * R should reflect your measurement noise level
#' * For slow-changing signals, reduce base_Q
#' * For noisy x, increase R
#'
#' @seealso
#' filter_kalman for regularly sampled data
#'
#' @export
filter_kalman_irregular <- function(
  x,
  times,
  base_Q = NULL,
  R = NULL,
  initial_state = NULL,
  initial_P = NULL,
  resample = FALSE,
  resample_freq = NULL,
  keep_na = FALSE
) {
  ensure_keep_na(keep_na)
  # Previous input validation remains the same
  if (length(x) != length(times)) {
    stop("x and times must have the same length")
  }
  if (!is.numeric(times)) {
    stop("times must be numeric")
  }
  if (any(is.na(times)) || any(is.infinite(times))) {
    stop("times must be finite and not NA")
  }
  if (length(x) == 0) {
    stop("x cannot be empty")
  }
  if (all(is.na(x))) {
    stop("At least one non-NA measurement is required")
  }
  if (resample && is.null(resample_freq)) {
    stop("resample_freq must be provided when resample=TRUE")
  }

  # Check for non-decreasing times
  if (any(diff(times) < 0)) {
    stop("times must be monotonically increasing")
  }
  if (any(diff(times) == 0)) {
    warning(
      "Duplicate time points detected. Using x in order provided."
    )
  }

  # Get valid x for parameter estimation
  valid_measurements <- x[!is.na(x)]

  # Calculate median sampling rate
  time_diffs <- diff(times)
  time_diffs <- time_diffs[time_diffs > 0] # Exclude zero differences
  if (length(time_diffs) > 0) {
    median_rate <- 1 / stats::median(time_diffs)
  } else {
    median_rate <- 1
  }

  # Improved parameter auto-configuration
  if (is.null(base_Q)) {
    # If we have enough valid x for variance
    if (length(valid_measurements) > 1) {
      signal_var <- stats::var(valid_measurements)
      # Scale base_Q based on both variance and rate, but more conservative
      base_Q <- signal_var / (10 * median_rate)
    } else {
      base_Q <- 0.1 # Default if we can't compute variance
    }
  }

  if (is.null(R)) {
    # If we have enough x for local differences
    if (length(valid_measurements) > 1) {
      # Use both local differences and overall variance to estimate noise
      local_diff_var <- mean(diff(valid_measurements)^2) / 2
      signal_var <- stats::var(valid_measurements)
      R <- min(local_diff_var, signal_var / 10)
    } else {
      R <- 0.1 # Default if we can't estimate noise
    }
  }

  if (is.null(initial_P)) {
    if (length(valid_measurements) > 1) {
      initial_P <- stats::var(valid_measurements)
    } else {
      initial_P <- 1
    }
  }

  # Warn if resampling frequency is too high
  if (resample && resample_freq > 2 * median_rate) {
    warning(sprintf(
      "Requested resampling frequency (%g Hz) exceeds twice the median sampling rate (%g Hz).
            This may lead to poor interpolation.",
      resample_freq,
      median_rate
    ))
  }

  n <- length(x)
  filtered <- numeric(n)

  # Initialize state
  x_hat <- if (is.null(initial_state)) {
    valid_measurements[1] # We know this exists due to earlier check
  } else {
    initial_state
  }

  P <- initial_P
  last_time <- times[1]

  # Process each measurement
  for (i in 1:n) {
    dt <- max(times[i] - last_time, 0) # Prevent negative time differences
    Q <- base_Q * dt # Scale base_Q by time difference

    x_hat_minus <- x_hat
    P_minus <- P + Q

    if (!is.na(x[i])) {
      K <- P_minus / (P_minus + R)
      x_hat <- x_hat_minus + K * (x[i] - x_hat_minus)
      P <- (1 - K) * P_minus
      last_time <- times[i]
    } else {
      x_hat <- x_hat_minus
      P <- P_minus
    }

    filtered[i] <- x_hat
  }

  if (resample) {
    dt <- 1 / resample_freq
    regular_times <- seq(min(times), max(times), by = dt)
    # Resample from the complete series: the regular grid has no
    # correspondence with input positions, so keep_na cannot apply to it.
    regular_filtered <- stats::approx(
      times,
      filtered,
      regular_times,
      method = "linear",
      rule = 2
    )$y

    return(list(
      time = regular_times,
      values = regular_filtered,
      original_time = times,
      original_values = restore_na(filtered, is.na(x), keep_na)
    ))
  } else {
    return(restore_na(filtered, is.na(x), keep_na))
  }
}
