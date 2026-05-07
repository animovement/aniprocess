#' Apply Triangular Filter
#'
#' Applies a triangular smoothing filter — a rolling mean of width
#' `window_width` applied twice. The composition of two boxcars is a
#' triangular kernel, so the effective kernel width is `2 * window_width - 1`
#' with peak weight at the centre.
#'
#' @param x Numeric vector to filter.
#' @param window_width Integer width of each rolling-mean pass. The
#'   effective triangular kernel has width `2 * window_width - 1`.
#' @param min_obs Minimum number of non-NA values required per window
#'   per pass. Defaults to `1`.
#' @param align Window alignment, passed to [filter_rollmean()]. One of
#'   `"center"` (default), `"right"`, or `"left"`.
#'
#' @details
#' For `align = "center"`, the underlying [filter_rollmean()] returns
#' `NA` at the first and last `(window_width - 1) %/% 2` positions of
#' each pass, so the output has roughly `window_width - 1` `NA` values
#' at each edge.
#'
#' Triangular smoothing is sometimes useful as a lightweight alternative
#' to a Gaussian kernel when the kernel shape is less critical than the
#' simplicity of the implementation.
#'
#' @return Filtered numeric vector, same length as `x`.
#'
#' @examples
#' x <- c(1, 2, 3, 100, 5, 6, 7, 8, 9)
#' filter_triangular(x, window_width = 3)
#'
#' @export
filter_triangular <- function(
  x,
  window_width = 5,
  min_obs = 1,
  align = c("center", "right", "left")
) {
  align <- match.arg(align)
  pass1 <- filter_rollmean(
    x,
    window_width = window_width,
    min_obs = min_obs,
    align = align
  )
  filter_rollmean(
    pass1,
    window_width = window_width,
    min_obs = min_obs,
    align = align
  )
}
