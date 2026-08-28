# Positions to interpolate against

Row position by default, the index values when the caller supplies them.
On a regularly sampled frame the two are proportional and agree; on an
irregular one they do not, and row position silently places an imputed
value at the wrong moment (#67).

## Usage

``` r
interpolation_positions(x, times = NULL)
```

## Arguments

- x:

  The vector being filled.

- times:

  Index values, or `NULL` for row position.

## Value

Numeric vector the same length as `x`.
