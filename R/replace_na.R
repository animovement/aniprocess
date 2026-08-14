#' Replace Missing Values Using Various Methods
#'
#' @description
#' A wrapper function that replaces missing values using various interpolation
#' or filling methods.
#'
#' @param x A vector containing numeric data with missing values (NAs)
#' @param method Character string specifying the replacement method:
#'   - "linear": Linear interpolation (default)
#'   - "spline": Spline interpolation for smoother curves
#'   - "stine": Stineman interpolation preserving data shape
#'   - "locf": Last observation carried forward
#'   - "value": Replace with a constant value
#' @param value Numeric value for replacement when method = "value"
#' @param min_gap Integer specifying minimum gap size to interpolate/fill. Gaps shorter
#'   than this will be left as NA. Default is 1 (handle all gaps).
#' @param max_gap Integer or Inf specifying maximum gap size to interpolate/fill. Gaps longer
#'   than this will be left as NA. Default is Inf (no upper limit).
#' @param ... Additional parameters passed to the underlying interpolation functions
#'
#' @return A numeric vector with NA values replaced according to the specified method
#' where gap length criteria are met.
#'
#' @examples
#' \dontrun{
#' x <- c(1, NA, NA, 4, 5, NA, NA, NA, 9)
#'
#' # Different methods
#' replace_na(x, method = "linear")
#' replace_na(x, method = "spline")
#' replace_na(x, method = "stine")
#' replace_na(x, method = "locf")
#' replace_na(x, method = "value", value = 0)
#'
#' # With gap constraints
#' replace_na(x, method = "linear", min_gap = 2)
#' replace_na(x, method = "spline", max_gap = 2)
#' replace_na(x, method = "linear", min_gap = 2, max_gap = 3)
#' }
#'
#' @section Naming:
#' This is the original name for what is now [replace_na_with()], and the
#' two are identical — this one simply calls it. `replace_na()` collides
#' with [tidyr::replace_na()], which does something different, so
#' [replace_na_with()] is the name to prefer in new code. Nothing is
#' deprecated: this function keeps working.
#'
#' @seealso
#' - [replace_na_with()], the preferred name
#' - replace_na_linear() for linear interpolation details
#' - replace_na_spline() for spline interpolation details
#' - replace_na_stine() for Stineman interpolation details
#' - replace_na_locf() for last observation carried forward details
#' - replace_na_value() for constant value replacement details
#'
#' @export
replace_na <- function(
  x,
  method = "linear",
  value = NULL,
  min_gap = 1,
  max_gap = Inf,
  ...
) {
  replace_na_with(
    x,
    method = method,
    value = value,
    min_gap = min_gap,
    max_gap = max_gap,
    ...
  )
}
