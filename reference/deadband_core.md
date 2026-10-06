# The deadband recursion.

Rows with any `NA` are left as they are and do not move the anchor; a
run of them longer than `max_gap` clears it.

## Usage

``` r
deadband_core(points, threshold, drag, max_gap)
```

## Arguments

- points:

  Numeric matrix, one row per sample.

- threshold:

  Dead-zone radius.

- drag:

  `TRUE` for the play operator, `FALSE` to jump.

- max_gap:

  Longest run of incomplete rows that keeps the anchor.

## Value

Numeric matrix of the same shape as `points`.
