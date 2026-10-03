# Measure and judge each segment's length against its reference.

Measure and judge each segment's length against its reference.

## Usage

``` r
judge_segment_lengths(
  data,
  name,
  struct,
  segments,
  by,
  index,
  tolerance,
  min_difference
)
```

## Arguments

- data:

  An anipoint.

- name:

  Name of the structure to use.

- struct:

  That structure.

- segments:

  Names of the segments to judge.

- by:

  The keys of a frame: the frame's keys other than the structure's
  variable, and its index.

- index:

  Name of the index column.

- tolerance, min_difference:

  The thresholds, as in
  [`filter_na_segment_length()`](https://animovement.dev/aniprocess/reference/filter_na_segment_length.md).

## Value

A data frame of the measured segments, one row per segment and frame:
the `by` columns, `segment`, `.aniprocess_frame` (an integer naming the
frame) and `.aniprocess_off`.
