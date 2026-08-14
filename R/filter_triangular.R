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
#' @inheritParams filter-na-args
#'
#' @details
#' For `align = "center"`, the underlying [filter_rollmean()] returns
#' `NA` at the first and last `(window_width - 1) %/% 2` positions of
#' each pass, so the output has roughly `window_width - 1` `NA` values
#' at each edge.
#'
#' `keep_na = TRUE` restores the positions that were `NA` in the input,
#' but note that this filter fills gaps more aggressively than a single
#' [filter_rollmean()] pass: because the second pass smooths the output of
#' the first, values interpolated across a gap propagate outward. `keep_na`
#' blanks the original gap positions; it does not undo that spread into
#' neighbouring positions. Raise `min_obs` to suppress it.
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
  align = c("center", "right", "left"),
  keep_na = TRUE
) {
  align <- match.arg(align)
  ensure_keep_na(keep_na)

  # Both passes run with keep_na = FALSE so the second pass smooths a
  # complete series; gaps are restored once, from the original input.
  pass1 <- filter_rollmean(
    x,
    window_width = window_width,
    min_obs = min_obs,
    align = align,
    keep_na = FALSE
  )
  result <- filter_rollmean(
    pass1,
    window_width = window_width,
    min_obs = min_obs,
    align = align,
    keep_na = FALSE
  )
  restore_na(result, is.na(x), keep_na)
}
