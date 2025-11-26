# Replace Missing Values with a Constant Value

Replaces missing values with a specified constant value, with control
over both minimum and maximum gap sizes to fill.

## Usage

``` r
replace_na_value(x, value, min_gap = 1, max_gap = Inf)
```

## Arguments

- x:

  A vector containing numeric data with missing values (NAs)

- value:

  Numeric value to use for replacement

- min_gap:

  Integer specifying minimum gap size to fill. Gaps shorter than this
  will be left as NA. Default is 1 (fill all gaps).

- max_gap:

  Integer or Inf specifying maximum gap size to fill. Gaps longer than
  this will be left as NA. Default is Inf (no upper limit).

## Value

A numeric vector with NA values replaced by the specified value where
gap length criteria are met.

## Details

The function applies both minimum and maximum gap criteria:

- Gaps shorter than min_gap are left as NA

- Gaps longer than max_gap are left as NA

- Only gaps that meet both criteria are filled If both parameters are
  specified, min_gap must be less than or equal to max_gap.

## Examples

``` r
if (FALSE) { # \dontrun{
x <- c(1, NA, NA, 4, 5, NA, NA, NA, 9)
replace_na_value(x, value = 0)  # fills all gaps with 0
replace_na_value(x, value = -1, min_gap = 2)  # only gaps >= 2
replace_na_value(x, value = -999, max_gap = 2)  # only gaps <= 2
replace_na_value(x, value = 0, min_gap = 2, max_gap = 3)  # gaps between 2 and 3
} # }
```
