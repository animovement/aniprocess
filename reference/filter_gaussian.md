# Apply Gaussian Kernel Smoother

Convolves a numeric vector with a discrete Gaussian kernel.

## Usage

``` r
filter_gaussian(x, sigma = 1, window_width = NULL, keep_na = TRUE)
```

## Arguments

- x:

  Numeric vector to filter.

- sigma:

  Standard deviation of the Gaussian kernel, in samples (frames). Must
  be positive.

- window_width:

  Integer kernel width in samples. Must be positive and is forced to be
  odd. Defaults to `2 * ceiling(3 * sigma) + 1`, which truncates the
  kernel at ±3σ.

- keep_na:

  Logical. If `TRUE` (default), positions that were `NA` in the input
  are `NA` in the output — gaps stay gaps. If `FALSE`, the values used
  to fill those gaps are kept, so the output has **fewer `NA`s than the
  input** and genuinely-missing stretches come back as interpolated
  estimates.

## Value

Filtered numeric vector, same length as `x`.

## Details

The kernel is symmetric and centered:
`weights[k] = dnorm(k, sd = sigma)` for `k` in `-half:half` (where
`half = (window_width - 1) / 2`), renormalised to sum to 1. The output
is the kernel-weighted moving average of `x`.

At each position, weights for kernel taps that would fall outside `x` or
that align with `NA` values are excluded, and the remaining weights are
renormalised. This means edges and isolated `NA`s are handled gracefully
without contaminating the result. A position whose entire window is `NA`
returns `NA`.

Larger `sigma` gives heavier smoothing. For movement data, typical
values range from `0.5` (very light smoothing) to `5` (heavy smoothing).

## Examples

``` r
x <- c(1, 2, 3, 100, 5, 6, 7)
filter_gaussian(x, sigma = 1)
#> [1]  2.127792  7.635157 26.352299 42.308827 28.325582 11.377478  7.088955
```
