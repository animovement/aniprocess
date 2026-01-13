#' Filter values by speed threshold
#'
#' @description
#' Filters out observations where the calculated speed exceeds a specified
#' threshold. Spatial coordinates and confidence values are replaced with NA
#' where speed is too high. Speed is calculated using numerical differentiation
#' of position over time.
#'
#' @param data An aniframe containing spatial coordinates and a time column.
#' @param threshold A numeric value specifying the speed threshold, or "auto".
#'   - If numeric: Observations with speeds greater than this value will have
#'     their spatial and confidence values replaced with NA.
#'   - If "auto": Sets threshold at mean speed + 3 standard deviations.
#'
#' @return An aniframe with the same structure as the input, but with spatial
#'   and confidence values replaced by NA where speed exceeds the threshold.
#'
#' @details
#' Speed is calculated as the magnitude of the velocity vector, computed using
#' numerical differentiation via the `differentiate` function. For 2D data,
#' speed = sqrt(v_x^2 + v_y^2). For 3D data, speed = sqrt(v_x^2 + v_y^2 + v_z^2).
#'
#' When using `threshold = "auto"`, the function calculates the threshold as
#' the mean speed plus three standard deviations, which assumes approximately
#' normally distributed speeds.
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
  aniframe::ensure_is_aniframe(data)

  # Get spatial variables from metadata
  variables_where <- aniframe::get_metadata(data, "variables_where")

  # Validate required columns exist
  required_cols <- c("time", variables_where)
  missing_cols <- setdiff(required_cols, names(data))
  if (length(missing_cols) > 0) {
    cli::cli_abort(
      c(
        "Missing required column{?s}: {.val {missing_cols}}.",
        "i" = "Spatial variables from metadata: {.val {variables_where}}."
      )
    )
  }

  # Check that time and spatial columns are numeric
  check_cols <- c("time", variables_where)
  for (col in check_cols) {
    if (!is.numeric(data[[col]])) {
      cli::cli_abort("Column {.val {col}} must be numeric.")
    }
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

  # Calculate speed based on dimensionality
  has_z <- "z" %in% variables_where

  if (has_z) {
    speed <- calculate_speed_3d(data$x, data$y, data$z, data$time)
  } else {
    speed <- calculate_speed_2d(data$x, data$y, data$time)
  }

  # Determine threshold if auto
  if (identical(threshold, "auto")) {
    threshold <- mean(speed, na.rm = TRUE) + 3 * stats::sd(speed, na.rm = TRUE)
  }

  # Create mask for exceeding threshold
  exceeds <- abs(speed) > threshold

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


#' Calculate speed from 2D position and time
#'
#' @param x Numeric vector of x coordinates.
#' @param y Numeric vector of y coordinates.
#' @param time Numeric vector of time values.
#'
#' @return Numeric vector of speed values.
#' @keywords internal
calculate_speed_2d <- function(x, y, time) {
  check_animetric()
  v_x <- animetric::differentiate(x, time, order = 1)
  v_y <- animetric::differentiate(y, time, order = 1)
  sqrt(v_x^2 + v_y^2)
}


#' Calculate speed from 3D position and time
#'
#' @param x Numeric vector of x coordinates.
#' @param y Numeric vector of y coordinates.
#' @param z Numeric vector of z coordinates.
#' @param time Numeric vector of time values.
#'
#' @return Numeric vector of speed values.
#' @keywords internal
calculate_speed_3d <- function(x, y, z, time) {
  check_animetric()
  v_x <- animetric::differentiate(x, time, order = 1)
  v_y <- animetric::differentiate(y, time, order = 1)
  v_z <- animetric::differentiate(z, time, order = 1)
  sqrt(v_x^2 + v_y^2 + v_z^2)
}
