#' Filter values by speed threshold
#'
#' @description
#' Filters out single-frame outliers based on movement speed. Spatial
#' coordinates and confidence values at flagged rows are replaced with NA.
#'
#' @param data A data frame of numeric coordinate columns — typically supplied
#'   by [dplyr::pick()] inside [dplyr::mutate()]. To filter a whole aniframe,
#'   use [filter_na_across()].
#' @param time Numeric vector of time values, one per row.
#' @param threshold A numeric value specifying the speed threshold, or "auto".
#'   - If numeric: Rows whose speed exceeds this value have their spatial and
#'     confidence values replaced with NA.
#'   - If "auto": Sets threshold at mean speed + 3 standard deviations.
#'
#' @return `data`, with coordinates replaced by `NA` where speed exceeds the
#'   threshold.
#'
#' @section Input shape:
#' Takes and returns a frame of coordinate columns, so it composes inside
#' [dplyr::mutate()]:
#'
#' ```r
#' data |> mutate(filter_na_speed(pick(all_of(c("x", "y"))), time = time))
#' ```
#'
#' Speed depends on all coordinates jointly, so this cannot be used with
#' [dplyr::across()]. `confidence` is not a coordinate and so is never
#' modified here; [filter_na_across()] blanks it on masked rows.
#'
#' @details
#' For each row, two step speeds are computed: the backward step (from the
#' previous row to this one) and the forward step (from this row to the next),
#' each as the magnitude of the position change divided by the time step.
#' The row's speed is the **minimum** of the two — so a row is only flagged
#' when both the step in *and* the step out are fast. This isolates
#' single-frame outliers (a position that jumps away and comes back) from
#' legitimate state changes (a sustained move to a new region), which only
#' have one fast step.
#'
#' Endpoints have only one neighbor; their speed falls back to the available
#' one-sided step. NAs in inputs do not contaminate adjacent rows: a missing
#' coordinate at row `i` only affects row `i`'s speed estimate.
#'
#' Every row of `data` is treated as one continuous track: a step is formed
#' between each consecutive pair. Called via [filter_na_across()] or with
#' [dplyr::pick()] inside a grouped [dplyr::mutate()], that means one group,
#' so a step is never formed across a track boundary.
#'
#' When using `threshold = "auto"`, the threshold is the mean speed plus
#' three standard deviations of the rows given. Called through
#' [filter_na_across()] that means one threshold per group; pass
#' `threshold = "pooled"` there to estimate a single threshold from every
#' group at once instead.
#'
#' @examples
#' coords <- data.frame(x = c(1, 2, 4, 7, 11), y = c(1, 1, 2, 3, 5))
#'
#' filter_na_speed(coords, threshold = 3, time = 1:5)
#' filter_na_speed(coords, threshold = "auto", time = 1:5)
#'
#' @export
filter_na_speed <- function(data, threshold = "auto", time = NULL) {
  ensure_coords(data, across = "filter_na_across")
  variables_where <- names(data)

  if (is.null(time)) {
    cli::cli_abort(c(
      "{.arg time} is required.",
      "i" = "Inside {.fn dplyr::mutate}: {.code filter_na_speed(pick(all_of(...)), time = time)}.",
      "i" = "For a whole aniframe, use {.fn filter_na_across}."
    ))
  }

  if (!is.numeric(time)) {
    cli::cli_abort("{.arg time} must be numeric.")
  }
  if (length(time) != nrow(data)) {
    cli::cli_abort(
      "{.arg time} must have one value per row ({nrow(data)}); got {length(time)}."
    )
  }

  # Check threshold input
  if (identical(threshold, "pooled")) {
    cli::cli_abort(c(
      "{.arg threshold} cannot be {.val pooled} here.",
      "i" = "Pooling estimates one threshold across groups, and this function sees only the rows it was given.",
      "i" = "Use {.fn filter_na_across} for a whole aniframe."
    ))
  }
  if (!identical(threshold, "auto") && !is.numeric(threshold)) {
    cli::cli_abort(
      "{.arg threshold} must be either {.val auto} or a numeric value."
    )
  }

  if (is.numeric(threshold) && (length(threshold) != 1 || is.na(threshold))) {
    cli::cli_abort("{.arg threshold} must be a single numeric value.")
  }

  # The caller has already decided which rows belong together.
  speed <- calculate_step_speed(data, time)

  # Determine threshold if auto. Estimated from within-track speeds only,
  # since no cross-track step ever enters `speed`.
  if (identical(threshold, "auto")) {
    threshold <- mean(speed, na.rm = TRUE) + 3 * stats::sd(speed, na.rm = TRUE)
  }

  # Create mask for exceeding threshold. Groups shorter than two rows have
  # no step and so no speed; `is.na()` guards them, because `if_else()`
  # propagates a missing condition and would blank those rows.
  exceeds <- !is.na(speed) & speed > threshold

  # Filter spatial variables
  for (col in variables_where) {
    data[[col]] <- dplyr::if_else(exceeds, NA_real_, data[[col]])
  }

  data
}


#' Calculate per-row outlier speed from position and time
#'
#' Returns the minimum of the backward and forward step speeds at each row.
#' Endpoints fall back to the one available side; if either side is NA, the
#' other is used (`pmin` with `na.rm = TRUE`).
#'
#' Dimension-agnostic: the Euclidean step is summed over whatever columns
#' `coords` holds, so the same function serves 1D, 2D and 3D data. Intended
#' to be called inside `dplyr::mutate()` with `dplyr::pick()`, which supplies
#' one group's coordinates at a time.
#'
#' @param coords A data frame of numeric coordinate columns.
#' @param time Numeric vector of time values, same length as `nrow(coords)`.
#'
#' @return Numeric vector of speed values, of length `nrow(coords)`.
#' @keywords internal
calculate_step_speed <- function(coords, time) {
  n <- nrow(coords)
  if (n < 2L) {
    return(rep(NA_real_, n))
  }
  squared <- 0
  for (axis in coords) {
    squared <- squared + diff(axis)^2
  }
  step_speed <- sqrt(squared) / diff(time)
  back <- c(NA_real_, step_speed)
  fwd <- c(step_speed, NA_real_)
  pmin(back, fwd, na.rm = TRUE)
}
