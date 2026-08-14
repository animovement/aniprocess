# Apply a filter across an aniframe's spatial columns

**\[experimental\]**

The aniframe-level entry point to the `filter_*()` family. Applies a
named filter to the columns given by the `variables_where` metadata
field, within the frame's existing grouping.

## Usage

``` r
filter_across(
  data,
  method = c("gaussian", "rollmean", "rollmedian", "triangular", "sgolay", "lowpass",
    "highpass", "lowpass_fft", "highpass_fft", "kalman", "kalman_irregular", "ccma"),
  variables = NULL,
  ...,
  use_derivatives = FALSE
)
```

## Arguments

- data:

  An aniframe.

- method:

  Filter to apply. One of `"gaussian"`, `"rollmean"`, `"rollmedian"`,
  `"triangular"`, `"sgolay"`, `"lowpass"`, `"highpass"`,
  `"lowpass_fft"`, `"highpass_fft"`, `"kalman"`, `"kalman_irregular"` or
  `"ccma"`.

- variables:

  Columns to filter, as a tidyselect expression. Defaults to the
  `variables_where` metadata field.

- ...:

  Arguments passed to the underlying filter.

- use_derivatives:

  If `TRUE`, difference each column, filter the differences, and
  re-integrate. For trackball data, where the raw measurements are
  per-frame displacements and the coordinates were integrated from them,
  smoothing belongs on the displacements.

## Value

An aniframe of the same shape, with the selected columns filtered.

## Details

This is the aniframe tier of the interface:

- [`filter_gaussian()`](http://animovement.dev/aniprocess/reference/filter_gaussian.md)
  and friends filter one vector — use them inside
  [`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html).

- [`filter_with()`](http://animovement.dev/aniprocess/reference/filter_with.md)
  does the same but picks the method by name.

- `filter_across()` applies a method to a whole aniframe.

Beyond looping over columns, it fills in what the frame already knows:
`sampling_rate` comes from metadata for the methods that need it, and
`"kalman_irregular"` takes its `times` from the column named by
`variables_when`. Either can still be passed explicitly to override.

`"ccma"` is multivariate — each output coordinate depends on all of them
— so it is applied jointly rather than column by column.

## See also

[`filter_with()`](http://animovement.dev/aniprocess/reference/filter_with.md)
for the vector-level generic.

## Examples

``` r
if (FALSE) { # \dontrun{
# sampling_rate is taken from the aniframe's metadata
filter_across(tracking_data, "lowpass", cutoff_freq = 5)

# restrict to some of the spatial columns
filter_across(tracking_data, "gaussian", variables = c(x, y), sigma = 2)
} # }
```
