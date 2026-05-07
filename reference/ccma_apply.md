# Apply CCMA to a single trajectory.

Operates on the `n × d` coordinate matrix of one group. Lifts 2D to 3D
internally; the original returns 2D output for 2D input. Boundary mode
`"padding"` extends endpoints so that output length equals input length.

## Usage

``` r
ccma_apply(P, w_ma, w_cc, kernel, boundary, cc_mode)
```

## Arguments

- P:

  Numeric matrix `n × d` with `d %in% c(2, 3)`.

- w_ma:

  Half-width of the moving-average kernel.

- w_cc:

  Half-width of the curvature-correction kernel.

- kernel:

  One of `"hanning"`, `"uniform"`.

- boundary:

  Currently only `"padding"`.

- cc_mode:

  If `FALSE`, return the moving-average result without curvature
  correction.

## Value

Numeric matrix the same shape as `P`.
