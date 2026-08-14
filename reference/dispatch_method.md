# Dispatch a method name to its implementation.

Shared machinery for the `*_with()` generics. Applies the
shape-preserving contract: a vector in gives a vector out, a frame of
coordinate columns gives a frame out.

## Usage

``` r
dispatch_method(
  x,
  method,
  fn,
  multivariate,
  generic,
  ...,
  call = rlang::caller_env()
)
```

## Arguments

- x:

  A numeric vector or a data frame of coordinate columns.

- method:

  The resolved method name.

- fn:

  The function implementing `method`.

- multivariate:

  `TRUE` if `method` needs all coordinates at once.

- generic:

  Name of the calling generic, for error messages.

- ...:

  Passed on to `fn`.

- call:

  Environment used for the error's call context.

## Value

The same shape as `x`.

## Details

Univariate methods are applied column-wise when given a frame.
Multivariate methods — where each result depends on all coordinates
jointly — require a frame, and say so when handed a bare vector.
