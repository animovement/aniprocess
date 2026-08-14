# Wrap a filter so it acts on differences rather than on levels.

Differences the column, filters the differences, then re-integrates from
the original starting value — so with a filter that does nothing, the
round trip returns the input unchanged.

## Usage

``` r
derivative_wrapper(fn)
```

## Arguments

- fn:

  The filter to wrap.

## Value

A function with the same interface as `fn`.

## Details

A `NA` among the filtered differences is treated as no movement for the
purpose of accumulation, and restored as `NA` at its own position, so
one missing step does not blank the rest of the series.
