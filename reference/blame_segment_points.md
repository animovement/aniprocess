# Find the points to blame for off segments.

A point with two or more measured segments is to blame when all of them
are off. A point with one is to blame when it is off and the point at
its other end has another measured segment that is not off.

## Usage

``` r
blame_segment_points(judged, struct, by)
```

## Arguments

- judged:

  The output of
  [`judge_segment_lengths()`](https://animovement.dev/aniprocess/reference/judge_segment_lengths.md).

- struct:

  The structure.

- by:

  The keys of a frame.

## Value

A data frame of the masked points: the `by` columns, the structure's
variable as character, and `.aniprocess_masked` (`TRUE`).
