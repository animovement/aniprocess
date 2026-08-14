# Wrap a filter so it acts on differences rather than on levels.

Differences the column, filters the differences, then re-integrates.

## Usage

``` r
derivative_wrapper(fn)
```

## Arguments

- fn:

  The filter to wrap.

## Value

A function with the same interface as `fn`.
