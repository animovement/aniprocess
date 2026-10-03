# Resolve the segments to judge.

Resolve the segments to judge.

## Usage

``` r
resolve_length_segments(struct, name, segments, call = rlang::caller_env())
```

## Arguments

- struct:

  The structure.

- name:

  Its name, for errors.

- segments:

  Names of segments, or `NULL` for all of them.

- call:

  Environment used for the error's call context.

## Value

A character vector of segment names.
