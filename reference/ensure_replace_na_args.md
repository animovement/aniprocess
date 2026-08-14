# Validate the common arguments shared by `replace_na_*()` functions.

Aborts on a non-numeric `x`, `min_gap < 1`, or `max_gap < min_gap`. Used
at the start of every `replace_na_*()` function so the same messages and
behaviour apply consistently when those functions are called directly
(rather than via
[`replace_na_with()`](http://animovement.dev/aniprocess/reference/replace_na_with.md)).

## Usage

``` r
ensure_replace_na_args(x, min_gap, max_gap)
```

## Arguments

- x:

  The numeric input to validate.

- min_gap, max_gap:

  Gap-size thresholds.

## Value

Invisibly `NULL`. Called for side effects (errors).
