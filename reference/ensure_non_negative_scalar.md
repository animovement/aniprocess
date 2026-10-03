# Validate a single non-negative number.

Validate a single non-negative number.

## Usage

``` r
ensure_non_negative_scalar(value, arg, call = rlang::caller_env())
```

## Arguments

- value:

  The value to validate.

- arg:

  Argument name to use in the error message.

- call:

  Environment used for the error's call context.

## Value

Invisibly `NULL`. Called for side effects (errors).
