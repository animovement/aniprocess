#' Mask points whose segments are far off their usual length
#'
#' @description
#' `r lifecycle::badge('experimental')`
#'
#' Finds the points of a structure that sit in the wrong place, from the
#' lengths of the segments joining them, and replaces their coordinates with
#' `NA`. A segment meant to be rigid — a long bone, the pelvis — stretches or
#' shrinks when one of its ends is wrong. Each segment is compared with its
#' usual length, and the point to blame is masked, not the segment: a wrong
#' ankle makes both shin and foot off while the thigh is fine, so the ankle
#' goes, and the knee and the toe stay.
#'
#' This catches errors that confidence, speed and smoothing miss: a point
#' that sits wrong for many frames with a confident score, such as a match
#' in multi-camera 3D that several cameras happen to agree on.
#'
#' Unlike the other `mask_na_*()` functions, it judges each point by its
#' neighbours, so it needs all of an individual's points at once. It takes
#' the whole anipoint rather than one track at a time, and is not a method of
#' [mask_na_across()].
#'
#' @details
#' # Reference length
#'
#' Each segment is compared with a reference length:
#'
#' * its `length` in the structure (see [anicore::anistructure()]), when the
#'   structure gives one, in the frame's spatial units;
#' * otherwise, the median of its non-missing lengths over the track: within
#'   each group of [anicore::as_anisegment()], that is per segment and per
#'   combination of the keys other than the structure's variable — per
#'   individual, and per session or trial when `data` has them. Every time
#'   point counts towards it, including those where the segment turns out to
#'   be off; the median holds while they are fewer than half.
#'
#' A segment with no `length` in the structure has no usable reference in a
#' track where its median is missing (its two ends are never present
#' together) or zero (they coincide in at least half the frames). It is not
#' judged in that track.
#'
#' # When a segment is off
#'
#' The lengths are those of [anicore::as_anisegment()]: the distance between
#' the segment's two points in each frame. A segment is off in a frame when
#' its length `L` differs from its reference `R` by more than both
#' thresholds:
#'
#' ```
#' abs(L - R) > tolerance * R  &  abs(L - R) > min_difference
#' ```
#'
#' A difference equal to a threshold is not off. With the default
#' `min_difference = 0`, `tolerance` alone decides.
#'
#' A segment whose length is missing in a frame, because either end is `NA`
#' or has no row there, is not measured in that frame.
#'
#' # Which point is to blame
#'
#' Blame is decided frame by frame — at each time point of each individual,
#' and of each session or trial — from the segments measured in that frame.
#' Only the selected `segments` count.
#'
#' * A point with two or more measured segments is masked when all of them
#'   are off.
#' * A point with one measured segment — an end point such as a toe or a
#'   nose, or a point whose other segments are missing in that frame — is
#'   masked when that segment is off and the point at its other end has
#'   another measured segment that is not off. That point is in place, so
#'   the fault is at this end. It is also what keeps a wrong ankle from
#'   taking the toe with it: the toe's one segment is the foot, and the
#'   ankle's other segment, the shin, is off as well.
#' * When neither end of an off segment has another measured segment,
#'   nothing tells which end is wrong, and neither is masked.
#' * A point with no measured segment is left alone, as is any level of the
#'   structure's variable that the selected segments do not reach.
#'
#' It is one pass over the lengths as measured: masking a point does not
#' re-judge its neighbours. A correct point whose neighbours are all wrong
#' has every segment off, so it is masked along with them.
#'
#' # What is masked
#'
#' A masked point has every axis set to `NA`, and its `confidence` too where
#' the frame has that column, as [mask_na_across()] does. A point that is
#' already `NA`, in any axis, has no measured segment, so it is not judged,
#' and its neighbours are judged by their other segments.
#'
#' @inheritParams anicore::as_anisegment
#' @param data An anipoint in 2D or 3D Cartesian coordinates, with a
#'   structure attached by [anicore::set_structure()].
#' @param tolerance A single non-negative number (default `0.3`): how far a
#'   segment's length may differ from its reference, as a fraction of the
#'   reference, before it is off.
#' @param min_difference A single non-negative number (default `0`): how far
#'   a segment's length may differ from its reference, in the frame's spatial
#'   units, before it is off. A segment must exceed both this and
#'   `tolerance`, so this keeps a short segment from being off over a
#'   difference that is large only relative to its length.
#' @param segments Names of the segments to judge, as a character vector, or
#'   `NULL` (the default) for every segment of the structure. Choose those
#'   meant to be rigid: long bones and the pelvis, not the width of the
#'   shoulders or the neck. A point's segments are counted among these
#'   alone, so a point with one of them is an end point.
#'
#' @return `data`, with every axis of each masked point set to `NA`, and its
#'   `confidence` where present. Its rows, columns and metadata are
#'   unchanged.
#'
#' @examples
#' # A leg standing straight for five frames
#' leg <- anicore::anipoint(
#'   individual = 1,
#'   keypoint = rep(c("hip", "knee", "ankle", "toe"), each = 5),
#'   time = rep(1:5, times = 4),
#'   x = 0,
#'   y = rep(c(4, 2, 0, -1), each = 5),
#'   variables_what = c("individual", "keypoint"),
#'   index = "time",
#'   variables_where = c("x", "y")
#' )
#' leg <- anicore::set_structure(
#'   leg,
#'   anicore::anistructure(
#'     segments = data.frame(
#'       segment = c("thigh", "shin", "foot"),
#'       from = c("hip", "knee", "ankle"),
#'       to = c("knee", "ankle", "toe")
#'     )
#'   )
#' )
#'
#' # In frame 3 the ankle is off to the side: shin and foot both stretch
#' leg$x[leg$keypoint == "ankle" & leg$time == 3] <- 2
#'
#' # Only the ankle is masked, not the knee or the toe
#' mask_na_segment_length(leg) |>
#'   dplyr::filter(time == 3)
#'
#' # Judge thigh and shin alone: the ankle is now an end point, and goes
#' # because the knee's other segment, the thigh, is fine
#' mask_na_segment_length(leg, segments = c("thigh", "shin")) |>
#'   dplyr::filter(time == 3)
#'
#' # Expected lengths recorded in the structure are used instead of the median
#' leg <- anicore::set_structure(
#'   leg,
#'   anicore::anistructure(
#'     segments = data.frame(
#'       segment = c("thigh", "shin", "foot"),
#'       from = c("hip", "knee", "ankle"),
#'       to = c("knee", "ankle", "toe"),
#'       length = c(2, 2, 1)
#'     )
#'   )
#' )
#' mask_na_segment_length(leg, min_difference = 0.5) |>
#'   dplyr::filter(time == 3)
#'
#' @seealso [anicore::as_anisegment()] for the lengths, and
#'   [anicore::set_structure()] to attach a structure. [mask_na_across()]
#'   for the criteria judged one track at a time.
#' @export
mask_na_segment_length <- function(
  data,
  structure = NULL,
  tolerance = 0.3,
  min_difference = 0,
  segments = NULL
) {
  ensure_segment_length_data(data)
  ensure_non_negative_scalar(tolerance, "tolerance")
  ensure_non_negative_scalar(min_difference, "min_difference")
  name <- resolve_length_structure(data, structure)
  struct <- anicore::get_structure(data, name)
  segments <- resolve_length_segments(struct, name, segments)

  variable <- struct$variable
  index <- anicore::get_index(data)
  by <- c(setdiff(anicore::get_keys(data), variable), index)

  judged <- judge_segment_lengths(
    data,
    name = name,
    struct = struct,
    segments = segments,
    by = by,
    index = index,
    tolerance = tolerance,
    min_difference = min_difference
  )
  if (!any(judged$.aniprocess_off)) {
    return(data)
  }

  masked <- blame_segment_points(judged, struct, by)

  # Match each row of `data` to the masked points by frame and point.
  rows <- as.data.frame(data)[c(by, variable)]
  rows[[variable]] <- as.character(rows[[variable]])
  hit <- !is.na(
    dplyr::left_join(rows, masked, by = c(by, variable))$.aniprocess_masked
  )

  for (col in unname(anicore::get_axes(data))) {
    data[[col]][hit] <- NA
  }
  if ("confidence" %in% names(data)) {
    data$confidence[hit] <- NA
  }
  data
}


#' Measure and judge each segment's length against its reference.
#'
#' @param data An anipoint.
#' @param name Name of the structure to use.
#' @param struct That structure.
#' @param segments Names of the segments to judge.
#' @param by The keys of a frame: the frame's keys other than the structure's
#'   variable, and its index.
#' @param index Name of the index column.
#' @param tolerance,min_difference The thresholds, as in
#'   [mask_na_segment_length()].
#'
#' @return A data frame of the measured segments, one row per segment and
#'   frame: the `by` columns, `segment`, `.aniprocess_frame` (an integer
#'   naming the frame) and `.aniprocess_off`.
#' @keywords internal
judge_segment_lengths <- function(
  data,
  name,
  struct,
  segments,
  by,
  index,
  tolerance,
  min_difference
) {
  lengths <- as.data.frame(anicore::as_anisegment(data, name))
  lengths <- lengths[lengths$segment %in% segments, c(by, "segment", "length")]
  lengths$segment <- as.character(lengths$segment)

  # The median is taken per track: each group of `as_anisegment()`.
  track <- c(setdiff(by, index), "segment")
  lengths <- dplyr::mutate(
    lengths,
    .aniprocess_median = stats::median(.data$length, na.rm = TRUE),
    .by = dplyr::all_of(track)
  )
  lengths <- dplyr::mutate(
    lengths,
    .aniprocess_frame = dplyr::cur_group_id(),
    .by = dplyr::all_of(by)
  )

  expected <- struct$segments$length[
    match(lengths$segment, struct$segments$segment)
  ]
  reference <- dplyr::coalesce(expected, lengths$.aniprocess_median)
  measured <- !is.na(lengths$length) & !is.na(reference) & reference > 0

  lengths <- lengths[measured, ]
  reference <- reference[measured]
  difference <- abs(lengths$length - reference)
  lengths$.aniprocess_off <- difference > tolerance * reference &
    difference > min_difference
  lengths
}


#' Find the points to blame for off segments.
#'
#' A point with two or more measured segments is to blame when all of them
#' are off. A point with one is to blame when it is off and the point at its
#' other end has another measured segment that is not off.
#'
#' @param judged The output of [judge_segment_lengths()].
#' @param struct The structure.
#' @param by The keys of a frame.
#'
#' @return A data frame of the masked points: the `by` columns, the
#'   structure's variable as character, and `.aniprocess_masked` (`TRUE`).
#' @keywords internal
blame_segment_points <- function(judged, struct, by) {
  points <- struct$points
  n_points <- length(points)
  at <- match(judged$segment, struct$segments$segment)
  from <- match(struct$segments$from[at], points)
  to <- match(struct$segments$to[at], points)

  # One row per end of each measured segment, keyed by frame and point.
  frame <- rep(judged$.aniprocess_frame, 2L)
  point <- (frame - 1) * n_points + c(from, to)
  other <- (frame - 1) * n_points + c(to, from)
  off <- rep(judged$.aniprocess_off, 2L)

  keys <- unique(point)
  id <- match(point, keys)
  other_id <- match(other, keys)
  n <- tabulate(id, length(keys))
  n_off <- tabulate(id[off], length(keys))

  all_off <- keys[n >= 2L & n_off == n]
  # The shared segment is off, so a segment of the other end that is not
  # off is another one. An isolated pair has none, and neither is blamed.
  end <- n[id] == 1L & off & n_off[other_id] < n[other_id]
  blamed <- unique(c(all_off, point[end]))

  frames <- judged[
    !duplicated(judged$.aniprocess_frame),
    c(by, ".aniprocess_frame")
  ]
  masked <- frames[
    match((blamed - 1) %/% n_points + 1, frames$.aniprocess_frame),
    by,
    drop = FALSE
  ]
  masked[[struct$variable]] <- points[(blamed - 1) %% n_points + 1]
  masked$.aniprocess_masked <- rep(TRUE, nrow(masked))
  masked
}


#' Validate the frame given to `mask_na_segment_length()`.
#'
#' @param data The value to validate.
#' @param call Environment used for the error's call context.
#'
#' @return Invisibly `NULL`. Called for side effects (errors).
#' @keywords internal
ensure_segment_length_data <- function(data, call = rlang::caller_env()) {
  if (!anicore::is_anipoint(data)) {
    cli::cli_abort(
      c(
        "{.arg data} must be an anipoint.",
        "i" = "Each point is judged by its neighbours, so this needs the whole frame rather than a frame of coordinates."
      ),
      call = call
    )
  }
  if (!anicore::is_cartesian_2d(data) && !anicore::is_cartesian_3d(data)) {
    cli::cli_abort(
      c(
        "{.arg data} must be in 2D or 3D Cartesian coordinates.",
        "i" = "Its coordinate system is {.val {anicore::get_coordinate_system(data)}}."
      ),
      call = call
    )
  }
  invisible(NULL)
}


#' Pick the structure whose segments are judged.
#'
#' Mirrors [anicore::as_anisegment()]: `structure` may be omitted when only
#' one structure has segments.
#'
#' @param data An anipoint.
#' @param structure Name of the structure, or `NULL`.
#' @param call Environment used for the error's call context.
#'
#' @return The structure's name.
#' @keywords internal
resolve_length_structure <- function(
  data,
  structure,
  call = rlang::caller_env()
) {
  structures <- anicore::get_structure(data)
  with_segments <- names(Filter(
    function(s) nrow(s$segments) > 0L,
    structures
  ))

  if (is.null(structure)) {
    if (length(with_segments) == 1L) {
      return(with_segments)
    }
    cli::cli_abort(
      if (length(with_segments) == 0L) {
        c(
          "{.arg data} has no structure with segments.",
          "i" = "Attach one with {.fn anicore::set_structure}."
        )
      } else {
        c(
          "{.arg data} has several structures with segments: {.val {with_segments}}.",
          "i" = "Name the one to use with {.arg structure}."
        )
      },
      call = call
    )
  }

  if (!is.character(structure) || length(structure) != 1L || is.na(structure)) {
    cli::cli_abort("{.arg structure} must be a single string.", call = call)
  }
  if (!structure %in% names(structures)) {
    cli::cli_abort(
      c(
        "There is no structure named {.val {structure}}.",
        "i" = if (length(structures) > 0L) {
          "Structures: {.val {names(structures)}}."
        } else {
          "{.arg data} has no structures."
        }
      ),
      call = call
    )
  }
  if (!structure %in% with_segments) {
    cli::cli_abort(
      "Structure {.val {structure}} has no segments.",
      call = call
    )
  }
  structure
}


#' Resolve the segments to judge.
#'
#' @param struct The structure.
#' @param name Its name, for errors.
#' @param segments Names of segments, or `NULL` for all of them.
#' @param call Environment used for the error's call context.
#'
#' @return A character vector of segment names.
#' @keywords internal
resolve_length_segments <- function(
  struct,
  name,
  segments,
  call = rlang::caller_env()
) {
  known <- struct$segments$segment
  if (is.null(segments)) {
    return(known)
  }
  if (!is.character(segments) || length(segments) == 0L || anyNA(segments)) {
    cli::cli_abort(
      "{.arg segments} must be a character vector of segment names.",
      call = call
    )
  }
  unknown <- setdiff(segments, known)
  if (length(unknown) > 0L) {
    cli::cli_abort(
      c(
        "Structure {.val {name}} has no segment{?s} {.val {unknown}}.",
        "i" = "Its segments: {.val {known}}."
      ),
      call = call
    )
  }
  unique(segments)
}
