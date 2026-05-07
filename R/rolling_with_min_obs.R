#' Apply a data.table rolling function with a `min_obs` threshold
#'
#' Wraps [data.table::frollmean()] / [data.table::frollmedian()] (or any
#' compatible `frollX` function) and masks results where the window contains
#' fewer than `min_obs` non-NA values.
#'
#' For `align = "right"` or `"left"`, the underlying function runs with
#' `partial = TRUE` so positions near the edge use whatever values are
#' available. For `align = "center"`, `partial = TRUE` is not supported by
#' data.table, so partial windows at the edges return `NA`.
#'
#' @param x Numeric vector.
#' @param fn A `data.table` rolling function such as `frollmean` or
#'   `frollmedian`.
#' @param window_width Integer window width.
#' @param min_obs Minimum number of non-NA values per window.
#' @param align One of `"right"`, `"left"`, `"center"`.
#'
#' @return Numeric vector of the same length as `x`.
#' @keywords internal
rolling_with_min_obs <- function(x, fn, window_width, min_obs, align) {
  use_partial <- align %in% c("right", "left")

  result <- fn(
    x,
    n = window_width,
    align = align,
    na.rm = TRUE,
    partial = use_partial
  )

  # Mask positions where the window has fewer non-NA values than min_obs.
  # min_obs <= 1 only needs to filter NaN (all-NA windows produce NaN, which
  # we surface as NA for consistency).
  if (min_obs > 1) {
    counts <- data.table::frollsum(
      as.numeric(!is.na(x)),
      n = window_width,
      align = align,
      na.rm = TRUE,
      partial = use_partial
    )
    result[counts < min_obs] <- NA_real_
  }
  result[is.nan(result)] <- NA_real_
  result
}
