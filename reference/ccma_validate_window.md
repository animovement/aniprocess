# Validate a CCMA window-width argument.

Ensures the value is a single positive integer; rounds even values up to
the next odd integer. Mirrors the convention used by
[`filter_gaussian()`](http://animovement.dev/aniprocess/reference/filter_gaussian.md).

## Usage

``` r
ccma_validate_window(arg_name, value)
```
