# Validate aniframe spatial readiness.

Consolidates the input validation that every aniframe-aware filter has
to do before touching the spatial coordinates: the input must be an
aniframe, every column named in the metadata field `variables_where`
must be present, and each must be numeric.

## Usage

``` r
ensure_aniframe_spatial(data)
```

## Arguments

- data:

  An aniframe.

## Value

`data`, invisibly.

## Details

Aborts with a granular error message identifying which condition failed;
otherwise returns `data` invisibly.
