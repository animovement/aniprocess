#' Apply Butterworth Lowpass Filter to Signal
#'
#' This function applies a lowpass Butterworth filter to a signal using forward-backward
#' filtering (filtfilt) to achieve zero phase distortion. The Butterworth filter is
#' maximally flat in the passband, making it ideal for many signal processing applications.
#'
#' @param x Numeric vector containing the signal to be filtered
#' @param cutoff_freq Cutoff frequency in Hz. Frequencies below this value are passed,
#'        while frequencies above are attenuated. Should be between 0 and sampling_rate/2.
#' @param sampling_rate Sampling rate of the signal in Hz. Must be at
#'        least twice the highest frequency component in the signal (Nyquist criterion).
#' @param order Filter order (default = 4). Controls the steepness of frequency rolloff:
#'        - Higher orders give sharper cutoffs but may introduce more ringing
#'        - Lower orders give smoother transitions but less steep rolloff
#'        - Common values in practice are 2-8
#'        - Values above 8 are rarely used due to numerical instability
#' @inheritParams filter-na-args
#' @param ... Additional arguments passed to replace_na(). Common options include:
#'        - value: Numeric value for replacement when na_action = "value"
#'        - min_gap: Minimum gap size to interpolate/fill
#'        - max_gap: Maximum gap size to interpolate/fill
#'
#' @details
#' The Butterworth filter response falls off at -6*order dB/octave. The cutoff frequency
#' corresponds to the -3dB point of the filter's magnitude response.
#'
#' Parameter Selection Guidelines:
#' * cutoff_freq: Choose based on the frequency content you want to preserve
#' * sampling_rate: Should match your data collection rate
#' * order:
#'   - order=2: Gentle rolloff, minimal ringing (~12 dB/octave)
#'   - order=4: Standard choice, good balance (~24 dB/octave)
#'   - order=6: Steeper rolloff, some ringing (~36 dB/octave)
#'   - order=8: Very steep, may have significant ringing (~48 dB/octave)
#'   Note: For very low cutoff frequencies (<0.001 of Nyquist), order is automatically
#'   reduced to 2 to maintain stability.
#'
#' Common values by field:
#' * Biomechanics: order=2 or 4
#' * EEG/MEG: order=4 or 6
#' * Audio processing: order=2 to 8
#' * Mechanical vibrations: order=2 to 4
#'
#' Missing Value Handling:
#' The function uses replace_na() internally for handling missing values. See ?replace_na
#' for detailed information about each method and its parameters. NAs can optionally be
#' restored to their original positions after filtering using keep_na = TRUE.
#'
#' @return Numeric vector containing the filtered signal
#'
#' @examples
#' # Generate example signal: 2 Hz fundamental + 50 Hz noise
#' t <- seq(0, 1, by = 0.001)
#' x <- sin(2*pi*2*t) + 0.5*sin(2*pi*50*t)
#'
#' # Add some NAs
#' x[sample(length(x), 10)] <- NA
#'
#' # Basic filtering with linear interpolation for NAs
#' filtered <- filter_lowpass(x, cutoff_freq = 5, sampling_rate = 1000)
#'
#' # Using spline interpolation with max gap constraint
#' filtered <- filter_lowpass(x, cutoff_freq = 5, sampling_rate = 1000,
#'                           na_action = "spline", max_gap = 3)
#'
#' # Replace NAs with zeros before filtering
#' filtered <- filter_lowpass(x, cutoff_freq = 5, sampling_rate = 1000,
#'                           na_action = "value", value = 0)
#'
#' # Filter but keep NAs in their original positions
#' filtered <- filter_lowpass(x, cutoff_freq = 5, sampling_rate = 1000,
#'                           na_action = "linear", keep_na = TRUE)
#'
#' @seealso
#' \code{\link{replace_na}} for details on NA handling methods
#' \code{\link{filter_highpass}} for high-pass filtering
#'
#' @references
#' Butterworth, S. (1930). On the Theory of Filter Amplifiers.
#' Wireless Engineer, 7, 536-541.
#'
#' @export
filter_lowpass <- function(
  x,
  cutoff_freq,
  sampling_rate,
  order = 4,
  na_action = c("linear", "spline", "stine", "locf", "value", "error"),
  keep_na = TRUE,
  ...
) {
  # Check that signal is installed
  check_signal()

  # Input validation
  if (!is.numeric(x)) {
    cli::cli_abort("Input signal must be numeric")
  }
  if (cutoff_freq <= 0 || cutoff_freq >= sampling_rate / 2) {
    cli::cli_abort("Cutoff frequency must be between 0 and sampling_rate/2")
  }
  if (order < 1 || order > 8) {
    cli::cli_abort("Filter order should be between 1 and 8")
  }

  na_action <- match.arg(na_action)
  ensure_keep_na(keep_na)

  prepared <- prepare_na(x, na_action, list(...))
  x <- prepared$x

  # For very low cutoff frequencies (<0.001 normalized), reduce order
  nyquist_freq <- sampling_rate / 2
  normalized_cutoff <- cutoff_freq / nyquist_freq

  if (normalized_cutoff < 0.001 & order > 2) {
    order <- min(order, 2) # Limit order for very low frequencies
    cli::cli_warn(
      "Very low cutoff frequency detected. Reducing filter order to 2 for stability."
    )
  }

  # Add reflection padding to reduce edge effects
  n_pad <- max(round(sampling_rate / cutoff_freq), order * 10)
  start_pad <- rev(x[1:min(n_pad, length(x))])
  end_pad <- rev(x[(length(x) - min(n_pad, length(x)) + 1):length(x)])
  x_padded <- c(start_pad, x, end_pad)

  # Create and apply filter
  bf <- signal::butter(order, normalized_cutoff, type = "low")
  filtered_padded <- signal::filtfilt(bf, x_padded)

  # Remove padding and ensure original length
  filtered <- filtered_padded[(n_pad + 1):(n_pad + length(x))]

  restore_na(filtered, prepared$na_positions, keep_na)
}

#' Apply Butterworth Highpass Filter to Signal
#'
#' This function applies a highpass Butterworth filter to a signal using forward-backward
#' filtering (filtfilt) to achieve zero phase distortion. The Butterworth filter is
#' maximally flat in the passband, making it ideal for many signal processing applications.
#'
#' @param x Numeric vector containing the signal to be filtered
#' @param cutoff_freq Cutoff frequency in Hz. Frequencies above this value are passed,
#'        while frequencies below are attenuated. Should be between 0 and sampling_rate/2.
#' @param sampling_rate Sampling rate of the signal in Hz. Must be at
#'        least twice the highest frequency component in the signal (Nyquist criterion).
#' @param order Filter order (default = 4). Controls the steepness of frequency rolloff:
#'        - Higher orders give sharper cutoffs but may introduce more ringing
#'        - Lower orders give smoother transitions but less steep rolloff
#'        - Common values in practice are 2-8
#'        - Values above 8 are rarely used due to numerical instability
#' @inheritParams filter-na-args
#' @param ... Additional arguments passed to replace_na(). Common options include:
#'        - value: Numeric value for replacement when na_action = "value"
#'        - min_gap: Minimum gap size to interpolate/fill
#'        - max_gap: Maximum gap size to interpolate/fill
#'
#' @details
#' The Butterworth filter response falls off at -6*order dB/octave. The cutoff frequency
#' corresponds to the -3dB point of the filter's magnitude response.
#'
#' Common Applications:
#' * Removing baseline drift: Use low cutoff (0.1-1 Hz)
#' * EMG analysis: Use moderate cutoff (10-20 Hz)
#' * Motion artifact removal: Use application-specific cutoff
#'
#' Parameter Selection Guidelines:
#' * cutoff_freq: Choose based on the lowest frequency you want to preserve
#' * order: Same guidelines as lowpass_filter
#'
#' Common values by field:
#' * ECG processing: order=2, cutoff=0.5 Hz
#' * EEG analysis: order=4, cutoff=1 Hz
#' * Mechanical vibrations: order=2, cutoff application-specific
#'
#' Missing Value Handling:
#' The function uses replace_na() internally for handling missing values. See ?replace_na
#' for detailed information about each method and its parameters. NAs can optionally be
#' restored to their original positions after filtering using keep_na = TRUE.
#'
#' @return Numeric vector containing the filtered signal
#'
#' @examples
#' # Generate example signal with drift
#' t <- seq(0, 1, by = 0.001)
#' drift <- 0.5 * t  # Linear drift
#' signal <- sin(2*pi*10*t)  # 10 Hz signal
#' x <- signal + drift
#'
#' # Add some NAs
#' x[sample(length(x), 10)] <- NA
#'
#' # Basic filtering with linear interpolation for NAs
#' filtered <- filter_highpass(x, cutoff_freq = 2, sampling_rate = 1000)
#'
#' # Using spline interpolation with max gap constraint
#' filtered <- filter_highpass(x, cutoff_freq = 2, sampling_rate = 1000,
#'                            na_action = "spline", max_gap = 3)
#'
#' # Replace NAs with zeros before filtering
#' filtered <- filter_highpass(x, cutoff_freq = 2, sampling_rate = 1000,
#'                            na_action = "value", value = 0)
#'
#' # Filter but keep NAs in their original positions
#' filtered <- filter_highpass(x, cutoff_freq = 2, sampling_rate = 1000,
#'                            na_action = "linear", keep_na = TRUE)
#'
#' @seealso
#' \code{\link{replace_na}} for details on NA handling methods
#' \code{\link{filter_lowpass}} for low-pass filtering
#'
#' @references
#' Butterworth, S. (1930). On the Theory of Filter Amplifiers.
#' Wireless Engineer, 7, 536-541.
#'
#' @export
filter_highpass <- function(
  x,
  cutoff_freq,
  sampling_rate,
  order = 4,
  na_action = c("linear", "spline", "stine", "locf", "value", "error"),
  keep_na = TRUE,
  ...
) {
  # Check that signal is installed
  check_signal()

  # Input validation
  if (!is.numeric(x)) {
    cli::cli_abort("Input signal must be numeric")
  }
  if (cutoff_freq <= 0 || cutoff_freq >= sampling_rate / 2) {
    cli::cli_abort("Cutoff frequency must be between 0 and sampling_rate/2")
  }
  if (order < 1 || order > 8) {
    cli::cli_abort("Filter order should be between 1 and 8")
  }

  na_action <- match.arg(na_action)
  ensure_keep_na(keep_na)

  prepared <- prepare_na(x, na_action, list(...))
  x <- prepared$x

  # For very low cutoff frequencies (<0.001 normalized), reduce order
  nyquist_freq <- sampling_rate / 2
  normalized_cutoff <- cutoff_freq / nyquist_freq

  if (normalized_cutoff < 0.001 & order > 2) {
    order <- min(order, 2) # Limit order for very low frequencies
    cli::cli_warn(
      "Very low cutoff frequency detected. Reducing filter order to 2 for stability."
    )
  }

  # Add reflection padding to reduce edge effects
  n_pad <- max(round(sampling_rate / cutoff_freq), order * 10)
  start_pad <- rev(x[1:min(n_pad, length(x))])
  end_pad <- rev(x[(length(x) - min(n_pad, length(x)) + 1):length(x)])
  x_padded <- c(start_pad, x, end_pad)

  # Create and apply filter
  bf <- signal::butter(order, normalized_cutoff, type = "high")
  filtered_padded <- signal::filtfilt(bf, x_padded)

  # Remove padding and ensure original length
  filtered <- filtered_padded[(n_pad + 1):(n_pad + length(x))]

  restore_na(filtered, prepared$na_positions, keep_na)
}
