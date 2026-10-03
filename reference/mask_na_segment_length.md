# Mask points whose segments are far off their usual length

**\[experimental\]**

Finds the points of a structure that sit in the wrong place, from the
lengths of the segments joining them, and replaces their coordinates
with `NA`. A segment meant to be rigid — a long bone, the pelvis —
stretches or shrinks when one of its ends is wrong. Each segment is
compared with its usual length, and the point to blame is masked, not
the segment: a wrong ankle makes both shin and foot off while the thigh
is fine, so the ankle goes, and the knee and the toe stay.

This catches errors that confidence, speed and smoothing miss: a point
that sits wrong for many frames with a confident score, such as a match
in multi-camera 3D that several cameras happen to agree on.

Unlike the other `mask_na_*()` functions, it judges each point by its
neighbours, so it needs all of an individual's points at once. It takes
the whole anipoint rather than one track at a time, and is not a method
of
[`mask_na_across()`](https://animovement.dev/aniprocess/reference/mask_na_across.md).

## Usage

``` r
mask_na_segment_length(
  data,
  structure = NULL,
  tolerance = 0.3,
  min_difference = 0,
  segments = NULL
)
```

## Arguments

- data:

  An anipoint in 2D or 3D Cartesian coordinates, with a structure
  attached by
  [`anicore::set_structure()`](https://animovement.dev/anicore/reference/structures.html).

- structure:

  Name of the structure to use. May be omitted when only one structure
  has segments.

- tolerance:

  A single non-negative number (default `0.3`): how far a segment's
  length may differ from its reference, as a fraction of the reference,
  before it is off.

- min_difference:

  A single non-negative number (default `0`): how far a segment's length
  may differ from its reference, in the frame's spatial units, before it
  is off. A segment must exceed both this and `tolerance`, so this keeps
  a short segment from being off over a difference that is large only
  relative to its length.

- segments:

  Names of the segments to judge, as a character vector, or `NULL` (the
  default) for every segment of the structure. Choose those meant to be
  rigid: long bones and the pelvis, not the width of the shoulders or
  the neck. A point's segments are counted among these alone, so a point
  with one of them is an end point.

## Value

`data`, with every axis of each masked point set to `NA`, and its
`confidence` where present. Its rows, columns and metadata are
unchanged.

## Reference length

Each segment is compared with a reference length:

- its `length` in the structure (see
  [`anicore::anistructure()`](https://animovement.dev/anicore/reference/anistructure.html)),
  when the structure gives one, in the frame's spatial units;

- otherwise, the median of its non-missing lengths over the track:
  within each group of
  [`anicore::as_anisegment()`](https://animovement.dev/anicore/reference/as_anisegment.html),
  that is per segment and per combination of the keys other than the
  structure's variable — per individual, and per session or trial when
  `data` has them. Every time point counts towards it, including those
  where the segment turns out to be off; the median holds while they are
  fewer than half.

A segment with no `length` in the structure has no usable reference in a
track where its median is missing (its two ends are never present
together) or zero (they coincide in at least half the frames). It is not
judged in that track.

## When a segment is off

The lengths are those of
[`anicore::as_anisegment()`](https://animovement.dev/anicore/reference/as_anisegment.html):
the distance between the segment's two points in each frame. A segment
is off in a frame when its length `L` differs from its reference `R` by
more than both thresholds:

    abs(L - R) > tolerance * R  &  abs(L - R) > min_difference

A difference equal to a threshold is not off. With the default
`min_difference = 0`, `tolerance` alone decides.

A segment whose length is missing in a frame, because either end is `NA`
or has no row there, is not measured in that frame.

## Which point is to blame

Blame is decided frame by frame — at each time point of each individual,
and of each session or trial — from the segments measured in that frame.
Only the selected `segments` count.

- A point with two or more measured segments is masked when all of them
  are off.

- A point with one measured segment — an end point such as a toe or a
  nose, or a point whose other segments are missing in that frame — is
  masked when that segment is off and the point at its other end has
  another measured segment that is not off. That point is in place, so
  the fault is at this end. It is also what keeps a wrong ankle from
  taking the toe with it: the toe's one segment is the foot, and the
  ankle's other segment, the shin, is off as well.

- When neither end of an off segment has another measured segment,
  nothing tells which end is wrong, and neither is masked.

- A point with no measured segment is left alone, as is any level of the
  structure's variable that the selected segments do not reach.

It is one pass over the lengths as measured: masking a point does not
re-judge its neighbours. A correct point whose neighbours are all wrong
has every segment off, so it is masked along with them.

## What is masked

A masked point has every axis set to `NA`, and its `confidence` too
where the frame has that column, as
[`mask_na_across()`](https://animovement.dev/aniprocess/reference/mask_na_across.md)
does. A point that is already `NA`, in any axis, has no measured
segment, so it is not judged, and its neighbours are judged by their
other segments.

## See also

[`anicore::as_anisegment()`](https://animovement.dev/anicore/reference/as_anisegment.html)
for the lengths, and
[`anicore::set_structure()`](https://animovement.dev/anicore/reference/structures.html)
to attach a structure.
[`mask_na_across()`](https://animovement.dev/aniprocess/reference/mask_na_across.md)
for the criteria judged one track at a time.

## Examples

``` r
# A leg standing straight for five frames
leg <- anicore::anipoint(
  individual = 1,
  keypoint = rep(c("hip", "knee", "ankle", "toe"), each = 5),
  time = rep(1:5, times = 4),
  x = 0,
  y = rep(c(4, 2, 0, -1), each = 5),
  variables_what = c("individual", "keypoint"),
  index = "time",
  variables_where = c("x", "y")
)
leg <- anicore::set_structure(
  leg,
  anicore::anistructure(
    segments = data.frame(
      segment = c("thigh", "shin", "foot"),
      from = c("hip", "knee", "ankle"),
      to = c("knee", "ankle", "toe")
    )
  )
)

# In frame 3 the ankle is off to the side: shin and foot both stretch
leg$x[leg$keypoint == "ankle" & leg$time == 3] <- 2

# Only the ankle is masked, not the knee or the toe
mask_na_segment_length(leg) |>
  dplyr::filter(time == 3)
#> # Individuals: 1
#> # Keypoints:   ankle, hip, knee, toe
#>   individual keypoint  time     x     y
#>        <int> <fct>    <int> <dbl> <dbl>
#> 1          1 ankle        3    NA    NA
#> 2          1 hip          3     0     4
#> 3          1 knee         3     0     2
#> 4          1 toe          3     0    -1

# Judge thigh and shin alone: the ankle is now an end point, and goes
# because the knee's other segment, the thigh, is fine
mask_na_segment_length(leg, segments = c("thigh", "shin")) |>
  dplyr::filter(time == 3)
#> # Individuals: 1
#> # Keypoints:   ankle, hip, knee, toe
#>   individual keypoint  time     x     y
#>        <int> <fct>    <int> <dbl> <dbl>
#> 1          1 ankle        3    NA    NA
#> 2          1 hip          3     0     4
#> 3          1 knee         3     0     2
#> 4          1 toe          3     0    -1

# Expected lengths recorded in the structure are used instead of the median
leg <- anicore::set_structure(
  leg,
  anicore::anistructure(
    segments = data.frame(
      segment = c("thigh", "shin", "foot"),
      from = c("hip", "knee", "ankle"),
      to = c("knee", "ankle", "toe"),
      length = c(2, 2, 1)
    )
  )
)
mask_na_segment_length(leg, min_difference = 0.5) |>
  dplyr::filter(time == 3)
#> # Individuals: 1
#> # Keypoints:   ankle, hip, knee, toe
#>   individual keypoint  time     x     y
#>        <int> <fct>    <int> <dbl> <dbl>
#> 1          1 ankle        3    NA    NA
#> 2          1 hip          3     0     4
#> 3          1 knee         3     0     2
#> 4          1 toe          3     0    -1
```
