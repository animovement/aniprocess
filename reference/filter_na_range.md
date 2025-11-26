# Filter values outside a range to NA

Replaces values in a numeric vector that fall outside the specified
range with NA. Values already NA in the input remain NA.

## Usage

``` r
filter_na_range(x, min = -Inf, max = Inf)
```

## Arguments

- x:

  A numeric vector to filter

- min:

  Minimum value (inclusive). Values below this become NA. Default is
  -Inf (no lower bound).

- max:

  Maximum value (inclusive). Values above this become NA. Default is Inf
  (no upper bound).

## Value

A numeric vector the same length as `x` with out-of-range values
replaced by NA

## Examples

``` r
filter_na_range(c(1, 5, 10, 15), min = 3, max = 12)
#> [1] NA  5 10 NA
# Returns: c(NA, 5, 10, NA)

filter_na_range(c(1, NA, 10), min = 5)
#> [1] NA NA 10
# Returns: c(NA, NA, 10)
```
