# Pick the structure whose segments are judged.

Mirrors
[`anicore::as_anisegment()`](https://animovement.dev/anicore/reference/as_anisegment.html):
`structure` may be omitted when only one structure has segments.

## Usage

``` r
resolve_length_structure(data, structure, call = rlang::caller_env())
```

## Arguments

- data:

  An anipoint.

- structure:

  Name of the structure, or `NULL`.

- call:

  Environment used for the error's call context.

## Value

The structure's name.
