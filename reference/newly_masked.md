# Which rows did a masking call newly blank?

A masker blanks every selected column on a flagged row, so a row is
newly masked when all of them are `NA` afterwards but were not before.

## Usage

``` r
newly_masked(before, after, variables)
```

## Arguments

- before, after:

  The aniframe on either side of the call.

- variables:

  Columns that were masked.

## Value

A logical vector, one value per row.
