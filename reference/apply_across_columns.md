# Apply a per-column function across one group's columns.

Called inside
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
with [`dplyr::pick()`](https://dplyr.tidyverse.org/reference/pick.html),
so `cols` holds one group's rows. Returns a frame of just `variables`,
which mutate splices back over them.

## Usage

``` r
apply_across_columns(cols, variables, fn, args = list(), helpers = list())
```

## Arguments

- cols:

  A data frame of the group's columns: `variables` plus any helper
  column the method needs.

- variables:

  Names of the columns to transform.

- fn:

  Function applied to each column.

- args:

  Additional arguments for `fn`.

- helpers:

  Named list mapping an argument name to a column name in `cols`,
  supplied per group (e.g. `list(times = "time")`).

## Value

A data frame with the `variables` columns transformed.
