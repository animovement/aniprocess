#' Filter low-confidence values in a dataset
#'
#' This function replaces spatial coordinate values with `NA` if the confidence
#' values are below a specified threshold. The `confidence` column is also
#' filtered.
#'
#' @param data A data frame of numeric coordinate columns — typically supplied
#'   by [dplyr::pick()] inside [dplyr::mutate()]. To filter a whole aniframe,
#'   use [filter_na_across()].
#' @param threshold A numeric value specifying the minimum confidence level to
#'   retain data. Must be a single value between 0 and 1. Default is 0.6.
#' @param confidence Numeric vector of confidence values, one per row.
#'
#' @return `data`, with coordinates replaced by `NA` where confidence is
#'   below the threshold.
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
#' Takes and returns a frame of coordinate columns, so it composes inside
#' [dplyr::mutate()]:
#'
#' ```r
#' data |> mutate(
#'   filter_na_confidence(pick(all_of(c("x", "y"))), confidence = confidence)
#' )
#' ```
#'
#' The decision uses all coordinates at once, so this cannot be used with
#' [dplyr::across()]. `confidence` is not a coordinate and so is never
#' modified here; [filter_na_across()] filters it as well.
#'
#' @examples
#' coords <- data.frame(x = 1:5, y = 6:10)
#' filter_na_confidence(
#'   coords,
#'   threshold = 0.6,
#'   confidence = c(0.5, 0.7, 0.4, 0.8, 0.9)
#' )
#'
#' @export
filter_na_confidence <- function(data, threshold = 0.6, confidence = NULL) {
  ensure_coords(data)
  variables_where <- names(data)

  if (is.null(confidence)) {
    cli::cli_abort(c(
      "{.arg confidence} is required.",
      "i" = "Inside {.fn dplyr::mutate}: {.code filter_na_confidence(pick(all_of(...)), confidence = confidence)}.",
      "i" = "For a whole aniframe, use {.fn filter_na_across}."
    ))
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

  data
}
