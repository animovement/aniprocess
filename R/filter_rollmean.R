#' Apply Rolling Mean Filter
#'
#' Applies a rolling mean filter to a numeric vector using
#' [data.table::frollmean()].
#'
#' @param x Numeric vector to filter.
#' @param window_width Integer specifying window size for the rolling
#'   calculation.
#' @param min_obs Minimum number of non-NA values required in the window.
#'   Positions with fewer non-NA values return `NA`. Defaults to `1`.
#' @param align Window alignment. One of `"right"` (default), `"left"`, or
#'   `"center"`.
#'
#' @details
#' For `align = "right"` or `"left"`, partial windows at the edges of the
#' series are computed (so position 1 with a width-5 right-aligned window
#' returns the value at position 1, not `NA`). For `align = "center"`,
#' edges are not partial: the first and last `(window_width - 1) %/% 2`
#' positions return `NA`. This is a limitation of the underlying
#' [data.table::frollmean()] implementation.
#'
#' @return Filtered numeric vector, same length as `x`.
#'
#' @export
filter_rollmean <- function(
  x,
  window_width = 5,
  min_obs = 1,
  align = c("right", "left", "center")
) {
  align <- match.arg(align)
  rolling_with_min_obs(
    x,
    fn = data.table::frollmean,
    window_width = window_width,
    min_obs = min_obs,
    align = align
  )
}
