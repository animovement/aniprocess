# Fill missing values across an aniframe's spatial columns

**\[experimental\]**

The aniframe-level entry point to the `replace_na_*()` family. Fills
gaps in the frame's declared position columns, within its existing
grouping — so a gap is never filled by interpolating between two
different tracks.

## Usage

``` r
replace_na_across(
  data,
  method = c("linear", "spline", "stine", "locf", "value"),
  variables = NULL,
  ...
)
```

## Arguments

- data:

  An aniframe.

- method:

  Character string specifying the replacement method:

  - `"linear"`: Linear interpolation (default)

  - `"spline"`: Spline interpolation for smoother curves

  - `"stine"`: Stineman interpolation preserving data shape

  - `"locf"`: Last observation carried forward

  - `"value"`: Replace with a constant value

- variables:

  Columns to fill, as a tidyselect expression. Defaults to the declared
  position columns.

- ...:

  Arguments passed to
  [`replace_na_with()`](https://animovement.dev/aniprocess/reference/replace_na_with.md),
  such as `value`, `min_gap` and `max_gap`.

## Value

An aniframe of the same shape, with gaps filled.

## See also

[`replace_na_with()`](https://animovement.dev/aniprocess/reference/replace_na_with.md)
for the vector-level generic.

## Examples

``` r
tracking_data <- anicore::example_anipoint()
tracking_data$x[c(2, 3, 10)] <- NA

replace_na_across(tracking_data, "linear", max_gap = 5)
#> # Individuals: 1, 2, 3
#> # Keypoints:   head, neck, shoulder_right, shoulder_left, abdomen, hip_right,
#> #   hip_left, knee_right, knee_left, foot_right, foot_left
#> # Sessions:    1
#> # Trials:      1
#>    individual keypoint session trial  time      x      y confidence
#>         <int> <fct>      <int> <int> <int>  <dbl>  <dbl>      <dbl>
#>  1          1 head           1     1     1 -1.87   0.819      0.702
#>  2          1 head           1     1     2 -1.71  -1.18       0.622
#>  3          1 head           1     1     3 -1.55  -1.86       0.659
#>  4          1 head           1     1     4 -1.39   0.457      0.658
#>  5          1 head           1     1     5 -0.781 -2.13       0.174
#>  6          1 head           1     1     6  0.617 -1.22       0.796
#>  7          1 head           1     1     7 -0.276 -2.15       0.735
#>  8          1 head           1     1     8  1.60  -1.30       0.796
#>  9          1 head           1     1     9 -0.150  0.276      0.806
#> 10          1 head           1     1    10  0.133  0.786      0.545
#> # ℹ 1,640 more rows
replace_na_across(tracking_data, "value", value = 0, variables = c(x, y))
#> # Individuals: 1, 2, 3
#> # Keypoints:   head, neck, shoulder_right, shoulder_left, abdomen, hip_right,
#> #   hip_left, knee_right, knee_left, foot_right, foot_left
#> # Sessions:    1
#> # Trials:      1
#>    individual keypoint session trial  time      x      y confidence
#>         <int> <fct>      <int> <int> <int>  <dbl>  <dbl>      <dbl>
#>  1          1 head           1     1     1 -1.87   0.819      0.702
#>  2          1 head           1     1     2  0     -1.18       0.622
#>  3          1 head           1     1     3  0     -1.86       0.659
#>  4          1 head           1     1     4 -1.39   0.457      0.658
#>  5          1 head           1     1     5 -0.781 -2.13       0.174
#>  6          1 head           1     1     6  0.617 -1.22       0.796
#>  7          1 head           1     1     7 -0.276 -2.15       0.735
#>  8          1 head           1     1     8  1.60  -1.30       0.796
#>  9          1 head           1     1     9 -0.150  0.276      0.806
#> 10          1 head           1     1    10  0      0.786      0.545
#> # ℹ 1,640 more rows
```
