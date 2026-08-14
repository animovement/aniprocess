#' Apply Curvature-Corrected Moving Average (CCMA)
#'
#' @description
#' `r lifecycle::badge('experimental')`
#'
#' Smooths a trajectory while undoing the inward "corner-cutting" bias that
#' a plain moving average introduces on curved paths.
#'
#' @details
#' A plain moving average pulls each point toward the chord between its
#' neighbours, which lies *inside* the curve — so smoothed circles shrink
#' inward. CCMA (Steinecker & Wuensche, 2023) estimates how much shrinkage
#' the moving average caused at each point — from the local curvature and
#' the kernel — and pushes the result back outward by exactly that amount.
#'
#' The algorithm has two stages:
#' 1. **Moving average** of the spatial coordinates with a kernel of width
#'    `window_width_ma`.
#' 2. **Curvature correction**: at each output position, sum a kernel of
#'    width `window_width_cc` of curvature-derived shifts and apply them
#'    outward in the curve's plane.
#'
#' Because curvature is intrinsically multi-dimensional, this filter
#' operates on all spatial coordinates jointly (unlike the per-column
#' filters dispatched through [filter_across()]). It is most useful
#' for smoothing curved 2D or 3D trajectories where a plain moving
#' average visibly cuts corners; for general-purpose time-series
#' smoothing reach for [filter_gaussian()] or [filter_sgolay()].
#'
#' Smoothing is applied within the aniframe's existing grouping (driven
#' by `variables_what`), so each individual / track / keypoint is
#' smoothed as its own trajectory.
#'
#' @section Input shape:
#' Returns the same shape it is given.
#'
#' * Given an **aniframe**, the spatial columns named by `variables_where`
#'   are smoothed and an aniframe is returned.
#' * Given a **data frame of coordinate columns**, that frame is smoothed
#'   and returned. This is the form to use inside [dplyr::mutate()], where
#'   [dplyr::pick()] supplies the columns and the result is spliced back
#'   over them:
#'
#' ```r
#' data |> mutate(filter_ccma(pick(all_of(c("x", "y")))))
#' ```
#'
#' CCMA is multivariate — each output coordinate depends on all of them —
#' so it cannot be used with [dplyr::across()], which passes one column at
#' a time.
#'
#' @param data An aniframe in Cartesian coordinates with 2 or 3 spatial
#'   columns (set via the `variables_where` metadata field), or a data
#'   frame of 2 or 3 numeric coordinate columns. The curvature math is
#'   Cartesian-specific (cross products, Euclidean norms, circumradius),
#'   so polar / cylindrical / spherical aniframes are rejected.
#' @param window_width_ma Integer width of the moving-average kernel
#'   (must be odd; even values are rounded up). Larger = more smoothing.
#'   Default `11`.
#' @param window_width_cc Integer width of the curvature-correction
#'   kernel (must be odd). Larger = smoother correction but uses
#'   curvature info from further away. Default `7`.
#' @param kernel Kernel shape for both stages. One of `"hanning"`
#'   (default; raised cosine) or `"uniform"` (boxcar).
#' @param boundary Edge-handling strategy. Currently only `"padding"`
#'   (repeat the first and last point so output length equals input
#'   length).
#' @param cc_mode If `FALSE`, returns just the moving-average result
#'   without curvature correction. Useful for comparison.
#' @inheritParams filter-na-args
#' @param ... Additional arguments passed to [replace_na_with()] (e.g.
#'   `value`, `min_gap`, `max_gap`).
#'
#' @return An aniframe of the same shape as the input, with the
#'   spatial columns smoothed.
#'
#' @references
#' Steinecker, T. & Wuensche, H.-J. (2023). A Simple and Model-Free
#' Path Filtering Algorithm for Smoothing and Accuracy. *2023 IEEE
#' Intelligent Vehicles Symposium (IV)*.
#'
#' Reference Python implementation:
#' <https://github.com/UniBwTAS/ccma>
#'
#' @examples
#' \dontrun{
#' filter_ccma(tracking_data, window_width_ma = 11, window_width_cc = 7)
#' }
#'
#' @export
filter_ccma <- function(
  data,
  window_width_ma = 11,
  window_width_cc = 7,
  kernel = c("hanning", "uniform"),
  boundary = c("padding"),
  cc_mode = TRUE,
  na_action = c("linear", "spline", "stine", "locf", "value", "error"),
  keep_na = TRUE,
  ...
) {
  ensure_coords(data)

  d <- ncol(data)
  if (!d %in% c(2L, 3L)) {
    cli::cli_abort(c(
      "CCMA requires 2 or 3 coordinate columns; got {.val {d}}.",
      "i" = "The curvature math is defined in 2D and 3D only."
    ))
  }

  window_width_ma <- ccma_validate_window("window_width_ma", window_width_ma)
  window_width_cc <- ccma_validate_window("window_width_cc", window_width_cc)
  w_ma <- (window_width_ma - 1L) %/% 2L
  w_cc <- (window_width_cc - 1L) %/% 2L

  kernel <- match.arg(kernel)
  boundary <- match.arg(boundary)
  na_action <- match.arg(na_action)
  ensure_keep_na(keep_na)

  extra_args <- rlang::list2(...)

  smooth <- function(coords) {
    ccma_filter_group(
      coords,
      w_ma = w_ma,
      w_cc = w_cc,
      kernel = kernel,
      boundary = boundary,
      cc_mode = cc_mode,
      na_action = na_action,
      keep_na = keep_na,
      replace_na_args = extra_args
    )
  }

  smooth(data)
}


#' Apply CCMA to one group's coordinates.
#'
#' Matrix-in, matrix-out adaptor around [ccma_filter_one()] that takes and
#' returns a data frame, so the result can be spliced back over the spatial
#' columns by `dplyr::mutate()`.
#'
#' @param coords A data frame of the group's spatial columns.
#' @inheritParams ccma_filter_one
#'
#' @return A data frame with the same names and shape as `coords`.
#' @keywords internal
ccma_filter_group <- function(coords, ...) {
  smoothed <- ccma_filter_one(as.matrix(coords), ...)
  out <- as.data.frame(smoothed)
  names(out) <- names(coords)
  out
}


#' Validate a CCMA window-width argument.
#'
#' Ensures the value is a single positive integer; rounds even values up
#' to the next odd integer. Mirrors the convention used by
#' [filter_gaussian()].
#'
#' @keywords internal
ccma_validate_window <- function(arg_name, value) {
  if (!is.numeric(value) || length(value) != 1L || value < 1L) {
    cli::cli_abort(
      "{.arg {arg_name}} must be a single positive integer."
    )
  }
  value <- as.integer(value)
  if (value %% 2L == 0L) {
    value <- value + 1L
  }
  value
}


#' Apply CCMA to one trajectory, with NA pre-handling.
#'
#' Wraps [ccma_apply()] with `replace_na`-based interpolation of `NA`s
#' before filtering and optional restoration after.
#'
#' @keywords internal
ccma_filter_one <- function(
  P,
  w_ma,
  w_cc,
  kernel,
  boundary,
  cc_mode,
  na_action,
  keep_na,
  replace_na_args
) {
  prepared <- prepare_na(P, na_action, replace_na_args)
  P <- prepared$x

  if (anyNA(P)) {
    # Some NAs couldn't be filled (e.g. all-NA column). Return as-is.
    return(P)
  }

  out <- ccma_apply(
    P,
    w_ma = w_ma,
    w_cc = w_cc,
    kernel = kernel,
    boundary = boundary,
    cc_mode = cc_mode
  )

  restore_na(out, prepared$na_positions, keep_na)
}
