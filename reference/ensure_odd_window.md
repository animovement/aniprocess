# Validate a centred window width.

A window centred on a row needs as many rows on each side, so its width
is odd; and a width of 1 holds only the row itself.

## Usage

``` r
ensure_odd_window(window_width, call = rlang::caller_env())
```

## Arguments

- window_width:

  The value to validate.

- call:

  Environment used for the error's call context.

## Value

Invisibly `NULL`. Called for side effects (errors).
