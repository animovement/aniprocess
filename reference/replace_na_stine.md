# Replace Missing Values Using Stineman Interpolation

Replaces missing values using Stineman interpolation, with control over
both minimum and maximum gap sizes to interpolate.

## Usage

``` r
replace_na_stine(x, min_gap = 1, max_gap = Inf, ...)
```

## Arguments

- x:

  A vector containing numeric data with missing values (NAs)

- min_gap:

  Integer specifying minimum gap size to interpolate. Gaps shorter than
  this will be left as NA. Default is 1 (interpolate all gaps).

- max_gap:

  Integer or Inf specifying maximum gap size to interpolate. Gaps longer
  than this will be left as NA. Default is Inf (no upper limit).

- ...:

  Additional parameters passed to stinepack::stinterp

## Value

A numeric vector with NA values replaced by interpolated values where
gap length criteria are met.

## Details

The function applies both minimum and maximum gap criteria:

- Gaps shorter than min_gap are left as NA

- Gaps longer than max_gap are left as NA

- Only gaps that meet both criteria are interpolated If both parameters
  are specified, min_gap must be less than or equal to max_gap.

Stineman interpolation is particularly good at preserving the shape of
the data and avoiding overshooting.

## Examples

``` r
if (FALSE) { # \dontrun{
x <- c(1, NA, NA, 4, 5, NA, NA, NA, 9)
replace_na_stine(x)  # interpolates all gaps
replace_na_stine(x, min_gap = 2)  # only gaps >= 2
replace_na_stine(x, max_gap = 2)  # only gaps <= 2
replace_na_stine(x, min_gap = 2, max_gap = 3)  # gaps between 2 and 3
} # }
```
