#' Apply Gaussian Kernel Smoother
#'
#' Convolves a numeric vector with a discrete Gaussian kernel.
#'
#' @param x Numeric vector to filter.
#' @param sigma Standard deviation of the Gaussian kernel, in samples
#'   (frames). Must be positive.
#' @param window_width Integer kernel width in samples. Must be positive
#'   and is forced to be odd. Defaults to `2 * ceiling(3 * sigma) + 1`,
#'   which truncates the kernel at ±3σ.
#' @inheritParams filter-na-args
#'
#' @details
#' The kernel is symmetric and centered: `weights[k] = dnorm(k, sd = sigma)`
#' for `k` in `-half:half` (where `half = (window_width - 1) / 2`),
#' renormalised to sum to 1. The output is the kernel-weighted moving
#' average of `x`.
#'
#' At each position, weights for kernel taps that would fall outside `x`
#' or that align with `NA` values are excluded, and the remaining weights
#' are renormalised. This means edges and isolated `NA`s are handled
#' gracefully without contaminating the result. A position whose entire
#' window is `NA` returns `NA`.
#'
#' Larger `sigma` gives heavier smoothing. For movement data, typical
#' values range from `0.5` (very light smoothing) to `5` (heavy
#' smoothing).
#'
#' @return Filtered numeric vector, same length as `x`.
#'
#' @examples
#' x <- c(1, 2, 3, 100, 5, 6, 7)
#' filter_gaussian(x, sigma = 1)
#'
#' @export
filter_gaussian <- function(x, sigma = 1, window_width = NULL, keep_na = TRUE) {
  if (!is.numeric(sigma) || length(sigma) != 1L || sigma <= 0) {
    cli::cli_abort("{.arg sigma} must be a single positive number.")
  }
  ensure_keep_na(keep_na)
  na_positions <- is.na(x)
  if (is.null(window_width)) {
    window_width <- 2L * as.integer(ceiling(3 * sigma)) + 1L
  }
  if (
    !is.numeric(window_width) || length(window_width) != 1L || window_width < 1
  ) {
    cli::cli_abort("{.arg window_width} must be a single positive integer.")
  }
  window_width <- as.integer(window_width)
  if (window_width %% 2L == 0L) {
    window_width <- window_width + 1L
  }

  half <- (window_width - 1L) %/% 2L
  offsets <- (-half):half
  weights <- stats::dnorm(offsets, mean = 0, sd = sigma)
  weights <- weights / sum(weights)

  n <- length(x)
  num <- numeric(n)
  den <- numeric(n)
  for (i in seq_along(offsets)) {
    src <- seq_len(n) + offsets[i]
    in_range <- src >= 1L & src <= n
    val <- rep(NA_real_, n)
    val[in_range] <- x[src[in_range]]
    has_val <- !is.na(val)
    num[has_val] <- num[has_val] + weights[i] * val[has_val]
    den[has_val] <- den[has_val] + weights[i]
  }

  result <- num / den
  result[den == 0] <- NA_real_
  restore_na(result, na_positions, keep_na)
}
