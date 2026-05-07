# Per-column valid-mode correlation (kernel symmetry assumed).

Output length = `nrow(P) - length(weights) + 1`.

## Usage

``` r
ccma_convolve_valid(P, weights)
```

## Arguments

- P:

  Numeric matrix.

- weights:

  Numeric vector (kernel).

## Value

Numeric matrix with the same number of columns as `P`.
