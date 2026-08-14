#' Filter values outside a range to NA
#'
#' Replaces values in a numeric vector that fall outside the specified range
#' with NA. Values already NA in the input remain NA.
#'
#' @param x A numeric vector to filter
#' @param min_value Minimum value (inclusive). Values below this become NA.
#'   Default is -Inf (no lower bound).
#' @param max_value Maximum value (inclusive). Values above this become NA.
#'   Default is Inf (no upper bound).
#'
#' @return A numeric vector the same length as `x` with out-of-range values
#'   replaced by NA
#'
#' @examples
#' filter_na_range(c(1, 5, 10, 15), min_value = 3, max_value = 12)
#' # Returns: c(NA, 5, 10, NA)
#'
#' filter_na_range(c(1, NA, 10), min_value = 5)
#' # Returns: c(NA, NA, 10)
#' @export
filter_na_range <- function(x, min_value = -Inf, max_value = Inf) {
  # Input validation
  if (!is.numeric(x)) {
    cli::cli_abort("{.arg x} must be numeric.")
  }
  if (!is.numeric(min_value) || length(min_value) != 1 || is.na(min_value)) {
    cli::cli_abort("{.arg min_value} must be a single numeric value.")
  }
  if (!is.numeric(max_value) || length(max_value) != 1 || is.na(max_value)) {
    cli::cli_abort("{.arg max_value} must be a single numeric value.")
  }
  if (min_value > max_value) {
    cli::cli_abort(
      "{.arg min_value} must be less than or equal to {.arg max_value}."
    )
  }

  dplyr::case_when(
    x < min_value ~ NA,
    x > max_value ~ NA,
    .default = x
  )
}
