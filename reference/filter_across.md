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
    "highpass", "lowpass_fft", "highpass_fft", "kalman", "kalman_irregular", "one_euro",
    "ccma"),
  variables = NULL,
  ...,
  on_deltas = FALSE
)
```

## Arguments

- data:

  An aniframe.

- method:

  Filter to apply. One of `"gaussian"`, `"rollmean"`, `"rollmedian"`,
  `"triangular"`, `"sgolay"`, `"lowpass"`, `"highpass"`,
  `"lowpass_fft"`, `"highpass_fft"`, `"kalman"`, `"kalman_irregular"`,
  `"one_euro"` or `"ccma"`.

- variables:

  Columns to filter, as a tidyselect expression. Defaults to the
  `variables_where` metadata field.

- ...:

  Arguments passed to the underlying filter.

- on_deltas:

  If `TRUE`, difference each column, filter the differences, and
  re-integrate from the original starting value. For trackball data,
  where the raw measurements are per-frame displacements and the
  coordinates were integrated from them, smoothing belongs on the
  displacements rather than on the integrated positions.

  A `NA` among the filtered differences counts as no movement when
  accumulating, and is restored as `NA` at its own position, so one
  missing step does not blank the rest of the series.

## Value

An aniframe of the same shape, with the selected columns filtered.

## Details

This is the aniframe tier of the interface:

- [`filter_gaussian()`](https://animovement.dev/aniprocess/reference/filter_gaussian.md)
  and friends filter one vector — use them inside
  [`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html).

- [`filter_with()`](https://animovement.dev/aniprocess/reference/filter_with.md)
  does the same but picks the method by name.

- `filter_across()` applies a method to a whole aniframe.

Beyond looping over columns, it fills in what the frame already knows:
`sampling_rate` comes from metadata for the methods that need it, and
`"kalman_irregular"` takes its `times` from the column named by
`variables_when`. Either can still be passed explicitly to override.

`"ccma"` is multivariate — each output coordinate depends on all of them
— so it is applied jointly rather than column by column.

## See also

[`filter_with()`](https://animovement.dev/aniprocess/reference/filter_with.md)
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
