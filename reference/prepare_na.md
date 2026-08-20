# Record and fill NA positions before filtering

Captures where the `NA`s are, then fills them via
[`replace_na_with()`](https://animovement.dev/aniprocess/reference/replace_na_with.md)
so the filter receives a complete series. Pair with
[`restore_na()`](https://animovement.dev/aniprocess/reference/restore_na.md)
to put the gaps back afterwards.

## Usage

``` r
prepare_na(x, na_action, replace_na_args = list(), call = rlang::caller_env())
```

## Arguments

- x:

  Numeric vector or matrix.

- na_action:

  One of the
  [`replace_na_with()`](https://animovement.dev/aniprocess/reference/replace_na_with.md)
  methods, or `"error"`.

- replace_na_args:

  Named list of extra arguments for
  [`replace_na_with()`](https://animovement.dev/aniprocess/reference/replace_na_with.md),
  typically `list(...)` from the calling filter.

- call:

  Environment used for the error's call context.

## Value

A list with `x` (the filled input) and `na_positions` (a logical vector
or matrix, matching the shape of `x`, marking the original `NA`s).

## Details

Accepts a numeric vector or a numeric matrix; a matrix is filled
column-wise, since interpolating down a column is meaningful whereas
interpolating across coordinates is not.
