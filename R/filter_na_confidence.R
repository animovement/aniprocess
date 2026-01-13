#' Filter low-confidence values in a dataset
#'
#' This function replaces spatial coordinate values with `NA` if the confidence
#' values are below a specified threshold. The `confidence` column is also
#' filtered.
#'
#' @param data An aniframe containing a `confidence` column and spatial columns
#'   as defined in the metadata's `variables_where`.
#' @param threshold A numeric value specifying the minimum confidence level to
#'   retain data. Must be a single value between 0 and 1. Default is 0.6.
#'
#' @return An aniframe with the same structure as the input, but where spatial
#'   and `confidence` values are replaced with `NA` if the confidence is below
#'   the threshold.
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
#'   confidence = c(0.5, 0.7, 0.4, 0.8, 0.9),
#'   variables_where = c("x", "y", "z")
#' )
#'
#' filter_na_confidence(data_3d, threshold = 0.6)
#'
#' @export
filter_na_confidence <- function(data, threshold = 0.6) {
  aniframe::ensure_is_aniframe(data)

  # Get spatial variables from metadata
  variables_where <- aniframe::get_metadata(data, "variables_where")

  # Validate required columns exist
  required_cols <- c(variables_where, "confidence")
  missing_cols <- setdiff(required_cols, names(data))
  if (length(missing_cols) > 0) {
    cli::cli_abort(
      c(
        "{.arg data} is missing required column{?s}: {.val {missing_cols}}.",
        "i" = "Spatial variables from metadata: {.val {variables_where}}."
      )
    )
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
    cli::cli_abort("Column {.val confidence} must be numeric.")
  }

  # Replace spatial values with NA where confidence is below threshold
  for (col in variables_where) {
    data <- data |>
      dplyr::mutate(
        !!col := dplyr::if_else(.data$confidence < threshold, NA, .data[[col]])
      )
  }

  # Filter confidence column
  data |>
    dplyr::mutate(
      confidence = filter_na_range(.data$confidence, min = threshold)
    )
}
