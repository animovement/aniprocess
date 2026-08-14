#' Fill missing values by a named method
#'
#' @description
#' Generic entry point to the `replace_na_*()` family: pick the method with
#' an argument rather than by choosing a function.
#'
#' @details
#' Returns the same shape it is given. Every method is univariate, so a
#' data frame is filled one column at a time — meaning this generic does
#' work with [dplyr::across()] as well as [dplyr::pick()].
#'
#' @param x A numeric vector, or a data frame of numeric columns, with
#'   missing values to fill.
#' @param method Character string specifying the replacement method:
#'   - `"linear"`: Linear interpolation (default)
#'   - `"spline"`: Spline interpolation for smoother curves
#'   - `"stine"`: Stineman interpolation preserving data shape
#'   - `"locf"`: Last observation carried forward
#'   - `"value"`: Replace with a constant value
#' @param value Numeric value for replacement when `method = "value"`.
#' @param min_gap Integer specifying the minimum gap size to fill. Gaps
#'   shorter than this are left as `NA`. Default `1` (fill all gaps).
#' @param max_gap Integer or `Inf` specifying the maximum gap size to fill.
#'   Gaps longer than this are left as `NA`. Default `Inf` (no limit).
#' @param ... Additional parameters passed to the underlying function.
#'
#' @return The same shape as `x`, with gaps filled where the gap-length
#'   criteria are met.
#'
#' @examples
#' x <- c(1, NA, NA, 4, 5, NA, NA, NA, 9)
#'
#' replace_na_with(x, "linear")
#' replace_na_with(x, "value", value = 0)
#' replace_na_with(x, "linear", max_gap = 2)
#'
#' # A frame is filled column by column
#' replace_na_with(data.frame(a = x, b = rev(x)), "locf")
#'
#' @seealso [filter_with()] for smoothing, [filter_na_with()] for masking.
#'   [replace_na()] is the original name of this function and still works.
#' @export
replace_na_with <- function(
  x,
  method = c("linear", "spline", "stine", "locf", "value"),
  value = NULL,
  min_gap = 1,
  max_gap = Inf,
  ...
) {
  method <- match.arg(method)

  if (method == "value" && is.null(value)) {
    cli::cli_abort(
      "{.arg value} must be specified when {.code method = \"value\"}."
    )
  }

  fn <- switch(
    method,
    linear = function(v, ...) {
      replace_na_linear(v, min_gap = min_gap, max_gap = max_gap, ...)
    },
    spline = function(v, ...) {
      replace_na_spline(v, min_gap = min_gap, max_gap = max_gap, ...)
    },
    stine = function(v, ...) {
      replace_na_stine(v, min_gap = min_gap, max_gap = max_gap, ...)
    },
    locf = function(v, ...) {
      replace_na_locf(v, min_gap = min_gap, max_gap = max_gap)
    },
    value = function(v, ...) {
      replace_na_value(v, value = value, min_gap = min_gap, max_gap = max_gap)
    }
  )

  dispatch_method(
    x,
    method = method,
    fn = fn,
    multivariate = FALSE,
    generic = "replace_na_with",
    ...
  )
}
