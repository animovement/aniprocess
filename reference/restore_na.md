# Restore NAs to their original positions after filtering

The counterpart to
[`prepare_na()`](http://animovement.dev/aniprocess/reference/prepare_na.md),
and also usable on its own by filters that never fill (they infer
through gaps, or handle `NA` natively) but should still honour
`keep_na`.

## Usage

``` r
restore_na(result, na_positions, keep_na)
```

## Arguments

- result:

  Filter output, the same shape as the original input.

- na_positions:

  Logical vector or matrix from
  [`prepare_na()`](http://animovement.dev/aniprocess/reference/prepare_na.md),
  or from [`is.na()`](https://rdrr.io/r/base/NA.html) on the original
  input.

- keep_na:

  Logical. When `FALSE`, `result` is returned untouched.

## Value

`result`, with `NA` written back at `na_positions` when `keep_na` is
`TRUE`.
