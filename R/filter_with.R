#' Apply a filter by name
#'
#' @description
#' Generic entry point to the `filter_*()` family: pick the method with an
#' argument rather than by choosing a function. Useful when the method is
#' itself a parameter — comparing filters, or driving one from a config.
#'
#' @details
#' Returns the same shape it is given. A numeric vector gives a numeric
#' vector; a data frame of coordinate columns gives a data frame.
#'
#' Most methods are univariate and are applied one column at a time when
#' given a frame. `"ccma"` is multivariate — each output coordinate depends
#' on all of them — so it requires a frame and cannot be used with
#' [dplyr::across()].
#'
#' Method-specific arguments are passed through `...`, so a required one
#' still has to be supplied: `sampling_rate` for `"sgolay"`, `"lowpass"`,
#' `"highpass"`, the `_fft` variants and `"kalman"`; `times` for
#' `"kalman_irregular"`; `cutoff_freq` for the frequency filters.
#'
#' @param x A numeric vector, or a data frame of numeric coordinate columns.
#' @param method Filter to apply. One of `"gaussian"`, `"rollmean"`,
#'   `"rollmedian"`, `"triangular"`, `"sgolay"`, `"lowpass"`, `"highpass"`,
#'   `"lowpass_fft"`, `"highpass_fft"`, `"kalman"`, `"kalman_irregular"` or
#'   `"ccma"`.
#' @param ... Arguments passed to the underlying filter.
#'
#' @return The same shape as `x`, filtered.
#'
#' @examples
#' x <- c(1, 2, 3, 100, 5, 6, 7, 8, 9)
#'
#' filter_with(x, "gaussian", sigma = 1)
#' filter_with(x, "rollmean", window_width = 3)
#'
#' # A frame is filtered column by column
#' filter_with(data.frame(x = x, y = rev(x)), "rollmean", window_width = 3)
#'
#' @seealso [filter_across()] to apply a filter across an aniframe's
#'   spatial columns.
#' @export
filter_with <- function(
  x,
  method = c(
    "gaussian",
    "rollmean",
    "rollmedian",
    "triangular",
    "sgolay",
    "lowpass",
    "highpass",
    "lowpass_fft",
    "highpass_fft",
    "kalman",
    "kalman_irregular",
    "ccma"
  ),
  ...
) {
  method <- match.arg(method)

  fn <- switch(
    method,
    gaussian = filter_gaussian,
    rollmean = filter_rollmean,
    rollmedian = filter_rollmedian,
    triangular = filter_triangular,
    sgolay = filter_sgolay,
    lowpass = filter_lowpass,
    highpass = filter_highpass,
    lowpass_fft = filter_lowpass_fft,
    highpass_fft = filter_highpass_fft,
    kalman = filter_kalman,
    kalman_irregular = filter_kalman_irregular,
    ccma = filter_ccma
  )

  dispatch_method(
    x,
    method = method,
    fn = fn,
    multivariate = method == "ccma",
    generic = "filter_with",
    ...
  )
}
