# Resolve which columns an `*_across()` verb should operate on.

Defaults to the columns named by the `variables_where` metadata field. A
tidyselect expression overrides that.

## Usage

``` r
resolve_variables(data, variables, call = rlang::caller_env())
```

## Arguments

- data:

  An aniframe.

- variables:

  A tidyselect expression, already defused, or `NULL`.

- call:

  Environment used for the error's call context.

## Value

A character vector of column names.
