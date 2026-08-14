# Exponential smoothing factor for a cutoff frequency.

`alpha = 1 / (1 + tau/dt)` with `tau = 1 / (2 * pi * cutoff)`, written
in the algebraically equivalent form used by the reference
implementation.

## Usage

``` r
one_euro_alpha(dt, cutoff)
```

## Arguments

- dt:

  Time step in seconds.

- cutoff:

  Cutoff frequency in Hz.

## Value

A smoothing factor in `(0, 1)`.
