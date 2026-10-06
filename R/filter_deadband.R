#' Apply a deadband filter
#'
#' @description
#' `r lifecycle::badge('experimental')`
#'
#' Holds a still subject still. The output stays where it is until the
#' tracked point has moved more than `threshold` away from it, so the small
#' wandering of tracking noise on a stationary point is removed entirely
#' rather than merely made smaller.
#'
#' @details
#' Tracking noise on a point that is not moving adds a little to its path
#' every frame, so distance travelled is overestimated — the more so the
#' longer the subject is still and the higher the sampling rate — and speed
#' never reaches zero. A smoother scales that noise down but does not remove
#' it. A deadband does: movement smaller than `threshold` is ignored.
#'
#' The output keeps an *anchor*, starting at the first complete row. For
#' each row, the distance from the anchor to the row's point is compared
#' with `threshold`. While it is at most `threshold`, the output is the
#' anchor. Once it is more, the anchor moves, in one of two ways:
#'
#' * `"hold"` (default): the anchor jumps to the point. This is the "direct"
#'   *Minimal Distance Moved* of Noldus EthoVision XT, and the behaviour
#'   OptiTrack Motive describes for its rigid-body *Deadband Filter*, so
#'   results can be compared with theirs.
#' * `"drag"`: the anchor is pulled towards the point until it is exactly
#'   `threshold` away, as if on a lead of that length. This is the play
#'   (backlash) operator of hysteresis theory, in its vector form (Krejčí,
#'   1991). The output never jumps and trails the point by at most
#'   `threshold`, but sustained movement is shortened by `threshold` at
#'   each start and stop.
#'
#' With several coordinate columns the distance is Euclidean, so the dead
#' zone is a circle or sphere: a move registers by its length, whatever its
#' direction. The axes should therefore share a unit, and be Cartesian.
#'
#' ## Choosing a threshold
#'
#' `threshold` is in the units of the coordinates. It should exceed the
#' noise on a still point — a few times its standard deviation, measured on
#' a stretch where the subject is known to be still — and stay below the
#' smallest movement that matters. Smoothing first, for instance with
#' [filter_lowpass()], lowers the noise and so lets the threshold be
#' smaller.
#'
#' ## What it does to derivatives
#'
#' A deadband is for distance travelled, immobility and bout detection, not
#' for kinematics. In `"hold"` mode the speed is zero while the anchor holds
#' and spikes when it jumps; in `"drag"` mode it is zero, then continuous.
#' Neither is the subject's real speed.
#'
#' The filter is recursive and causal: each output depends on the rows
#' before it, so the result depends on where the series starts, and
#' running it backwards in time gives a different answer.
#'
#' ## Missing values
#'
#' A row with any coordinate missing is not a point: it is left as it is,
#' and does not move the anchor. The next complete row is compared with the
#' anchor as it stood before the gap, so a subject that is in the same place
#' after a dropout stays exactly where it was. When a run of such rows is
#' longer than `max_gap`, the anchor is reset instead: the next complete row
#' is taken as it is, as at the start of the series.
#'
#' @section Input shape:
#' This is a **column-level** function: it takes a data frame of coordinate
#' columns and returns one of the same shape. The aniframe tier is
#' [filter_across()], which applies it within the frame's existing grouping
#' so each individual / track / keypoint is filtered as its own trajectory.
#'
#' ```r
#' filter_across(af, "deadband", threshold = 2)                       # a whole aniframe
#' data |> mutate(filter_deadband(pick(all_of(c("x", "y"))), threshold = 2))  # the columns
#' ```
#'
#' The distance depends on all coordinates jointly, so this cannot be used
#' with [dplyr::across()], which passes one column at a time. For a single
#' signal, pass a one-column frame.
#'
#' @param data A data frame of numeric coordinate columns — typically
#'   supplied by [dplyr::pick()] inside [dplyr::mutate()]. To filter a whole
#'   aniframe, use [filter_across()].
#' @param threshold A single non-negative number, in the units of the
#'   coordinates: how far the point has to move from the anchor before the
#'   output follows. `0` returns `data` unchanged.
#' @param mode How the output follows once the threshold is crossed:
#'   `"hold"` (default) jumps to the point, `"drag"` moves just far enough
#'   to bring the point back to the edge of the dead zone. See Details.
#' @param max_gap A whole number of rows, or `Inf` (default): the longest
#'   run of incomplete rows across which the anchor is kept. After a longer
#'   gap, the next complete row starts afresh.
#'
#' @return A data frame with the same names and shape as `data`.
#'
#' @references
#' OptiTrack. Properties Pane: Rigid Body — Deadband Filter. *Motive
#' documentation*.
#' <https://docs.optitrack.com/motive-ui-panes/properties-pane/properties-pane-rigid-body>
#'
#' Noldus Information Technology. Smooth the tracks: Minimal Distance Moved
#' methods. *EthoVision XT 19 reference manual*.
#' <https://noldus.com/shared/resources/book/noldus-product-documentation/chapter/ethovision-xt/page/ethovision-xt-19-smooth-the-tracks-minimum-distance-moved-methods>
#'
#' Hen, I., Sakov, A., Kafkafi, N., Golani, I., & Benjamini, Y. (2004). The
#' dynamics of spatial behavior: how can robust smoothing techniques help?
#' *Journal of Neuroscience Methods*, 133, 161–172.
#' \doi{10.1016/j.jneumeth.2003.10.013}
#'
#' Krasnosel'skiǐ, M. A., & Pokrovskiǐ, A. V. (1989). *Systems with
#' Hysteresis*. Springer. \doi{10.1007/978-3-642-61302-9}
#'
#' Krejčí, P. (1991). Vector hysteresis models. *European Journal of
#' Applied Mathematics*, 2, 281–292. \doi{10.1017/S0956792500000541}
#'
#' @examples
#' # A point that sits still with a little noise for 100 frames, then moves
#' # 10 units in 10 frames
#' set.seed(1)
#' coords <- data.frame(
#'   x = c(rep(0, 100), 1:10) + rnorm(110, sd = 0.05),
#'   y = rnorm(110, sd = 0.05)
#' )
#'
#' # The still stretch comes out exactly still
#' held <- filter_deadband(coords, threshold = 0.2)
#' held[95:105, ]
#'
#' # So the noise no longer adds to the path length
#' path_length <- function(d) sum(sqrt(diff(d$x)^2 + diff(d$y)^2))
#' path_length(coords)
#' path_length(held)
#'
#' # "drag" follows without jumping, at most `threshold` behind
#' filter_deadband(coords, threshold = 0.2, mode = "drag")[95:105, ]
#'
#' # The aniframe tier
#' af <- anicore::example_anipoint(n_obs = 60, n_individuals = 1, n_keypoints = 1)
#' filter_across(af, "deadband", threshold = 0.5)
#'
#' @seealso [filter_lowpass()] and [filter_one_euro()], which reduce noise
#'   rather than remove it, and work well before a deadband.
#' @export
filter_deadband <- function(
  data,
  threshold,
  mode = c("hold", "drag"),
  max_gap = Inf
) {
  ensure_coords(data, across = "filter_across")
  ensure_non_negative_scalar(threshold, "threshold")
  mode <- match.arg(mode)
  if (
    !is.numeric(max_gap) ||
      length(max_gap) != 1L ||
      is.na(max_gap) ||
      max_gap < 0 ||
      (is.finite(max_gap) && max_gap != round(max_gap))
  ) {
    cli::cli_abort(
      "{.arg max_gap} must be a single non-negative whole number, or {.code Inf}."
    )
  }

  if (nrow(data) == 0L) {
    return(data)
  }

  points <- as.matrix(data)
  held <- deadband_core(points, threshold, drag = mode == "drag", max_gap)
  for (j in seq_along(data)) {
    data[[j]] <- held[, j]
  }
  data
}


#' The deadband recursion.
#'
#' Rows with any `NA` are left as they are and do not move the anchor; a
#' run of them longer than `max_gap` clears it.
#'
#' @param points Numeric matrix, one row per sample.
#' @param threshold Dead-zone radius.
#' @param drag `TRUE` for the play operator, `FALSE` to jump.
#' @param max_gap Longest run of incomplete rows that keeps the anchor.
#'
#' @return Numeric matrix of the same shape as `points`.
#' @keywords internal
deadband_core <- function(points, threshold, drag, max_gap) {
  out <- points
  complete <- stats::complete.cases(points)
  anchor <- NULL
  gap <- 0

  for (i in seq_len(nrow(points))) {
    if (!complete[i]) {
      gap <- gap + 1
      next
    }
    if (gap > max_gap) {
      anchor <- NULL
    }
    gap <- 0

    p <- points[i, ]
    if (is.null(anchor)) {
      anchor <- p
    } else {
      step <- p - anchor
      distance <- sqrt(sum(step^2))
      if (distance > threshold) {
        anchor <- if (drag) p - step * (threshold / distance) else p
      }
    }
    out[i, ] <- anchor
  }
  out
}
