# Apply Rolling Mean Filter

Applies a rolling mean filter to a numeric vector using the roll
package.

## Usage

``` r
filter_rollmean(x, window_width = 5, min_obs = 1, ...)
```

## Arguments

- x:

  Numeric vector to filter

- window_width:

  Integer specifying window size for rolling calculation

- min_obs:

  Minimum number of non-NA values required (default: 1)

- ...:

  Additional parameters to be passed to
  [`roll::roll_mean()`](https://rdrr.io/pkg/roll/man/roll_mean.html)

## Value

Filtered numeric vector
