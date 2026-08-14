#' Validate the common arguments shared by `replace_na_*()` functions.
#'
#' Aborts on a non-numeric `x`, `min_gap < 1`, or `max_gap < min_gap`.
#' Used at the start of every `replace_na_*()` function so the same
#' messages and behaviour apply consistently when those functions are
#' called directly (rather than via [replace_na_with()]).
#'
#' @param x The numeric input to validate.
#' @param min_gap,max_gap Gap-size thresholds.
#'
#' @return Invisibly `NULL`. Called for side effects (errors).
#' @keywords internal
ensure_replace_na_args <- function(x, min_gap, max_gap) {
  if (!is.numeric(x)) {
    cli::cli_abort("Input must be numeric")
  }
  if (min_gap < 1) {
    cli::cli_abort("min_gap must be >= 1")
  }
  if (max_gap < min_gap) {
    cli::cli_abort("max_gap must be >= min_gap")
  }
  invisible(NULL)
}

#' Validate a coordinate frame.
#'
#' The vector-level form of the aniframe-aware filters accepts a data frame
#' of coordinate columns — typically supplied by [dplyr::pick()] inside
#' [dplyr::mutate()]. This checks that it is a data frame with at least one
#' column and that every column is numeric.
#'
#' @param coords The value to validate.
#' @param arg Argument name to use in error messages.
#' @param call Environment used for the error's call context.
#'
#' @return Invisibly `NULL`. Called for side effects (errors).
#' @keywords internal
ensure_coords <- function(coords, arg = "data", call = rlang::caller_env()) {
  if (!is.data.frame(coords)) {
    cli::cli_abort(
      c(
        "{.arg {arg}} must be an aniframe or a data frame of coordinates.",
        "i" = "Inside {.fn dplyr::mutate}, use {.code pick(all_of(...))}."
      ),
      call = call
    )
  }
  if (ncol(coords) == 0L) {
    cli::cli_abort("{.arg {arg}} has no columns.", call = call)
  }
  non_numeric <- names(coords)[!vapply(coords, is.numeric, logical(1))]
  if (length(non_numeric) > 0L) {
    cli::cli_abort(
      "Coordinate column{?s} {.val {non_numeric}} must be numeric.",
      call = call
    )
  }
  invisible(NULL)
}
