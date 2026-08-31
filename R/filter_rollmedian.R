#' Apply Rolling Median Filter
#'
#' Applies a rolling median filter to a numeric vector using
#' [data.table::frollmedian()].
#'
#' @inheritParams filter_rollmean
#'
#' @details
#' Edge handling matches [filter_rollmean()]: partial windows at the edges
#' for `align = "right"`/`"left"`; `NA` at the edges for `align = "center"`.
#'
#' @return Filtered numeric vector, same length as `x`.
#'
#' @examples
#' x <- c(1, 2, 100, 4, 5, 6, 7)
#' filter_rollmedian(x, window_width = 3)
#'
#' # The median discards the spike; a rolling mean smears it across three
#' # neighbouring samples instead
#' filter_rollmean(x, window_width = 3)
#' @export
filter_rollmedian <- function(
  x,
  window_width = 5,
  min_obs = 1,
  align = c("center", "right", "left"),
  keep_na = TRUE
) {
  align <- match.arg(align)
  ensure_keep_na(keep_na)

  result <- rolling_with_min_obs(
    x,
    fn = data.table::frollmedian,
    window_width = window_width,
    min_obs = min_obs,
    align = align
  )
  restore_na(result, is.na(x), keep_na)
}
