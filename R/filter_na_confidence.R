#' Filter low-confidence values in a dataset
#'
#' This function replaces values in columns `x`, `y`, and optionally `z` with `NA`
#' if the confidence values are below a specified threshold. The `confidence`
#' column is also filtered.
#'
#' @param data A data frame containing the columns `x`, `y`, and `confidence`.
#' If a `z` column is present, it will also be filtered.
#' @param threshold A numeric value specifying the minimum confidence level to
#' retain data. Must be a single value between 0 and 1. Default is 0.6.
#'
#' @return A data frame with the same structure as the input, but where `x`, `y`,
#' `z` (if present), and `confidence` values are replaced with `NA` if the
#' confidence is below the threshold.
#'
#' @examples
#' # 2D example
#' data <- aniframe::aniframe(
#'   time = 1:5,
#'   x = 1:5,
#'   y = 6:10,
#'   confidence = c(0.5, 0.7, 0.4, 0.8, 0.9)
#' )
#'
#' filter_na_confidence(data, threshold = 0.6)
#'
#' # With z column (3D)
#' data_3d <- aniframe::aniframe(
#'   time = 1:5,
#'   x = 1:5,
#'   y = 6:10,
#'   z = 11:15,
#'   confidence = c(0.5, 0.7, 0.4, 0.8, 0.9)
#' )
#'
#' filter_na_confidence(data_3d, threshold = 0.6)
#'
#' @export
filter_na_confidence <- function(data, threshold = 0.6) {
  # Validate data is an aniframe
  aniframe::ensure_is_aniframe(data)

  # Validate required columns exist
  required_cols <- c("x", "y", "confidence")
  missing_cols <- setdiff(required_cols, names(data))
  if (length(missing_cols) > 0) {
    cli::cli_abort(c(
      "{.arg data} is missing required column{?s}: {.field {missing_cols}}",
      "i" = "Required columns are: {.field {required_cols}}"
    ))
  }

  # Validate threshold
  if (!is.numeric(threshold) || length(threshold) != 1 || is.na(threshold)) {
    cli::cli_abort("{.arg threshold} must be a single numeric value.")
  }

  if (threshold < 0 || threshold > 1) {
    cli::cli_abort("{.arg threshold} must be between 0 and 1.")
  }

  # Validate confidence column is numeric
  if (!is.numeric(data$confidence)) {
    cli::cli_abort("Column {.field confidence} must be numeric.")
  }

  # Check if z column exists
  has_z <- "z" %in% names(data)

  if (has_z) {
    data |>
      dplyr::mutate(
        x = dplyr::if_else(.data$confidence < threshold, NA, .data$x),
        y = dplyr::if_else(.data$confidence < threshold, NA, .data$y),
        z = dplyr::if_else(.data$confidence < threshold, NA, .data$z),
        confidence = filter_na_range(.data$confidence, min = threshold)
      )
  } else {
    data |>
      dplyr::mutate(
        x = dplyr::if_else(.data$confidence < threshold, NA, .data$x),
        y = dplyr::if_else(.data$confidence < threshold, NA, .data$y),
        confidence = filter_na_range(.data$confidence, min = threshold)
      )
  }
}
