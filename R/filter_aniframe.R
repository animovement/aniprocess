#' Smooth Movement Data
#'
#' @description
#' `r lifecycle::badge('experimental')`
#'
#' Applies smoothing filters to movement tracking data to reduce noise.
#'
#' @param data An aniframe. Spatial columns to filter are taken from the
#'   metadata field `variables_where` (e.g. `c("x", "y")` or `c("x", "y", "z")`).
#'   Filtering is applied within the aniframe's existing grouping, which is
#'   driven by `variables_what` (e.g. `c("individual", "keypoint")`, `"track"`,
#'   or `character(0)` for a single trajectory). Single-track data without an
#'   `individual` column is supported.
#' @param method Character string specifying the smoothing method. Options:
#'   - `"kalman"`: Kalman filter (see [filter_kalman()])
#'   - `"sgolay"`: Savitzky-Golay filter (see [filter_sgolay()])
#'   - `"lowpass"`: Low-pass filter (see [filter_lowpass()])
#'   - `"highpass"`: High-pass filter (see [filter_highpass()])
#'   - `"lowpass_fft"`: FFT-based low-pass filter (see [filter_lowpass_fft()])
#'   - `"highpass_fft"`: FFT-based high-pass filter (see [filter_highpass_fft()])
#'   - `"rollmean"`: Rolling mean filter (see [filter_rollmean()])
#'   - `"rollmedian"`: Rolling median filter (see [filter_rollmedian()])
#'   - `"triangular"`: Triangular filter (see [filter_triangular()])
#'   - `"gaussian"`: Gaussian kernel smoother (see [filter_gaussian()])
#' @param use_derivatives Filter on the derivative values instead of coordinates
#'   (important for e.g. trackball or accelerometer data)
#' @param ... Additional arguments passed to the specific filter function
#'
#' @details
#' This function is a wrapper that applies the chosen filter to every spatial
#' coordinate listed in `variables_where`, respecting the aniframe's existing
#' grouping. Each filtering method has its own specific parameters - see the
#' documentation of the individual filter functions for details:
#'
#' * [filter_kalman()]: Kalman filter parameters
#' * [filter_sgolay()]: Savitzky-Golay filter parameters
#' * [filter_lowpass()]: Low-pass filter parameters
#' * [filter_highpass()]: High-pass filter parameters
#' * [filter_lowpass_fft()]: FFT-based low-pass filter parameters
#' * [filter_highpass_fft()]: FFT-based high-pass filter parameters
#' * [filter_rollmean()]: Rolling mean parameters (window_width, min_obs)
#' * [filter_rollmedian()]: Rolling median parameters (window_width, min_obs)
#' * [filter_triangular()]: Triangular filter parameters (window_width, min_obs)
#' * [filter_gaussian()]: Gaussian kernel parameters (sigma, window_width)
#'
#' @return An aniframe with the same structure as the input, but with smoothed
#'   spatial coordinates.
#'
#' @examples
#' \dontrun{
#' # Apply rolling median with window of 5
#' filter_aniframe(tracking_data, "rollmedian", window_width = 5, min_obs = 1)
#' }
#'
#' @seealso
#' * [filter_kalman()]
#' * [filter_sgolay()]
#' * [filter_lowpass()]
#' * [filter_highpass()]
#' * [filter_lowpass_fft()]
#' * [filter_highpass_fft()]
#' * [filter_rollmean()]
#' * [filter_rollmedian()]
#' * [filter_triangular()]
#' * [filter_gaussian()]
#'
#' @export
filter_aniframe <- function(
  data,
  method = c(
    "rollmedian",
    "rollmean",
    "triangular",
    "gaussian",
    "kalman",
    "sgolay",
    "lowpass",
    "highpass",
    "lowpass_fft",
    "highpass_fft"
  ),
  use_derivatives = FALSE,
  ...
) {
  method <- match.arg(method)

  aniframe::ensure_is_aniframe(data)

  variables_where <- aniframe::get_metadata(data, "variables_where")

  missing_where <- setdiff(variables_where, names(data))
  if (length(missing_where) > 0) {
    cli::cli_abort(
      c(
        "Missing spatial column{?s}: {.val {missing_where}}.",
        "i" = "Spatial variables from metadata: {.val {variables_where}}."
      )
    )
  }

  filter_fn <- switch(
    method,
    rollmean = filter_rollmean,
    rollmedian = filter_rollmedian,
    triangular = filter_triangular,
    gaussian = filter_gaussian,
    kalman = filter_kalman,
    sgolay = filter_sgolay,
    lowpass = filter_lowpass,
    highpass = filter_highpass,
    lowpass_fft = filter_lowpass_fft,
    highpass_fft = filter_highpass_fft,
    cli::cli_abort("Invalid method: {method}")
  )

  # Materialise dots so per-column lambdas don't depend on tidyeval `...`
  extra_args <- rlang::list2(...)
  apply_filter <- function(col) do.call(filter_fn, c(list(col), extra_args))

  if (isFALSE(use_derivatives)) {
    dplyr::mutate(
      data,
      dplyr::across(dplyr::all_of(variables_where), apply_filter)
    )
  } else {
    # Shares derivative_wrapper() with filter_across(), so the two cannot
    # drift apart.
    integrate_filtered <- derivative_wrapper(apply_filter)
    dplyr::mutate(
      data,
      dplyr::across(dplyr::all_of(variables_where), integrate_filtered)
    )
  }
}
