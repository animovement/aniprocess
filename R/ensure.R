#' Validate the common arguments shared by `replace_na_*()` functions.
#'
#' Aborts on a non-numeric `x`, `min_gap < 1`, or `max_gap < min_gap`.
#' Used at the start of every `replace_na_*()` function so the same
#' messages and behaviour apply consistently when those functions are
#' called directly (rather than via [replace_na()]).
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
