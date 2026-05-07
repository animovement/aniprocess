# Curvature-correction reconstruction step.

Implements steps 2–5 of the CCMA algorithm: compute curvature vectors,
alpha angles, normalised MA radii, and shift each MA point outward to
undo the corner-cutting bias.

## Usage

``` r
ccma_correct(P_ma, w_ma, w_cc, weights_ma, weights_cc)
```

## Arguments

- P_ma:

  Moving-average-smoothed trajectory (matrix, 3 columns).

- w_ma, w_cc:

  Half-widths of the MA and CC kernels.

- weights_ma, weights_cc:

  Kernel weight vectors.

## Value

Corrected trajectory (matrix, 3 columns) with
`nrow = nrow(P_ma) - 2 * (w_ma + w_cc + 1)` rows.
