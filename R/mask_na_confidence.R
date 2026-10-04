#' Mask low-confidence values to NA
#'
#' This function replaces spatial coordinate values with `NA` if the confidence
#' values are below a specified threshold. The `confidence` column is also
#' masked.
#'
#' @param data A data frame of numeric coordinate columns — typically supplied
#'   by [dplyr::pick()] inside [dplyr::mutate()]. To mask a whole aniframe,
#'   use [mask_na_across()].
#' @param threshold A numeric value specifying the minimum confidence level to
#'   retain data. Must be a single value between 0 and 1. Default is 0.6.
#' @param confidence Numeric vector of confidence values, one per row.
#' @param missing What to do with rows whose confidence is `NA`. `"keep"`
#'   (the default) leaves them unmasked; `"mask"` treats a missing score as
#'   failing the threshold, so they are masked like any low-confidence row.
#'
#' @return `data`, with coordinates replaced by `NA` where confidence is
#'   below the threshold.
#'
#' @details
#' A missing confidence means *not assessed*, not *assessed as poor*, so by
#' default those rows are left unmasked. A human annotator has no natural
#' number to enter for "I did not assess this", and tracker scores are not
#' bounded at 1 — SLEAP can exceed it — so `NA` is the sensible thing to
#' record rather than a sentinel value. Set `missing = "mask"` when you would
#' rather drop what was never assessed.
#'
#' When `missing` is left at its default, a warning reports how many rows
#' were left unmasked without a score, since silently skipping them would hide that
#' they were never checked. Rows whose coordinates are already all `NA` are
#' not counted: masking could not change them. Supplying `missing`, either
#' value, says you have decided, and silences the warning.
#'
#' @section Input shape:
#' Takes and returns a frame of coordinate columns, so it composes inside
#' [dplyr::mutate()]:
#'
#' ```r
#' data |> mutate(
#'   mask_na_confidence(pick(all_of(c("x", "y"))), confidence = confidence)
#' )
#' ```
#'
#' The decision uses all coordinates at once, so this cannot be used with
#' [dplyr::across()]. `confidence` is not a coordinate and so is never
#' modified here; [mask_na_across()] masks it as well.
#'
#' @examples
#' coords <- data.frame(x = 1:5, y = 6:10)
#' mask_na_confidence(
#'   coords,
#'   threshold = 0.6,
#'   confidence = c(0.5, 0.7, 0.4, 0.8, 0.9)
#' )
#'
#' # Row 3 was never scored: kept by default, masked on request
#' scores <- c(0.5, 0.7, NA, 0.8, 0.9)
#' mask_na_confidence(coords, confidence = scores, missing = "keep")
#' mask_na_confidence(coords, confidence = scores, missing = "mask")
#'
#' @export
mask_na_confidence <- function(
  data,
  threshold = 0.6,
  confidence = NULL,
  missing = c("keep", "mask")
) {
  # `missing` shadows base::missing() here, so call it by its full name.
  warn_unscored <- base::missing(missing)
  missing <- rlang::arg_match(missing)
  ensure_coords(data, across = "mask_na_across")
  variables_where <- names(data)

  if (is.null(confidence)) {
    cli::cli_abort(c(
      "{.arg confidence} is required.",
      "i" = "Inside {.fn dplyr::mutate}: {.code mask_na_confidence(pick(all_of(...)), confidence = confidence)}.",
      "i" = "For a whole aniframe, use {.fn mask_na_across}."
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

  # A missing confidence means "not assessed", not "assessed as poor" -- a
  # human annotator has no natural numeric value to enter, and tracker scores
  # are not bounded at 1 (SLEAP can exceed it), so NA is the sensible thing to
  # record. By default those rows are kept, but flagged unless the caller
  # chose, since silently skipping them would hide that they were never
  # checked.
  unscored <- is.na(confidence)
  if (warn_unscored) {
    warn_unscored_confidence(count_unscored(data, confidence))
  }

  # Replace spatial values with NA where confidence is below threshold
  below <- !unscored & confidence < threshold
  if (missing == "mask") {
    below <- below | unscored
  }
  for (col in variables_where) {
    data[[col]][below] <- NA_real_
  }

  data
}


#' Count the unscored rows that masking could still change.
#'
#' A row with no confidence score only matters if it has a coordinate left
#' to mask; one whose coordinates are already all `NA` is the same either
#' way.
#'
#' @param data A data frame holding the coordinate columns.
#' @param confidence Numeric vector of confidence values, one per row.
#' @param variables Names of the coordinate columns in `data`.
#'
#' @return A single integer.
#' @keywords internal
count_unscored <- function(data, confidence, variables = names(data)) {
  has_position <- Reduce(
    `|`,
    lapply(variables, function(v) !is.na(data[[v]])),
    logical(length(confidence))
  )
  sum(is.na(confidence) & has_position)
}


#' Warn that rows without a confidence score were left unmasked.
#'
#' Raised once per call: by [mask_na_confidence()] when called on its own,
#' and by [mask_na_across()] for the whole frame, which keeps it from being
#' repeated per group and wrapped in [dplyr::mutate()]'s context.
#'
#' @param n Number of unscored rows that were left unmasked.
#'
#' @return Invisibly `NULL`. Called for its side effect.
#' @keywords internal
warn_unscored_confidence <- function(n) {
  if (n == 0L) {
    return(invisible(NULL))
  }
  cli::cli_warn(
    c(
      "{n} row{?s} {?has/have} no confidence score and {?was/were} left unmasked.",
      "i" = "{cli::qty(n)}Set {.code missing = \"mask\"} to mask {?it/them}, or {.code missing = \"keep\"} to keep {?it/them} without this warning."
    ),
    class = "aniprocess_warning_unscored_confidence"
  )
  invisible(NULL)
}
