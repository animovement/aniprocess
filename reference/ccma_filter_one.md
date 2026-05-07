# Apply CCMA to one trajectory, with NA pre-handling.

Wraps
[`ccma_apply()`](http://animovement.dev/aniprocess/reference/ccma_apply.md)
with `replace_na`-based interpolation of `NA`s before filtering and
optional restoration after.

## Usage

``` r
ccma_filter_one(
  P,
  w_ma,
  w_cc,
  kernel,
  boundary,
  cc_mode,
  na_action,
  keep_na,
  replace_na_args
)
```
