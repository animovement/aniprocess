# Fill missing values across an aniframe's spatial columns

**\[experimental\]**

The aniframe-level entry point to the `replace_na_*()` family. Fills
gaps in the columns given by the `variables_where` metadata field,
within the frame's existing grouping — so a gap is never filled by
interpolating between two different tracks.

## Usage

``` r
replace_na_across(
  data,
  method = c("linear", "spline", "stine", "locf", "value"),
  variables = NULL,
  ...
)
```

## Arguments

- data:

  An aniframe.

- method:

  Character string specifying the replacement method:

  - `"linear"`: Linear interpolation (default)

  - `"spline"`: Spline interpolation for smoother curves

  - `"stine"`: Stineman interpolation preserving data shape

  - `"locf"`: Last observation carried forward

  - `"value"`: Replace with a constant value

- variables:

  Columns to fill, as a tidyselect expression. Defaults to the
  `variables_where` metadata field.

- ...:

  Arguments passed to
  [`replace_na_with()`](http://animovement.dev/aniprocess/reference/replace_na_with.md),
  such as `value`, `min_gap` and `max_gap`.

## Value

An aniframe of the same shape, with gaps filled.

## See also

[`replace_na_with()`](http://animovement.dev/aniprocess/reference/replace_na_with.md)
for the vector-level generic.

## Examples

``` r
if (FALSE) { # \dontrun{
replace_na_across(tracking_data, "linear", max_gap = 5)
replace_na_across(tracking_data, "value", value = 0, variables = c(x, y))
} # }
```
