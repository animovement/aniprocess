# Hampel mask for one group of coordinates.

Pads the series with `(window_width - 1) / 2` missing rows at each end,
so every row has a full centred window and positions beyond the series
count as missing. The rolling median comes from
[`filter_rollmedian()`](https://animovement.dev/aniprocess/reference/filter_rollmedian.md),
one axis at a time; the MAD is about that median, from a matrix holding
each row's window side by side.

## Usage

``` r
hampel_mask(coords, window_width, k, min_distance)
```

## Arguments

- coords:

  A data frame of the group's spatial columns.

- window_width:

  An odd whole number, at least 3 (default `5`): the number of rows in
  the window, centred on the point being judged. Up to
  `(window_width - 1) / 2` consecutive spike frames can be caught.

- k:

  A single non-negative number (default `3`): how many robust deviations
  a point may lie from the rolling median before it is masked.

- min_distance:

  A single non-negative number (default `0`), in the units of the
  coordinates: a floor on the threshold. A point that lies within
  `min_distance` of its rolling median is never masked, however small
  the spread of its window.

## Value

Logical vector of length `nrow(coords)`, `TRUE` on spikes.
