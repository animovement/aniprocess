#' Filter values by speed threshold
#'
#' @description
#' Filters out single-frame outliers based on movement speed. Spatial
#' coordinates and confidence values at flagged rows are replaced with NA.
#'
#' @param data An aniframe containing spatial coordinates and a time column.
#' @param threshold A numeric value specifying the speed threshold, or "auto".
#'   - If numeric: Rows whose speed exceeds this value have their spatial and
#'     confidence values replaced with NA.
#'   - If "auto": Sets threshold at mean speed + 3 standard deviations.
#'
#' @return An aniframe with the same structure as the input, but with spatial
#'   and confidence values replaced by NA where speed exceeds the threshold.
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
#' Speed is computed **within each group** of a grouped aniframe, so a step
#' is never formed between the last row of one track and the first row of
#' the next. Each group's first and last rows are treated as endpoints. On
#' ungrouped data the whole frame is a single track.
#'
#' When using `threshold = "auto"`, the threshold is set to the mean speed
#' plus three standard deviations, pooled across groups. Because no
#' cross-track step is ever formed, the estimate uses within-track speeds
#' only.
#'
#' @examples
#' data <- aniframe::aniframe(
#'   time = 1:5,
#'   x = c(1, 2, 4, 7, 11),
#'   y = c(1, 1, 2, 3, 5),
#'   confidence = c(0.8, 0.9, 0.7, 0.85, 0.6)
#' )
#'
#' # Filter data by a speed threshold of 3
#' filter_na_speed(data, threshold = 3)
#'
#' # Use automatic threshold
#' filter_na_speed(data, threshold = "auto")
#'
#' @export
filter_na_speed <- function(data, threshold = "auto") {
  ensure_aniframe_spatial(data)
  variables_where <- aniframe::get_metadata(data, "variables_where")

  if (!"time" %in% names(data)) {
    cli::cli_abort("Missing required column: {.val time}.")
  }
  if (!is.numeric(data$time)) {
    cli::cli_abort("Column {.val time} must be numeric.")
  }

  # Check threshold input
  if (!identical(threshold, "auto") && !is.numeric(threshold)) {
    cli::cli_abort(
      "{.arg threshold} must be either {.val auto} or a numeric value."
    )
  }

  if (is.numeric(threshold) && (length(threshold) != 1 || is.na(threshold))) {
    cli::cli_abort("{.arg threshold} must be a single numeric value.")
  }

  # Speed is computed inside mutate() so that grouping is respected: a step
  # is never formed between the last row of one track and the first row of
  # the next. Works unchanged on ungrouped data, which is simply one group.
  speed <- dplyr::mutate(
    data,
    .aniprocess_speed = calculate_step_speed(
      dplyr::pick(dplyr::all_of(variables_where)),
      .data$time
    )
  )$.aniprocess_speed

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

  # Filter confidence if present
  if ("confidence" %in% names(data)) {
    data$confidence <- dplyr::if_else(exceeds, NA_real_, data$confidence)
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
