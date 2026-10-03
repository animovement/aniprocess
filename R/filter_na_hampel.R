#' Mask spikes against a rolling median
#'
#' @description
#' `r lifecycle::badge('experimental')`
#'
#' Masks spikes — a point that jumps away for a frame or two and comes back —
#' by judging each point against its own neighbourhood, after Hampel. A point
#' is set to `NA` when its distance from the rolling median of the window
#' around it exceeds `k` robust deviations of that window. Because both the
#' median and the spread are local, the threshold follows the movement: tight
#' where the keypoint moves slowly, loose where it moves fast — which a single
#' threshold on speed or on position cannot be.
#'
#' Unlike the classic Hampel filter, the point is masked rather than replaced
#' with the median, so it composes like the rest of the `filter_na_*()`
#' family: mask, then fill with [replace_na_with()].
#'
#' @param data A data frame of numeric coordinate columns — typically supplied
#'   by [dplyr::pick()] inside [dplyr::mutate()]. To filter a whole aniframe,
#'   use [filter_na_across()].
#' @param window_width An odd whole number, at least 3 (default `5`): the
#'   number of rows in the window, centred on the point being judged. Up to
#'   `(window_width - 1) / 2` consecutive spike frames can be caught.
#' @param k A single non-negative number (default `3`): how many robust
#'   deviations a point may lie from the rolling median before it is masked.
#' @param min_distance A single non-negative number (default `0`), in the
#'   units of the coordinates: a floor on the threshold. A point that lies
#'   within `min_distance` of its rolling median is never masked, however
#'   small the spread of its window.
#'
#' @return `data`, with every coordinate set to `NA` on rows judged to be
#'   spikes.
#'
#' @details
#' Each row is judged against the window of `window_width` rows centred on
#' it:
#'
#' 1. The window's median position is taken axis by axis, with
#'    [filter_rollmedian()].
#' 2. The row's deviation `d` is the Euclidean distance of its point from
#'    that median.
#' 3. The window's robust spread `S` is `1.4826` times the median of the
#'    distances of all the window's points from the same median: the median
#'    absolute deviation (MAD) of the window, scaled.
#' 4. The row is masked when `d > max(k * S, min_distance)`.
#'
#' With one coordinate column this is the Hampel identifier of Pearson et
#' al. (2016). With several, the distance is Euclidean, so a point is masked
#' in all axes at once, and the axes should share a unit. The factor 1.4826
#' makes the MAD estimate the standard deviation of one-dimensional Gaussian
#' noise; a Euclidean distance in two or three dimensions is not distributed
#' that way, so there `k` is a multiple of the robust spread rather than a
#' number of standard deviations, and more conservative.
#'
#' `min_distance` is what keeps a keypoint that barely moves from losing its
#' noise: there the MAD of a window can be tiny, or zero, and any deviation at
#' all exceeds `k` of it.
#'
#' The spread is that of the window's points about the window's own median,
#' as in Pearson et al., so it includes the distance travelled within the
#' window. On steady motion a spike therefore has to reach several times the
#' per-frame step to be masked — about nine at the defaults — while on a slow
#' stretch the same settings catch spikes far smaller than the fast stretch's
#' steps. A spread taken instead over each point's distance to its *own*
#' rolling median is scaled by the noise rather than the motion, and so is
#' more sensitive on fast stretches; but it is exactly zero wherever every
#' axis moves monotonically through the window, so it flags noise there
#' unless `min_distance` is set.
#'
#' Every row is judged against the original data in a single pass, so a spike
#' does not shift the verdict on its neighbours: the median and the MAD both
#' ignore up to `(window_width - 1) / 2` aberrant points in the window. A run
#' of spikes longer than that dominates the window and is not caught — that is
#' what [filter_na_excursion()] is for.
#'
#' ## Missing values and edges
#'
#' A row with any coordinate missing is neither judged nor used to judge its
#' neighbours: it is not a point, and is left as it is. A row is judged only
#' when a majority of its window — at least `(window_width + 1) / 2` rows —
#' holds complete points, which is also the fewest that leave a spike in the
#' minority. Positions beyond either end of the series count as missing, so
#' the first and last rows are judged against the part of the window that
#' exists, provided it is complete.
#'
#' The window counts rows, not time, so rows are taken to be in temporal
#' order; on irregularly sampled data it spans a varying duration.
#'
#' @section Input shape:
#' Takes and returns a frame of coordinate columns, so it composes inside
#' [dplyr::mutate()]:
#'
#' ```r
#' data |> mutate(filter_na_hampel(pick(all_of(c("x", "y")))))
#' ```
#'
#' The deviation depends on all coordinates jointly, so this cannot be used
#' with [dplyr::across()]. Every row of `data` is treated as one continuous
#' track; called via [filter_na_across()], or with [dplyr::pick()] inside a
#' grouped [dplyr::mutate()], a window never spans a track boundary.
#' `confidence` is not a coordinate and so is never modified here;
#' [filter_na_across()] blanks it on masked rows.
#'
#' @references
#' Pearson, R. K., Neuvo, Y., Astola, J., & Gabbouj, M. (2016). Generalized
#' Hampel filters. *EURASIP Journal on Advances in Signal Processing*,
#' 2016, 87. \doi{10.1186/s13634-016-0383-6}.
#'
#' @examples
#' # One unit per frame, then twenty, with a 15-unit spike at row 4
#' coords <- data.frame(
#'   x = c(0, 1, 2, 3, 4, 5, 6, 26, 46, 66, 86, 106),
#'   y = c(0, 0, 0, 15, 0, 0, 0, 0, 0, 0, 0, 0)
#' )
#' filter_na_hampel(coords)
#'
#' # A speed threshold low enough to catch the spike also takes the fast
#' # stretch, whose steps are larger than the spike
#' filter_na_speed(coords, threshold = 10, time = 1:12)
#'
#' # A keypoint that barely moves: without a floor, its noise is flagged
#' still <- data.frame(x = c(5, 5, 5.01, 5, 5, 5, 4.99, 5))
#' filter_na_hampel(still)
#' filter_na_hampel(still, min_distance = 0.05)
#'
#' @seealso [filter_na_speed()] and [filter_na_excursion()], which judge
#'   steps and excursions rather than deviations from a neighbourhood;
#'   [filter_rollmedian()] to smooth with the median instead.
#'
#' @export
filter_na_hampel <- function(
  data,
  window_width = 5,
  k = 3,
  min_distance = 0
) {
  ensure_coords(data, across = "filter_na_across")
  ensure_odd_window(window_width)
  ensure_non_negative_scalar(k, "k")
  ensure_non_negative_scalar(min_distance, "min_distance")

  # The caller has already decided which rows belong together.
  flagged <- hampel_mask(data, window_width, k, min_distance)
  data[flagged, ] <- NA_real_
  data
}


#' Hampel mask for one group of coordinates.
#'
#' Pads the series with `(window_width - 1) / 2` missing rows at each end, so
#' every row has a full centred window and positions beyond the series count
#' as missing. The rolling median comes from [filter_rollmedian()], one axis
#' at a time; the MAD is about that median, from a matrix holding each row's
#' window side by side.
#'
#' @param coords A data frame of the group's spatial columns.
#' @inheritParams filter_na_hampel
#'
#' @return Logical vector of length `nrow(coords)`, `TRUE` on spikes.
#' @keywords internal
hampel_mask <- function(coords, window_width, k, min_distance) {
  n <- nrow(coords)
  half <- (window_width - 1) %/% 2

  # A point with any axis missing is not a point: blank it in every axis,
  # so it drops out of every window alike.
  points <- as.matrix(coords)
  points[!stats::complete.cases(points), ] <- NA_real_
  gap <- matrix(NA_real_, nrow = half, ncol = ncol(points))
  padded <- rbind(gap, points, gap)
  inside <- half + seq_len(n)

  centre <- vapply(
    seq_len(ncol(padded)),
    function(axis) {
      filter_rollmedian(
        padded[, axis],
        window_width = window_width,
        min_obs = half + 1,
        align = "center"
      )[inside]
    },
    numeric(n)
  )
  centre <- matrix(centre, nrow = n, ncol = ncol(points))

  # Distance of every point in row i's window from row i's median, one
  # column per offset. The middle column is the point itself.
  distances <- vapply(
    -half:half,
    function(offset) {
      sqrt(rowSums((padded[inside + offset, , drop = FALSE] - centre)^2))
    },
    numeric(n)
  )
  distances <- matrix(distances, nrow = n, ncol = window_width)

  deviation <- distances[, half + 1]
  spread <- 1.4826 * row_median(distances)
  threshold <- pmax(k * spread, min_distance)

  # `deviation` is NA wherever the row was not judged.
  !is.na(deviation) & deviation > threshold
}


#' Median of each row of a matrix, ignoring `NA`.
#'
#' Vectorised: sorts every row at once with a single [order()], rather than
#' calling [stats::median()] once per row.
#'
#' @param m A numeric matrix.
#'
#' @return A numeric vector with one value per row; `NA` for a row with no
#'   observed values, whose first sorted value is itself `NA`.
#' @keywords internal
row_median <- function(m) {
  n <- nrow(m)
  observed <- rowSums(!is.na(m))
  # Within each row, ascending, with NA last.
  sorted <- matrix(m[order(row(m), m)], nrow = n, byrow = TRUE)
  lower <- pmax((observed + 1) %/% 2, 1)
  upper <- pmax(observed %/% 2 + 1, 1)
  rows <- seq_len(n)
  (sorted[cbind(rows, lower)] + sorted[cbind(rows, upper)]) / 2
}
