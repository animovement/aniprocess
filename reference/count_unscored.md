# Count the unscored rows that masking could still change.

A row with no confidence score only matters if it has a coordinate left
to mask; one whose coordinates are already all `NA` is the same either
way.

## Usage

``` r
count_unscored(data, confidence, variables = names(data))
```

## Arguments

- data:

  A data frame holding the coordinate columns.

- confidence:

  Numeric vector of confidence values, one per row.

- variables:

  Names of the coordinate columns in `data`.

## Value

A single integer.
