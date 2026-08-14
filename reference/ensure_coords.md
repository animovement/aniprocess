# Validate a coordinate frame.

The vector-level form of the aniframe-aware filters accepts a data frame
of coordinate columns — typically supplied by
[`dplyr::pick()`](https://dplyr.tidyverse.org/reference/pick.html)
inside
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html).
This checks that it is a data frame with at least one column and that
every column is numeric.

## Usage

``` r
ensure_coords(coords, arg = "data", call = rlang::caller_env())
```

## Arguments

- coords:

  The value to validate.

- arg:

  Argument name to use in error messages.

- call:

  Environment used for the error's call context.

## Value

Invisibly `NULL`. Called for side effects (errors).
