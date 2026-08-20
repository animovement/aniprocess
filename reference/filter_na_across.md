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
  ...,
  on_deltas = FALSE
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

- on_deltas:

  If `TRUE`, difference each column, mask the differences, and
  re-integrate from the original starting value — rejecting implausible
  single-window displacements rather than implausible positions. See
  *Masking on displacements* below.

  Only `"range"` accepts it. The others either already judge
  between-sample change, or are not about displacement at all, so
  differencing first would answer a different question than their name
  promises; they error rather than quietly compute it.

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

## Masking on displacements

`on_deltas` matters more here than it does for smoothing. Where the
coordinates are cumulative — trackball data, say, whose raw readings are
per-window displacements that were integrated with
[`cumsum()`](https://rdrr.io/r/base/cumsum.html) — masking a *position*
blanks the sample you flagged but leaves the spurious jump baked into
every subsequent position. Masking the *displacement* removes the bad
step itself, and everything downstream shifts back into place.

A masked step counts as no movement, and is restored as `NA` at its own
sample alone; the `NA` is not propagated forward. So the reading is
"this step is not believable", not "the animal's position is unknown
from here". The first sample of each group is never masked: it is the
starting point, and there is no step into it to judge.

## See also

[`filter_na_with()`](https://animovement.dev/aniprocess/reference/filter_na_with.md)
for the vector-level generic.

## Examples

``` r
if (FALSE) { # \dontrun{
# time comes from the aniframe's metadata
filter_na_across(tracking_data, "speed", threshold = "auto")

filter_na_across(tracking_data, "range", min_value = 0, max_value = 1920)

# trackball positions are integrated displacements: reject the step,
# not the position it left behind
filter_na_across(
  trackball_data,
  "range",
  min_value = -10,
  max_value = 10,
  on_deltas = TRUE
)
} # }
```
