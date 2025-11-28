# Find Peaks in Time Series Data

Identifies peaks (local maxima) in a numeric time series, with options
to filter peaks based on height and prominence. The function handles
missing values (NA) appropriately and is compatible with dplyr's mutate.
Includes flexible handling of plateaus and adjustable window size for
peak detection.

## Usage

``` r
find_peaks(
  x,
  min_height = -Inf,
  min_prominence = 0,
  plateau_handling = c("strict", "middle", "first", "last", "all"),
  window_size = 3
)
```

## Arguments

- x:

  Numeric vector containing the time series data

- min_height:

  Minimum height threshold for peaks (default: -Inf)

- min_prominence:

  Minimum prominence threshold for peaks (default: 0)

- plateau_handling:

  String specifying how to handle plateaus. One of:

  - "strict" (default): No points in plateau are peaks

  - "middle": Middle point(s) of plateau are peaks

  - "first": First point of plateau is peak

  - "last": Last point of plateau is peak

  - "all": All points in plateau are peaks

- window_size:

  Integer specifying the size of the window to use for peak detection
  (default: 3). Must be odd and \>= 3. Larger values detect peaks over
  wider ranges.

## Value

A logical vector of the same length as the input where:

- `TRUE` indicates a confirmed peak

- `FALSE` indicates a non-peak

- `NA` indicates peak status could not be determined due to missing data

## Details

The function uses a sliding window algorithm for peak detection (window
size specified by window_size parameter), combined with a region-based
prominence calculation method similar to that described in Palshikar
(2009).

## Note

- The function is optimized for use with dplyr's mutate

- For noisy data, consider using a larger window_size or smoothing the
  series before peak detection

- Adjust min_height and min_prominence to filter out unwanted peaks

- Choose plateau_handling based on your specific needs

- Larger window_size values result in more stringent peak detection

## Peak Detection

A point is considered a peak if it is the highest point within its
window (default window_size of 3 compares each point with its immediate
neighbors). The first and last (window_size-1)/2 points in the series
cannot be peaks and are marked as NA. Larger window sizes will identify
peaks that dominate over a wider range, typically resulting in fewer
peaks being detected.

## Prominence

Prominence measures how much a peak stands out relative to its
surrounding values. It is calculated as the height of the peak minus the
height of the highest minimum between this peak and any higher peaks (or
the end of the series if no higher peaks exist).

## Plateau Handling

Plateaus (sequences of identical values) are handled according to the
plateau_handling parameter:

- strict: No points in a plateau are considered peaks (traditional
  behavior)

- middle: For plateaus of odd length, the middle point is marked as a
  peak. For plateaus of even length, the two middle points are marked as
  peaks.

- first: The first point of each plateau is marked as a peak

- last: The last point of each plateau is marked as a peak

- all: Every point in the plateau is marked as a peak

Note that in all cases, the plateau must still qualify as a peak
relative to its surrounding window (i.e., higher than all other points
in the window).

## Missing Values (NA) Handling

The function uses the following rules for handling NAs:

- If a point is NA, it cannot be a peak (returns NA)

- If any point in the window is NA, peak status cannot be determined
  (returns NA)

- For prominence calculations, stretches of NAs are handled
  appropriately

- A minimum of window_size points is required; shorter series return all
  NAs

## References

Palshikar, G. (2009). Simple Algorithms for Peak Detection in
Time-Series. Proc. 1st Int. Conf. Advanced Data Analysis, Business
Analytics and Intelligence.

## See also

- [`find_troughs`](http://animovement.dev/aniprocess/reference/find_troughs.md)
  for finding local minima

## Examples

``` r
# Basic usage with default window size (3)
x <- c(1, 3, 2, 6, 4, 5, 2)
find_peaks(x)
#> [1]    NA  TRUE FALSE  TRUE FALSE  TRUE    NA

# With larger window size
find_peaks(x, window_size = 5)  # More stringent peak detection
#> [1]    NA    NA FALSE  TRUE FALSE    NA    NA

# With minimum height
find_peaks(x, min_height = 4, window_size = 3)
#> [1]    NA FALSE FALSE  TRUE FALSE  TRUE    NA

# With plateau handling
x <- c(1, 3, 3, 3, 2, 4, 4, 1)
find_peaks(x, plateau_handling = "middle", window_size = 3)  # Middle of plateaus
#> [1]    NA FALSE  TRUE FALSE FALSE  TRUE  TRUE    NA
find_peaks(x, plateau_handling = "all", window_size = 5)     # All plateau points
#> [1]    NA    NA FALSE FALSE FALSE  TRUE  TRUE    NA

# With missing values
x <- c(1, 3, NA, 6, 4, NA, 2)
find_peaks(x)
#> [1] NA NA NA NA NA NA NA

# Usage with dplyr
library(dplyr)
#> 
#> Attaching package: ‘dplyr’
#> The following objects are masked from ‘package:stats’:
#> 
#>     filter, lag
#> The following objects are masked from ‘package:base’:
#> 
#>     intersect, setdiff, setequal, union
data_frame(
  time = 1:10,
  value = c(1, 3, 7, 4, 2, 6, 5, 8, 4, 2)
) %>%
  mutate(peaks = find_peaks(value, window_size = 3))
#> Warning: `data_frame()` was deprecated in tibble 1.1.0.
#> ℹ Please use `tibble()` instead.
#> # A tibble: 10 × 3
#>     time value peaks
#>    <int> <dbl> <lgl>
#>  1     1     1 NA   
#>  2     2     3 FALSE
#>  3     3     7 TRUE 
#>  4     4     4 FALSE
#>  5     5     2 FALSE
#>  6     6     6 TRUE 
#>  7     7     5 FALSE
#>  8     8     8 TRUE 
#>  9     9     4 FALSE
#> 10    10     2 NA   
```
