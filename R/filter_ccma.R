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
#' filters dispatched through [filter_aniframe()]). It is most useful
#' for smoothing curved 2D or 3D trajectories where a plain moving
#' average visibly cuts corners; for general-purpose time-series
#' smoothing reach for [filter_gaussian()] or [filter_sgolay()].
#'
#' Smoothing is applied within the aniframe's existing grouping (driven
#' by `variables_what`), so each individual / track / keypoint is
#' smoothed as its own trajectory.
#'
#' @param data An aniframe in Cartesian coordinates with 2 or 3 spatial
#'   columns (set via the `variables_where` metadata field). The
#'   curvature math is Cartesian-specific (cross products, Euclidean
#'   norms, circumradius), so polar / cylindrical / spherical aniframes
#'   are rejected.
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
#' @param na_action How to fill `NA` values in the spatial columns
#'   before filtering. One of `"linear"` (default), `"spline"`,
#'   `"stine"`, `"locf"`, `"value"`, or `"error"` (abort if any `NA`s
#'   are present). See [replace_na()].
#' @param keep_na If `TRUE`, restore `NA`s at their original positions
#'   in the output. Defaults to `FALSE`.
#' @param ... Additional arguments passed to [replace_na()] (e.g.
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
  keep_na = FALSE,
  ...
) {
  ensure_aniframe_spatial(data)

  coord_system <- as.character(
    aniframe::get_metadata(data, "coordinate_system")
  )
  if (!startsWith(coord_system, "cartesian")) {
    cli::cli_abort(
      c(
        "CCMA requires a Cartesian coordinate system; got {.val {coord_system}}.",
        "i" = "The curvature math (cross product, Euclidean norm, circumradius) is Cartesian-specific."
      )
    )
  }

  variables_where <- aniframe::get_metadata(data, "variables_where")
  d <- length(variables_where)
  if (!d %in% c(2L, 3L)) {
    cli::cli_abort(
      "CCMA requires 2 or 3 spatial coordinates; got {.val {d}} from {.field variables_where}."
    )
  }

  window_width_ma <- ccma_validate_window("window_width_ma", window_width_ma)
  window_width_cc <- ccma_validate_window("window_width_cc", window_width_cc)
  w_ma <- (window_width_ma - 1L) %/% 2L
  w_cc <- (window_width_cc - 1L) %/% 2L

  kernel <- match.arg(kernel)
  boundary <- match.arg(boundary)
  na_action <- match.arg(na_action)

  extra_args <- rlang::list2(...)

  # Apply per group.
  if (inherits(data, "grouped_df") && length(dplyr::group_vars(data)) > 0L) {
    group_id <- dplyr::group_indices(data)
  } else {
    group_id <- rep(1L, nrow(data))
  }

  for (g in unique(group_id)) {
    mask <- which(group_id == g)
    P <- as.matrix(as.data.frame(data)[mask, variables_where, drop = FALSE])
    smoothed <- ccma_filter_one(
      P,
      w_ma = w_ma,
      w_cc = w_cc,
      kernel = kernel,
      boundary = boundary,
      cc_mode = cc_mode,
      na_action = na_action,
      keep_na = keep_na,
      replace_na_args = extra_args
    )
    for (i in seq_along(variables_where)) {
      data[[variables_where[i]]][mask] <- smoothed[, i]
    }
  }

  data
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
  d <- ncol(P)
  na_positions <- if (keep_na) {
    lapply(seq_len(d), function(i) which(is.na(P[, i])))
  } else {
    NULL
  }

  has_any_na <- anyNA(P)
  if (na_action == "error" && has_any_na) {
    cli::cli_abort("Spatial coordinates contain {.val NA} values.")
  }
  if (has_any_na && na_action != "error") {
    for (i in seq_len(d)) {
      if (anyNA(P[, i])) {
        P[, i] <- do.call(
          replace_na,
          c(list(P[, i], method = na_action), replace_na_args)
        )
      }
    }
  }

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

  if (keep_na) {
    for (i in seq_len(d)) {
      out[na_positions[[i]], i] <- NA_real_
    }
  }
  out
}
