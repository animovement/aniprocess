#' Mask values to NA by a named criterion
#'
#' @description
#' Generic entry point to the `mask_na_*()` family: pick the criterion
#' with an argument rather than by choosing a function. Every method
#' replaces values that fail its criterion with `NA`; none of them fill or
#' smooth.
#'
#' @details
#' Returns the same shape it is given.
#'
#' Only `"range"` is univariate, and it is applied one column at a time
#' when given a frame. The rest decide per row using all coordinates at
#' once, so they require a frame of coordinate columns and cannot be used
#' with [dplyr::across()].
#'
#' Method-specific arguments go through `...`: `min_value`/`max_value` for
#' `"range"`, `threshold` and `time` for `"speed"`, `outlier_sd`/`return_sd`
#' for `"excursion"`, `window_width`, `k` and `min_distance` for `"hampel"`,
#' the ROI bounds for `"roi"`, and `threshold` plus `confidence` for
#' `"confidence"`.
#'
#' @param x A numeric vector, or a data frame of numeric coordinate columns.
#' @param method Criterion to apply. One of `"range"`, `"speed"`,
#'   `"excursion"`, `"hampel"`, `"roi"` or `"confidence"`.
#' @param ... Arguments passed to the underlying function.
#'
#' @return The same shape as `x`, with failing values replaced by `NA`.
#'
#' @examples
#' mask_na_with(c(1, 5, 10, 15), "range", min_value = 3, max_value = 12)
#'
#' coords <- data.frame(x = c(0, 1, 2, 50, 4), y = c(0, 0, 0, 0, 0))
#' mask_na_with(coords, "speed", threshold = 10, time = 1:5)
#'
#' @seealso [filter_with()] for the smoothing and frequency filters,
#'   [replace_na_with()] for filling gaps.
#' @export
mask_na_with <- function(
  x,
  method = c("range", "speed", "excursion", "hampel", "roi", "confidence"),
  ...
) {
  method <- match.arg(method)

  fn <- switch(
    method,
    range = mask_na_range,
    speed = mask_na_speed,
    excursion = mask_na_excursion,
    hampel = mask_na_hampel,
    roi = mask_na_roi,
    confidence = mask_na_confidence
  )

  dispatch_method(
    x,
    method = method,
    fn = fn,
    multivariate = method != "range",
    generic = "mask_na_with",
    ...
  )
}
