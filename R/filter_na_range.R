#' Filter values outside a range to NA
#'
#' Replaces values in a numeric vector that fall outside the specified range
#' with NA. Values already NA in the input remain NA.
#'
#' @param x A numeric vector to filter
#' @param min Minimum value (inclusive). Values below this become NA.
#'   Default is -Inf (no lower bound).
#' @param max Maximum value (inclusive). Values above this become NA.
#'   Default is Inf (no upper bound).
#'
#' @return A numeric vector the same length as `x` with out-of-range values
#'   replaced by NA
#'
#' @examples
#' filter_na_range(c(1, 5, 10, 15), min = 3, max = 12)
#' # Returns: c(NA, 5, 10, NA)
#'
#' filter_na_range(c(1, NA, 10), min = 5)
#' # Returns: c(NA, NA, 10)
#' @export
filter_na_range <- function(x, min = -Inf, max = Inf) {
  # Input validation
  if (!is.numeric(x)) {
    cli::cli_abort("{.arg x} must be numeric.")
  }
  if (!is.numeric(min) || length(min) != 1 || is.na(min)) {
    cli::cli_abort("{.arg min} must be a single numeric value.")
  }
  if (!is.numeric(max) || length(max) != 1 || is.na(max)) {
    cli::cli_abort("{.arg max} must be a single numeric value.")
  }
  if (min > max) {
    cli::cli_abort("{.arg min} must be less than or equal to {.arg max}.")
  }

  dplyr::case_when(
    x < min ~ NA,
    x > max ~ NA,
    .default = x
  )
}
