# Validate the frame given to `mask_na_segment_length()`.

Validate the frame given to
[`mask_na_segment_length()`](https://animovement.dev/aniprocess/reference/mask_na_segment_length.md).

## Usage

``` r
ensure_segment_length_data(data, call = rlang::caller_env())
```

## Arguments

- data:

  The value to validate.

- call:

  Environment used for the error's call context.

## Value

Invisibly `NULL`. Called for side effects (errors).
