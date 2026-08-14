#' Filter low-confidence values in a dataset
#'
#' This function replaces spatial coordinate values with `NA` if the confidence
#' values are below a specified threshold. The `confidence` column is also
#' filtered.
#'
#' @param data An aniframe containing a `confidence` column and spatial columns
#'   as defined in the metadata's `variables_where`, or a data frame of numeric
#'   coordinate columns.
#' @param threshold A numeric value specifying the minimum confidence level to
#'   retain data. Must be a single value between 0 and 1. Default is 0.6.
#' @param confidence Numeric vector of confidence values, one per row.
#'   Required when `data` is a coordinate frame. When `data` is an aniframe
#'   this defaults to its `confidence` column.
#'
#' @return The same shape as the input, with spatial values replaced by `NA`
#'   where confidence is below the threshold. For an aniframe the
#'   `confidence` column is filtered too.
#'
#' @details
#' A missing confidence means *not scored*, not *scored badly*, so those rows
#' are left unfiltered. A human annotator has no natural number to enter for
#' "I did not assess this", and tracker scores are not bounded at 1 — SLEAP
#' can exceed it — so `NA` is the sensible thing to record rather than a
#' sentinel value. A warning reports how many were missing, since silently
#' skipping them would hide that those rows were never checked. To drop them
#' as well, filter `confidence` directly with [filter_na_range()].
#'
#' @section Input shape:
#' Returns the same shape it is given.
#'
#' * Given an **aniframe**, the columns named by `variables_where` are masked,
#'   along with `confidence`.
#' * Given a **data frame of coordinate columns**, that frame is masked and
#'   returned — the form to use inside [dplyr::mutate()]:
#'
#' ```r
#' data |> mutate(
#'   filter_na_confidence(pick(all_of(c("x", "y"))), confidence = confidence)
#' )
#' ```
#'
#' `confidence` is not a coordinate, so it is only filtered by the aniframe
#' form; the coordinate-frame form returns just the masked coordinates.
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
filter_na_confidence <- function(data, threshold = 0.6, confidence = NULL) {
  is_frame <- aniframe::is_aniframe(data)

  if (is_frame) {
    ensure_aniframe_spatial(data)
    variables_where <- aniframe::get_metadata(data, "variables_where")

    if (is.null(confidence)) {
      if (!"confidence" %in% names(data)) {
        cli::cli_abort("Missing required column: {.val confidence}.")
      }
      confidence <- data$confidence
    }
  } else {
    ensure_coords(data)
    variables_where <- names(data)

    if (is.null(confidence)) {
      cli::cli_abort(c(
        "{.arg confidence} is required when {.arg data} is a coordinate frame.",
        "i" = "Inside {.fn dplyr::mutate}: {.code filter_na_confidence(pick(all_of(...)), confidence = confidence)}."
      ))
    }
  }

  # Validate threshold
  if (!is.numeric(threshold) || length(threshold) != 1 || is.na(threshold)) {
    cli::cli_abort("{.arg threshold} must be a single numeric value.")
  }

  if (threshold < 0 || threshold > 1) {
    cli::cli_abort("{.arg threshold} must be between 0 and 1.")
  }

  if (!is.numeric(confidence)) {
    cli::cli_abort("{.arg confidence} must be numeric.")
  }
  if (length(confidence) != nrow(data)) {
    cli::cli_abort(
      "{.arg confidence} must have one value per row ({nrow(data)}); got {length(confidence)}."
    )
  }

  # A missing confidence means "not scored", not "scored badly" -- a human
  # annotator has no natural numeric value to enter, and tracker scores are
  # not bounded at 1 (SLEAP can exceed it), so NA is the sensible thing to
  # record. Those rows are left alone, but flagged, since silently skipping
  # them would hide that they were never checked.
  n_missing <- sum(is.na(confidence))
  if (n_missing > 0L) {
    cli::cli_warn(
      c(
        "{n_missing} confidence value{?s} {?is/are} missing.",
        "i" = "Those rows are left unfiltered. Use {.fn filter_na_range} on {.field confidence} to drop them."
      ),
      .frequency = "regularly",
      .frequency_id = "aniprocess_confidence_na"
    )
  }

  # Replace spatial values with NA where confidence is below threshold
  below <- !is.na(confidence) & confidence < threshold
  for (col in variables_where) {
    data[[col]][below] <- NA_real_
  }

  # `confidence` is not a coordinate, so it can only be masked when the
  # input carries it — that is, for an aniframe.
  if (is_frame && "confidence" %in% names(data)) {
    data$confidence <- filter_na_range(data$confidence, min_value = threshold)
  }

  data
}
