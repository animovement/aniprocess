# Deprecated `filter_na_*()` functions

**\[deprecated\]**

The NA-masking functions are now called `mask_na_*()`: they set bad
values to `NA` and keep every row, which `filter_` suggested they did
not. Each old name forwards to its replacement unchanged.

- `filter_na_across()` →
  [`mask_na_across()`](https://animovement.dev/aniprocess/reference/mask_na_across.md)

- `filter_na_with()` →
  [`mask_na_with()`](https://animovement.dev/aniprocess/reference/mask_na_with.md)

- `filter_na_confidence()` →
  [`mask_na_confidence()`](https://animovement.dev/aniprocess/reference/mask_na_confidence.md)

- `filter_na_excursion()` →
  [`mask_na_excursion()`](https://animovement.dev/aniprocess/reference/mask_na_excursion.md)

- `filter_na_range()` →
  [`mask_na_range()`](https://animovement.dev/aniprocess/reference/mask_na_range.md)

- `filter_na_roi()` →
  [`mask_na_roi()`](https://animovement.dev/aniprocess/reference/mask_na_roi.md)

- `filter_na_speed()` →
  [`mask_na_speed()`](https://animovement.dev/aniprocess/reference/mask_na_speed.md)

## Usage

``` r
filter_na_across(
  data,
  method = c("range", "speed", "excursion", "hampel", "roi", "confidence"),
  variables = NULL,
  ...,
  on_deltas = FALSE
)

filter_na_with(
  x,
  method = c("range", "speed", "excursion", "hampel", "roi", "confidence"),
  ...
)

filter_na_confidence(data, threshold = 0.6, confidence = NULL)

filter_na_excursion(data, outlier_sd = 5, return_sd = 1, by_axis = TRUE)

filter_na_range(x, min_value = -Inf, max_value = Inf)

filter_na_roi(
  data,
  x_min = NULL,
  x_max = NULL,
  y_min = NULL,
  y_max = NULL,
  z_min = NULL,
  z_max = NULL,
  x_center = NULL,
  y_center = NULL,
  z_center = NULL,
  radius = NULL
)

filter_na_speed(data, threshold = "auto", time = NULL)
```

## Arguments

- data, x, method, variables, ..., on_deltas, threshold, confidence,
  outlier_sd, return_sd, by_axis, min_value, max_value, x_min, x_max,
  y_min, y_max, z_min, z_max, x_center, y_center, z_center, radius,
  time:

  See the replacement.

## Value

What the replacement returns.
