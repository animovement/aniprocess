#' Apply Gaussian Smoothing Filter
#'
#' Applies a Gaussian smoothing filter to a numeric vector. The Gaussian kernel
#' provides smooth, symmetric weighting that decreases with distance from the
#' centre point.
#'
#' @param x Numeric vector containing the data to be filtered
#' @param window_size Integer specifying the window size in number of observations
#'        (default = 11).
#' @param alpha Controls the breadth of the Gaussian window (default = 2.5).
#'        Lower values produce broader, smoother kernels; higher values produce
#'        narrower, more localised smoothing.
#' @param keep_edges Logical indicating whether to include smoothed values at
#'        the signal edges where the full window cannot be applied (default = TRUE).
#'        When TRUE, partial windows are normalised to maintain proper weighting.
#'        When FALSE, edge regions are set to NA.
#' @param na_action Method to handle NA values before filtering. One of:
#'        - "linear": Linear interpolation (default)
#'        - "spline": Spline interpolation for smoother curves
#'        - "locf": Last observation carried forward
#'        - "value": Replace with a constant value
#'        - "error": Raise an error if NAs are present
#' @param keep_na Logical indicating whether to restore NAs to their original
#'        positions after filtering (default = FALSE)
#' @param ... Additional arguments passed to `replace_na()`
#'
#' @details
#' The Gaussian filter applies a weighted moving average where weights follow
#' a Gaussian (normal) distribution. This produces smooth results without the
#' sharp cutoffs of rectangular windows.
#'
#' Parameter Selection Guidelines
#'
#' * window_size: Larger windows produce more smoothing
#'   - 5-11: Light smoothing, preserves most detail
#'   - 11-21: Moderate smoothing
#'   - 21+: Heavy smoothing
#'
#' * alpha: Controls Gaussian kernel shape
#'   - alpha = 1.5-2: Broader kernel, more smoothing per window size
#'   - alpha = 2.5: Standard (default)
#'   - alpha = 3-4: Narrower kernel, less smoothing per window size
#'
#' @return Numeric vector containing the filtered data
#'
#' @examples
#' # Generate noisy data
#' x <- sin(seq(0, 4 * pi, length.out = 100)) + rnorm(100, sd = 0.2)
#'
#' # Basic smoothing with defaults
#' smoothed <- filter_gaussian(x)
#'
#' # Heavier smoothing with larger window
#' smoothed_heavy <- filter_gaussian(x, window_size = 21)
#'
#' # Narrower kernel for less smoothing
#' smoothed_light <- filter_gaussian(x, window_size = 11, alpha = 3.5)
#'
#' @seealso
#' \code{\link{filter_sgolay}} for polynomial smoothing that better preserves peaks
#' \code{\link{filter_lowpass}} for frequency-based filtering
#'
#' @export
filter_gaussian <- function(
  x,
  window_size = 11L,
  alpha = 2.5,
  keep_edges = TRUE,
  na_action = c("linear", "spline", "locf", "value", "error"),
  keep_na = FALSE,
  ...
) {
  # Input validation
  if (!is.numeric(x)) {
    cli::cli_abort("{.arg x} must be numeric.")
  }
  if (!is.numeric(alpha) || alpha <= 0) {
    cli::cli_abort("{.arg alpha} must be a positive number.")
  }
  if (!is.numeric(window_size) || window_size < 1) {
    cli::cli_abort("{.arg window_size} must be a positive integer.")
  }

  window_size <- as.integer(window_size)
  n <- length(x)

  if (window_size >= n) {
    cli::cli_abort(
      "{.arg window_size} ({window_size}) must be smaller than data length ({n})."
    )
  }

  na_action <- match.arg(na_action)

  # Store original NA positions if needed
  na_positions <- if (keep_na) which(is.na(x))

  # Handle NAs
  if (any(is.na(x))) {
    if (na_action == "error") {
      cli::cli_abort("{.arg x} contains NA values.")
    }
    x <- replace_na(x, method = na_action, ...)
  }

  # Build and normalise Gaussian kernel
  kernel <- make_gaussian_kernel(window_size, alpha)
  kernel <- kernel / sum(kernel)

  # Apply convolution
  kernel_size <- length(kernel)
  half_left <- as.integer(kernel_size / 2)
  half_right <- kernel_size - half_left

  result <- vapply(
    seq_along(x),
    function(i) {
      idx_data <- (i - half_left):(i + half_right - 1)
      idx_valid <- idx_data >= 1 & idx_data <= n
      idx_kernel <- which(idx_valid)
      idx_data <- idx_data[idx_valid]

      # Renormalise kernel for partial windows
      k <- if (length(idx_kernel) != kernel_size) {
        kernel[idx_kernel] / sum(kernel[idx_kernel])
      } else {
        kernel
      }

      sum(x[idx_data] * k)
    },
    numeric(1)
  )

  # Handle edges
  if (!keep_edges) {
    result[c(seq_len(half_left), (n - half_right + 1):n)] <- NA
  }

  # Restore NAs if requested
  if (keep_na && length(na_positions) > 0) {
    result[na_positions] <- NA
  }

  result
}

#' Create Gaussian Kernel
#'
#' Generates a Gaussian kernel for use in smoothing operations.
#'
#' @param window_size Integer specifying the kernel width
#' @param alpha Numeric controlling the breadth of the Gaussian curve
#'
#' @return Numeric vector of kernel weights (not normalised)
#'
#' @keywords internal
make_gaussian_kernel <- function(window_size, alpha) {
  hw <- window_size / 2
  idx <- seq_len(window_size) - 1
  n_offset <- idx - as.integer(hw)
  exp(-0.5 * (alpha * n_offset / hw)^2)
}
