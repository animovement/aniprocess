# Mask values to NA across an aniframe's spatial columns

**\[experimental\]**

The aniframe-level entry point to the `mask_na_*()` family. Applies a
named criterion to the frame's declared position columns, within its
existing grouping — so a criterion is never evaluated across a track
boundary.

## Usage

``` r
mask_na_across(
  data,
  method = c("range", "speed", "excursion", "hampel", "roi", "confidence"),
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
  `"hampel"`, `"roi"` or `"confidence"`.

- variables:

  Columns to mask, as a tidyselect expression. Defaults to the declared
  position columns.

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

  Only `"range"` accepts it. The others either already judge a sample
  against its neighbours, or are not about displacement at all, so
  differencing first would answer a different question than their name
  promises; they error rather than quietly compute it.

## Value

An aniframe of the same shape, with failing values replaced by `NA`.

## Details

Beyond looping over columns, it fills in what the frame already knows:
`"speed"` takes its `time` from the index column
([`anicore::get_index()`](https://animovement.dev/anicore/reference/get_index.html)),
and `"confidence"` takes its `confidence` from the column of that name.
Either can be passed explicitly to override. For `"confidence"`, the
warning about rows with no score is given once for the whole frame, not
once per group; see
[`mask_na_confidence()`](https://animovement.dev/aniprocess/reference/mask_na_confidence.md)
for `missing`.

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

[`mask_na_with()`](https://animovement.dev/aniprocess/reference/mask_na_with.md)
for the vector-level generic.

## Examples

``` r
tracking_data <- anicore::example_anipoint()

# time comes from the aniframe's metadata
mask_na_across(tracking_data, "speed", threshold = "auto")
#> # Individuals: 1, 2, 3
#> # Keypoints:   head, neck, shoulder_right, shoulder_left, abdomen, hip_right,
#> #   hip_left, knee_right, knee_left, foot_right, foot_left
#> # Sessions:    1
#> # Trials:      1
#>    individual keypoint session trial  time      x      y confidence
#>         <int> <fct>      <int> <int> <int>  <dbl>  <dbl>      <dbl>
#>  1          1 head           1     1     1  0.933  0.574      0.912
#>  2          1 head           1     1     2  0.303  1.34       0.685
#>  3          1 head           1     1     3 -1.96  -0.461      0.908
#>  4          1 head           1     1     4  0.354 -0.192      0.912
#>  5          1 head           1     1     5  0.450 -2.08       0.951
#>  6          1 head           1     1     6  0.660 -1.91       0.832
#>  7          1 head           1     1     7 -1.03   1.41       0.801
#>  8          1 head           1     1     8 -2.37   0.528      0.463
#>  9          1 head           1     1     9 -0.325  0.644      0.820
#> 10          1 head           1     1    10 -0.944  0.901      0.425
#> # ℹ 1,640 more rows

mask_na_across(tracking_data, "range", min_value = -2, max_value = 2)
#> # Individuals: 1, 2, 3
#> # Keypoints:   head, neck, shoulder_right, shoulder_left, abdomen, hip_right,
#> #   hip_left, knee_right, knee_left, foot_right, foot_left
#> # Sessions:    1
#> # Trials:      1
#>    individual keypoint session trial  time      x      y confidence
#>         <int> <fct>      <int> <int> <int>  <dbl>  <dbl>      <dbl>
#>  1          1 head           1     1     1  0.933  0.574      0.912
#>  2          1 head           1     1     2  0.303  1.34       0.685
#>  3          1 head           1     1     3 -1.96  -0.461      0.908
#>  4          1 head           1     1     4  0.354 -0.192      0.912
#>  5          1 head           1     1     5  0.450 NA          0.951
#>  6          1 head           1     1     6  0.660 -1.91       0.832
#>  7          1 head           1     1     7 -1.03   1.41       0.801
#>  8          1 head           1     1     8 NA      0.528      0.463
#>  9          1 head           1     1     9 -0.325  0.644      0.820
#> 10          1 head           1     1    10 -0.944  0.901      0.425
#> # ℹ 1,640 more rows

# trackball positions are integrated displacements: reject the step,
# not the position it left behind
trackball_data <- anicore::as_anipoint(data.frame(
  time = 1:8,
  x = cumsum(c(0, 1, 1, 1, 50, 1, 1, 1)),
  y = cumsum(c(0, 1, 1, 1, 1, 1, 1, 1))
))
mask_na_across(
  trackball_data,
  "range",
  min_value = -10,
  max_value = 10,
  on_deltas = TRUE
)
#> # Keypoints: centroid
#>   keypoint  time     x     y
#>   <fct>    <int> <dbl> <dbl>
#> 1 centroid     1     0     0
#> 2 centroid     2     1     1
#> 3 centroid     3     2     2
#> 4 centroid     4     3     3
#> 5 centroid     5    NA     4
#> 6 centroid     6     4     5
#> 7 centroid     7     5     6
#> 8 centroid     8     6     7
```
