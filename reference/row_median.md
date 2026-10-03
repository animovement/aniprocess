# Median of each row of a matrix, ignoring `NA`.

Vectorised: sorts every row at once with a single
[`order()`](https://rdrr.io/r/base/order.html), rather than calling
[`stats::median()`](https://rdrr.io/r/stats/median.html) once per row.

## Usage

``` r
row_median(m)
```

## Arguments

- m:

  A numeric matrix.

## Value

A numeric vector with one value per row; `NA` for a row with no observed
values, whose first sorted value is itself `NA`.
