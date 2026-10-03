#' Deprecated `filter_na_*()` functions
#'
#' @description
#' `r lifecycle::badge("deprecated")`
#'
#' The NA-masking functions are now called `mask_na_*()`: they set bad values
#' to `NA` and keep every row, which `filter_` suggested they did not. Each
#' old name forwards to its replacement unchanged.
#'
#' * `filter_na_across()` → [mask_na_across()]
#' * `filter_na_with()` → [mask_na_with()]
#' * `filter_na_confidence()` → [mask_na_confidence()]
#' * `filter_na_excursion()` → [mask_na_excursion()]
#' * `filter_na_range()` → [mask_na_range()]
#' * `filter_na_roi()` → [mask_na_roi()]
#' * `filter_na_speed()` → [mask_na_speed()]
#'
#' @param data,x,method,variables,...,on_deltas,threshold,confidence,outlier_sd,return_sd,by_axis,min_value,max_value,x_min,x_max,y_min,y_max,z_min,z_max,x_center,y_center,z_center,radius,time
#'   See the replacement.
#' @return What the replacement returns.
#' @name filter_na_deprecated
#' @keywords internal
NULL

#' @rdname filter_na_deprecated
#' @export
filter_na_across <- function(
  data,
  method = c("range", "speed", "excursion", "hampel", "roi", "confidence"),
  variables = NULL,
  ...,
  on_deltas = FALSE
) {
  lifecycle::deprecate_warn("0.6.0", "filter_na_across()", "mask_na_across()")
  mask_na_across(
    data,
    method = method,
    variables = {{ variables }},
    ...,
    on_deltas = on_deltas
  )
}

#' @rdname filter_na_deprecated
#' @export
filter_na_with <- function(
  x,
  method = c("range", "speed", "excursion", "hampel", "roi", "confidence"),
  ...
) {
  lifecycle::deprecate_warn("0.6.0", "filter_na_with()", "mask_na_with()")
  mask_na_with(x, method = method, ...)
}

#' @rdname filter_na_deprecated
#' @export
filter_na_confidence <- function(data, threshold = 0.6, confidence = NULL) {
  lifecycle::deprecate_warn(
    "0.6.0",
    "filter_na_confidence()",
    "mask_na_confidence()"
  )
  mask_na_confidence(data, threshold = threshold, confidence = confidence)
}

#' @rdname filter_na_deprecated
#' @export
filter_na_excursion <- function(
  data,
  outlier_sd = 5,
  return_sd = 1,
  by_axis = TRUE
) {
  lifecycle::deprecate_warn(
    "0.6.0",
    "filter_na_excursion()",
    "mask_na_excursion()"
  )
  mask_na_excursion(
    data,
    outlier_sd = outlier_sd,
    return_sd = return_sd,
    by_axis = by_axis
  )
}

#' @rdname filter_na_deprecated
#' @export
filter_na_range <- function(x, min_value = -Inf, max_value = Inf) {
  lifecycle::deprecate_warn("0.6.0", "filter_na_range()", "mask_na_range()")
  mask_na_range(x, min_value = min_value, max_value = max_value)
}

#' @rdname filter_na_deprecated
#' @export
filter_na_roi <- function(
  data,
  x_min = NULL,
  x_max = NULL,
  y_min = NULL,
  y_max = NULL,
  z_min = NULL,
  z_max = NULL,
  x_center = NULL,
  y_center = NULL,
  z_center = NULL,
  radius = NULL
) {
  lifecycle::deprecate_warn("0.6.0", "filter_na_roi()", "mask_na_roi()")
  mask_na_roi(
    data,
    x_min = x_min,
    x_max = x_max,
    y_min = y_min,
    y_max = y_max,
    z_min = z_min,
    z_max = z_max,
    x_center = x_center,
    y_center = y_center,
    z_center = z_center,
    radius = radius
  )
}

#' @rdname filter_na_deprecated
#' @export
filter_na_speed <- function(data, threshold = "auto", time = NULL) {
  lifecycle::deprecate_warn("0.6.0", "filter_na_speed()", "mask_na_speed()")
  mask_na_speed(data, threshold = threshold, time = time)
}
