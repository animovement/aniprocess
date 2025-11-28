# Find Troughs in Time Series Data

Identifies troughs (local minima) in a numeric time series, with options
to filter troughs based on height and prominence. The function handles
missing values (NA) appropriately and is compatible with dplyr's mutate.
Includes flexible handling of plateaus and adjustable window size for
trough detection.

## Usage

``` r
find_troughs(
  x,
  max_height = Inf,
  min_prominence = 0,
  plateau_handling = c("strict", "middle", "first", "last", "all"),
  window_size = 3
)
```

## Arguments

- x:

  Numeric vector containing the time series data

- max_height:

  Maximum height threshold for troughs (default: Inf)

- min_prominence:

  Minimum prominence threshold for troughs (default: 0)

- plateau_handling:

  String specifying how to handle plateaus. One of:

  - "strict" (default): No points in plateau are troughs

  - "middle": Middle point(s) of plateau are troughs

  - "first": First point of plateau is trough

  - "last": Last point of plateau is trough

  - "all": All points in plateau are troughs

- window_size:

  Integer specifying the size of the window to use for trough detection
  (default: 3). Must be odd and \>= 3. Larger values detect troughs over
  wider ranges.

## Value

A logical vector of the same length as the input where:

- `TRUE` indicates a confirmed trough

- `FALSE` indicates a non-trough

- `NA` indicates trough status could not be determined due to missing
  data

## Details

The function uses a sliding window algorithm for trough detection
(window size specified by window_size parameter), combined with a
region-based prominence calculation method similar to that described in
Palshikar (2009).

## Note

- The function is optimized for use with dplyr's mutate

- For noisy data, consider using a larger window_size or smoothing the
  series before trough detection

- Adjust max_height and min_prominence to filter out unwanted troughs

- Choose plateau_handling based on your specific needs

- Larger window_size values result in more stringent trough detection

## Trough Detection

A point is considered a trough if it is the lowest point within its
window (default window_size of 3 compares each point with its immediate
neighbors). The first and last (window_size-1)/2 points in the series
cannot be troughs and are marked as NA. Larger window sizes will
identify troughs that dominate over a wider range, typically resulting
in fewer troughs being detected.

## Prominence

Prominence measures how much a trough stands out relative to its
surrounding values. It is calculated as the height of the lowest maximum
between this trough and any lower troughs (or the end of the series if
no lower troughs exist) minus the height of the trough.

## Plateau Handling

Plateaus (sequences of identical values) are handled according to the
plateau_handling parameter:

- strict: No points in a plateau are considered troughs (traditional
  behavior)

- middle: For plateaus of odd length, the middle point is marked as a
  trough. For plateaus of even length, the two middle points are marked
  as troughs.

- first: The first point of each plateau is marked as a trough

- last: The last point of each plateau is marked as a trough

- all: Every point in the plateau is marked as a trough

Note that in all cases, the plateau must still qualify as a trough
relative to its surrounding window (i.e., lower than all other points in
the window).

## Missing Values (NA) Handling

The function uses the following rules for handling NAs:

- If a point is NA, it cannot be a trough (returns NA)

- If any point in the window is NA, trough status cannot be determined
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

- [`find_peaks`](http://animovement.dev/aniprocess/reference/find_peaks.md)
  for finding local maxima

## Examples

``` r
# Basic usage with default window size (3)
x <- c(5, 3, 4, 1, 4, 2, 5)
find_troughs(x)
#> [1]    NA  TRUE FALSE  TRUE FALSE  TRUE    NA

# With larger window size
find_troughs(x, window_size = 5)  # More stringent trough detection
#> [1]    NA    NA FALSE  TRUE FALSE    NA    NA

# With maximum height
find_troughs(x, max_height = 3, window_size = 3)
#> [1]    NA FALSE FALSE  TRUE FALSE  TRUE    NA

# With plateau handling
x <- c(5, 2, 2, 2, 3, 1, 1, 4)
find_troughs(x, plateau_handling = "middle", window_size = 3)  # Middle of plateaus
#> [1]    NA FALSE  TRUE FALSE FALSE  TRUE  TRUE    NA
find_troughs(x, plateau_handling = "all", window_size = 5)     # All plateau points
#> [1]    NA    NA FALSE FALSE FALSE  TRUE  TRUE    NA

# With missing values
x <- c(5, 3, NA, 1, 4, NA, 5)
find_troughs(x)
#> [1] NA NA NA NA NA NA NA

# Usage with dplyr
library(dplyr)
data_frame(
  time = 1:10,
  value = c(5, 3, 1, 4, 2, 1, 3, 0, 4, 5)
) %>%
  mutate(troughs = find_troughs(value, window_size = 3))
#> # A tibble: 10 × 3
#>     time value troughs
#>    <int> <dbl> <lgl>  
#>  1     1     5 NA     
#>  2     2     3 FALSE  
#>  3     3     1 TRUE   
#>  4     4     4 FALSE  
#>  5     5     2 FALSE  
#>  6     6     1 TRUE   
#>  7     7     3 FALSE  
#>  8     8     0 TRUE   
#>  9     9     4 FALSE  
#> 10    10     5 NA     
```
