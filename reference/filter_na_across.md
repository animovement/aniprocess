# Mask values to NA across an aniframe's spatial columns

**\[experimental\]**

The aniframe-level entry point to the `filter_na_*()` family. Applies a
named criterion to the columns given by the `variables_where` metadata
field, within the frame's existing grouping — so a criterion is never
evaluated across a track boundary.

## Usage

``` r
filter_na_across(
  data,
  method = c("range", "speed", "excursion", "roi", "confidence"),
  variables = NULL,
  ...
)
```

## Arguments

- data:

  An aniframe.

- method:

  Criterion to apply. One of `"range"`, `"speed"`, `"excursion"`,
  `"roi"` or `"confidence"`.

- variables:

  Columns to mask, as a tidyselect expression. Defaults to the
  `variables_where` metadata field.

- ...:

  Arguments passed to the underlying function.

  For `"speed"`, `threshold` additionally accepts `"pooled"`: `"auto"`
  estimates a threshold separately for each group, so every track is
  judged against its own noise; `"pooled"` estimates one threshold from
  all groups at once, which is steadier when tracks are short.

## Value

An aniframe of the same shape, with failing values replaced by `NA`.

## Details

Beyond looping over columns, it fills in what the frame already knows:
`"speed"` takes its `time` from the column named by `variables_when`,
and `"confidence"` takes its `confidence` from the column of that name.
Either can be passed explicitly to override.

Only `"range"` is univariate. The others decide per row using all the
selected columns at once, and blank every one of them on a flagged row.

Where a `confidence` column is present, it is blanked on rows that this
call masked — the cross-column effect that the vector-level functions
cannot perform, since `confidence` is not a coordinate.

## See also

[`filter_na_with()`](http://animovement.dev/aniprocess/reference/filter_na_with.md)
for the vector-level generic.

## Examples

``` r
if (FALSE) { # \dontrun{
# time comes from the aniframe's metadata
filter_na_across(tracking_data, "speed", threshold = "auto")

filter_na_across(tracking_data, "range", min_value = 0, max_value = 1920)
} # }
```
