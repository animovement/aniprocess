# Resolve a helper column named by an argument.

At the aniframe level a per-row argument such as `time` has to be a
column *name*, not a vector: each group needs its own slice, and a
whole-frame vector cannot be sliced by
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html).
The vector form belongs to the vector-level functions.

## Usage

``` r
helper_column(value, arg, generic, call = rlang::caller_env())
```

## Arguments

- value:

  The supplied argument, or `NULL`.

- arg:

  Argument name, for errors.

- generic:

  Name of the vector-level function, for the hint.

- call:

  Environment used for the error's call context.

## Value

A single column name, or `NULL`.
