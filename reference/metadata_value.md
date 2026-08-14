# Look up a required parameter from aniframe metadata.

The frame already knows its sampling rate and which column holds time,
so an `*_across()` verb should not make the caller repeat them.

## Usage

``` r
metadata_value(data, field, what, call = rlang::caller_env())
```

## Arguments

- data:

  An aniframe.

- field:

  Metadata field to read.

- what:

  Human-readable name of the parameter, for errors.

- call:

  Environment used for the error's call context.

## Value

The metadata value.
