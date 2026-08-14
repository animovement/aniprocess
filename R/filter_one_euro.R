#' Apply the One Euro filter
#'
#' @description
#' An adaptive low-pass filter that trades jitter against lag according to
#' how fast the signal is moving: heavy smoothing while the subject is
#' nearly still, light smoothing while it moves quickly.
#'
#' @details
#' A fixed low-pass filter forces one compromise on the whole recording. Set
#' the cutoff low and slow passages come out clean but fast ones lag behind;
#' set it high and fast passages track well but slow ones jitter. The One
#' Euro filter (Casiez, Roussel & Vogel, 2012) removes the compromise by
#' making the cutoff a function of the estimated speed:
#'
#' \deqn{f_c = f_{c_{min}} + \beta |\dot{x}|}
#'
#' where \eqn{\dot{x}} is itself low-pass filtered, at `d_cutoff`, so that
#' noise in the derivative does not drive the cutoff around.
#'
#' Tuning, following the authors' advice, is two-stage:
#'
#' 1. Set `beta = 0` and lower `min_cutoff` until jitter is acceptable while
#'    the subject is still.
#' 2. Raise `beta` until lag is acceptable while it moves quickly.
#'
#' `min_cutoff` therefore governs the slow-movement end and `beta` the
#' fast-movement end, and the two can be tuned almost independently.
#'
#' The filter is recursive, so it needs a complete series: `NA`s are filled
#' by `na_action` before filtering. With `keep_na = TRUE` (the default) they
#' are restored afterwards, so the gaps are not silently invented.
#'
#' @param x Numeric vector to filter.
#' @param sampling_rate Sampling rate of the signal in Hz.
#' @param min_cutoff Minimum cutoff frequency in Hz, the cutoff used when
#'   the signal is not moving. Lower means smoother but laggier. Default `1`.
#' @param beta Speed coefficient. `0` gives a plain low-pass filter at
#'   `min_cutoff`; larger values raise the cutoff more sharply as the signal
#'   speeds up, cutting lag. Default `0`.
#' @param d_cutoff Cutoff frequency in Hz for the derivative estimate, which
#'   keeps noise in the derivative from driving the adaptation. Default `1`.
#' @inheritParams filter-na-args
#' @param ... Additional arguments passed to [replace_na_with()].
#'
#' @return Filtered numeric vector, same length as `x`.
#'
#' @references
#' Casiez, G., Roussel, N., & Vogel, D. (2012). 1 € Filter: A Simple
#' Speed-based Low-pass Filter for Noisy Input in Interactive Systems.
#' *Proceedings of the SIGCHI Conference on Human Factors in Computing
#' Systems (CHI '12)*, 2527–2530. \doi{10.1145/2207676.2208639}
#'
#' @examples
#' t <- seq(0, 2, by = 1 / 60)
#' x <- ifelse(t < 1, 0, 10) + rnorm(length(t), 0, 0.1)
#'
#' # beta = 0 is a plain low-pass: smooth, but slow to follow the step
#' filter_one_euro(x, sampling_rate = 60, min_cutoff = 0.5)
#'
#' # raising beta keeps the still passages smooth but tracks the step
#' filter_one_euro(x, sampling_rate = 60, min_cutoff = 0.5, beta = 0.5)
#'
#' @seealso [filter_lowpass()] for a fixed-cutoff Butterworth filter.
#' @export
filter_one_euro <- function(
  x,
  sampling_rate,
  min_cutoff = 1,
  beta = 0,
  d_cutoff = 1,
  na_action = c("linear", "spline", "stine", "locf", "value", "error"),
  keep_na = TRUE,
  ...
) {
  if (!is.numeric(x)) {
    cli::cli_abort("{.arg x} must be numeric.")
  }
  ensure_positive_scalar(sampling_rate, "sampling_rate")
  ensure_positive_scalar(min_cutoff, "min_cutoff")
  ensure_positive_scalar(d_cutoff, "d_cutoff")
  if (!is.numeric(beta) || length(beta) != 1L || is.na(beta) || beta < 0) {
    cli::cli_abort("{.arg beta} must be a single non-negative number.")
  }

  na_action <- match.arg(na_action)
  ensure_keep_na(keep_na)

  prepared <- prepare_na(x, na_action, list(...))
  result <- one_euro_core(
    prepared$x,
    dt = 1 / sampling_rate,
    min_cutoff = min_cutoff,
    beta = beta,
    d_cutoff = d_cutoff
  )

  restore_na(result, prepared$na_positions, keep_na)
}


#' The One Euro recursion.
#'
#' Assumes a complete series and a constant time step.
#'
#' @param x Numeric vector with no `NA`s.
#' @param dt Time step in seconds.
#' @param min_cutoff,beta,d_cutoff One Euro parameters.
#'
#' @return Numeric vector of the same length as `x`.
#' @keywords internal
one_euro_core <- function(x, dt, min_cutoff, beta, d_cutoff) {
  n <- length(x)
  if (n < 2L) {
    return(x)
  }

  out <- numeric(n)
  out[1L] <- x[1L]
  dx_hat <- 0

  # The derivative's smoothing factor is constant for a constant time step.
  a_d <- one_euro_alpha(dt, d_cutoff)

  for (i in 2:n) {
    # The derivative is taken against the previous *filtered* value, as in
    # the authors' reference implementation.
    dx <- (x[i] - out[i - 1L]) / dt
    dx_hat <- a_d * dx + (1 - a_d) * dx_hat

    cutoff <- min_cutoff + beta * abs(dx_hat)
    a <- one_euro_alpha(dt, cutoff)
    out[i] <- a * x[i] + (1 - a) * out[i - 1L]
  }
  out
}


#' Exponential smoothing factor for a cutoff frequency.
#'
#' `alpha = 1 / (1 + tau/dt)` with `tau = 1 / (2 * pi * cutoff)`, written in
#' the algebraically equivalent form used by the reference implementation.
#'
#' @param dt Time step in seconds.
#' @param cutoff Cutoff frequency in Hz.
#'
#' @return A smoothing factor in `(0, 1)`.
#' @keywords internal
one_euro_alpha <- function(dt, cutoff) {
  r <- 2 * pi * cutoff * dt
  r / (r + 1)
}
