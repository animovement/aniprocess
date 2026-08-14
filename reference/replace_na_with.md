# Fill missing values by a named method

Generic entry point to the `replace_na_*()` family: pick the method with
an argument rather than by choosing a function.

## Usage

``` r
replace_na_with(
  x,
  method = c("linear", "spline", "stine", "locf", "value"),
  value = NULL,
  min_gap = 1,
  max_gap = Inf,
  ...
)
```

## Arguments

- x:

  A numeric vector, or a data frame of numeric columns, with missing
  values to fill.

- method:

  Character string specifying the replacement method:

  - `"linear"`: Linear interpolation (default)

  - `"spline"`: Spline interpolation for smoother curves

  - `"stine"`: Stineman interpolation preserving data shape

  - `"locf"`: Last observation carried forward

  - `"value"`: Replace with a constant value

- value:

  Numeric value for replacement when `method = "value"`.

- min_gap:

  Integer specifying the minimum gap size to fill. Gaps shorter than
  this are left as `NA`. Default `1` (fill all gaps).

- max_gap:

  Integer or `Inf` specifying the maximum gap size to fill. Gaps longer
  than this are left as `NA`. Default `Inf` (no limit).

- ...:

  Additional parameters passed to the underlying function.

## Value

The same shape as `x`, with gaps filled where the gap-length criteria
are met.

## Details

Returns the same shape it is given. Every method is univariate, so a
data frame is filled one column at a time — meaning this generic does
work with
[`dplyr::across()`](https://dplyr.tidyverse.org/reference/across.html)
as well as
[`dplyr::pick()`](https://dplyr.tidyverse.org/reference/pick.html).

## See also

[`filter_with()`](http://animovement.dev/aniprocess/reference/filter_with.md)
for smoothing,
[`filter_na_with()`](http://animovement.dev/aniprocess/reference/filter_na_with.md)
for masking.

## Examples

``` r
x <- c(1, NA, NA, 4, 5, NA, NA, NA, 9)

replace_na_with(x, "linear")
#> [1] 1 2 3 4 5 6 7 8 9
replace_na_with(x, "value", value = 0)
#> [1] 1 0 0 4 5 0 0 0 9
replace_na_with(x, "linear", max_gap = 2)
#> [1]  1  2  3  4  5 NA NA NA  9

# A frame is filled column by column
replace_na_with(data.frame(a = x, b = rev(x)), "locf")
#>   a b
#> 1 1 9
#> 2 1 9
#> 3 1 9
#> 4 4 9
#> 5 5 5
#> 6 5 4
#> 7 5 4
#> 8 5 4
#> 9 9 1
```
