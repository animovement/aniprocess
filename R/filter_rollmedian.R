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
#' @export
filter_rollmedian <- function(
  x,
  window_width = 5,
  min_obs = 1,
  align = c("right", "left", "center")
) {
  check_data_table()
  align <- match.arg(align)
  rolling_with_min_obs(
    x,
    fn = data.table::frollmedian,
    window_width = window_width,
    min_obs = min_obs,
    align = align
  )
}
