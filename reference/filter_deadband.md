# Apply a deadband filter

**\[experimental\]**

Holds a still subject still. The output stays where it is until the
tracked point has moved more than `threshold` away from it, so the small
wandering of tracking noise on a stationary point is removed entirely
rather than merely made smaller.

## Usage

``` r
filter_deadband(data, threshold, mode = c("hold", "drag"), max_gap = Inf)
```

## Arguments

- data:

  A data frame of numeric coordinate columns — typically supplied by
  [`dplyr::pick()`](https://dplyr.tidyverse.org/reference/pick.html)
  inside
  [`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html).
  To filter a whole aniframe, use
  [`filter_across()`](https://animovement.dev/aniprocess/reference/filter_across.md).

- threshold:

  A single non-negative number, in the units of the coordinates: how far
  the point has to move from the anchor before the output follows. `0`
  returns `data` unchanged.

- mode:

  How the output follows once the threshold is crossed: `"hold"`
  (default) jumps to the point, `"drag"` moves just far enough to bring
  the point back to the edge of the dead zone. See Details.

- max_gap:

  A whole number of rows, or `Inf` (default): the longest run of
  incomplete rows across which the anchor is kept. After a longer gap,
  the next complete row starts afresh.

## Value

A data frame with the same names and shape as `data`.

## Details

Tracking noise on a point that is not moving adds a little to its path
every frame, so distance travelled is overestimated — the more so the
longer the subject is still and the higher the sampling rate — and speed
never reaches zero. A smoother scales that noise down but does not
remove it. A deadband does: movement smaller than `threshold` is
ignored.

The output keeps an *anchor*, starting at the first complete row. For
each row, the distance from the anchor to the row's point is compared
with `threshold`. While it is at most `threshold`, the output is the
anchor. Once it is more, the anchor moves, in one of two ways:

- `"hold"` (default): the anchor jumps to the point. This is the
  "direct" *Minimal Distance Moved* of Noldus EthoVision XT, and the
  behaviour OptiTrack Motive describes for its rigid-body *Deadband
  Filter*, so results can be compared with theirs.

- `"drag"`: the anchor is pulled towards the point until it is exactly
  `threshold` away, as if on a lead of that length. This is the play
  (backlash) operator of hysteresis theory, in its vector form (Krejčí,
  1991). The output never jumps and trails the point by at most
  `threshold`, but sustained movement is shortened by `threshold` at
  each start and stop.

With several coordinate columns the distance is Euclidean, so the dead
zone is a circle or sphere: a move registers by its length, whatever its
direction. The axes should therefore share a unit, and be Cartesian.

### Choosing a threshold

`threshold` is in the units of the coordinates. It should exceed the
noise on a still point — a few times its standard deviation, measured on
a stretch where the subject is known to be still — and stay below the
smallest movement that matters. Smoothing first, for instance with
[`filter_lowpass()`](https://animovement.dev/aniprocess/reference/filter_lowpass.md),
lowers the noise and so lets the threshold be smaller.

### What it does to derivatives

A deadband is for distance travelled, immobility and bout detection, not
for kinematics. In `"hold"` mode the speed is zero while the anchor
holds and spikes when it jumps; in `"drag"` mode it is zero, then
continuous. Neither is the subject's real speed.

The filter is recursive and causal: each output depends on the rows
before it, so the result depends on where the series starts, and running
it backwards in time gives a different answer.

### Missing values

A row with any coordinate missing is not a point: it is left as it is,
and does not move the anchor. The next complete row is compared with the
anchor as it stood before the gap, so a subject that is in the same
place after a dropout stays exactly where it was. When a run of such
rows is longer than `max_gap`, the anchor is reset instead: the next
complete row is taken as it is, as at the start of the series.

## Input shape

This is a **column-level** function: it takes a data frame of coordinate
columns and returns one of the same shape. The aniframe tier is
[`filter_across()`](https://animovement.dev/aniprocess/reference/filter_across.md),
which applies it within the frame's existing grouping so each individual
/ track / keypoint is filtered as its own trajectory.

    filter_across(af, "deadband", threshold = 2)                       # a whole aniframe
    data |> mutate(filter_deadband(pick(all_of(c("x", "y"))), threshold = 2))  # the columns

The distance depends on all coordinates jointly, so this cannot be used
with
[`dplyr::across()`](https://dplyr.tidyverse.org/reference/across.html),
which passes one column at a time. For a single signal, pass a
one-column frame.

## References

OptiTrack. Properties Pane: Rigid Body — Deadband Filter. *Motive
documentation*.
<https://docs.optitrack.com/motive-ui-panes/properties-pane/properties-pane-rigid-body>

Noldus Information Technology. Smooth the tracks: Minimal Distance Moved
methods. *EthoVision XT 19 reference manual*.
<https://noldus.com/shared/resources/book/noldus-product-documentation/chapter/ethovision-xt/page/ethovision-xt-19-smooth-the-tracks-minimum-distance-moved-methods>

Hen, I., Sakov, A., Kafkafi, N., Golani, I., & Benjamini, Y. (2004). The
dynamics of spatial behavior: how can robust smoothing techniques help?
*Journal of Neuroscience Methods*, 133, 161–172.
[doi:10.1016/j.jneumeth.2003.10.013](https://doi.org/10.1016/j.jneumeth.2003.10.013)

Krasnosel'skiǐ, M. A., & Pokrovskiǐ, A. V. (1989). *Systems with
Hysteresis*. Springer.
[doi:10.1007/978-3-642-61302-9](https://doi.org/10.1007/978-3-642-61302-9)

Krejčí, P. (1991). Vector hysteresis models. *European Journal of
Applied Mathematics*, 2, 281–292.
[doi:10.1017/S0956792500000541](https://doi.org/10.1017/S0956792500000541)

## See also

[`filter_lowpass()`](https://animovement.dev/aniprocess/reference/filter_lowpass.md)
and
[`filter_one_euro()`](https://animovement.dev/aniprocess/reference/filter_one_euro.md),
which reduce noise rather than remove it, and work well before a
deadband.

## Examples

``` r
# A point that sits still with a little noise for 100 frames, then moves
# 10 units in 10 frames
set.seed(1)
coords <- data.frame(
  x = c(rep(0, 100), 1:10) + rnorm(110, sd = 0.05),
  y = rnorm(110, sd = 0.05)
)

# The still stretch comes out exactly still
held <- filter_deadband(coords, threshold = 0.2)
held[95:105, ]
#>               x            y
#> 95  -0.03716366 -0.016700042
#> 96  -0.03716366 -0.016700042
#> 97  -0.03716366 -0.016700042
#> 98  -0.03716366 -0.016700042
#> 99  -0.03716366 -0.016700042
#> 100 -0.03716366 -0.016700042
#> 101  0.96898167 -0.008218792
#> 102  2.00210579  0.021034732
#> 103  2.95445392 -0.020012337
#> 104  4.00790144 -0.068510394
#> 105  4.96727077  0.049391913

# So the noise no longer adds to the path length
path_length <- function(d) sum(sqrt(diff(d$x)^2 + diff(d$y)^2))
path_length(coords)
#> [1] 18.54119
path_length(held)
#> [1] 10.55844

# "drag" follows without jumping, at most `threshold` behind
filter_deadband(coords, threshold = 0.2, mode = "drag")[95:105, ]
#>               x           y
#> 95  -0.02332386 -0.02401083
#> 96  -0.02332386 -0.02401083
#> 97  -0.02332386 -0.02401083
#> 98  -0.02332386 -0.02401083
#> 99  -0.02332386 -0.02401083
#> 100 -0.02332386 -0.02401083
#> 101  0.76900699 -0.01140129
#> 102  1.80217495  0.01577566
#> 103  2.75455031 -0.01380364
#> 104  3.80809168 -0.05978902
#> 105  4.76815205  0.03063729

# The aniframe tier
af <- anicore::example_anipoint(n_obs = 60, n_individuals = 1, n_keypoints = 1)
filter_across(af, "deadband", threshold = 0.5)
#> # Individuals: 1
#> # Keypoints:   centroid
#> # Sessions:    1
#> # Trials:      1
#>    individual keypoint session trial  time        x      y confidence
#>         <int> <fct>      <int> <int> <int>    <dbl>  <dbl>      <dbl>
#>  1          1 centroid       1     1     1 -1.73    -2.26       0.627
#>  2          1 centroid       1     1     2  0.00213 -1.41       0.790
#>  3          1 centroid       1     1     3 -0.630    0.916      0.836
#>  4          1 centroid       1     1     4 -0.341   -0.191      0.818
#>  5          1 centroid       1     1     5 -1.16     0.803      0.876
#>  6          1 centroid       1     1     6  1.80     1.89       0.831
#>  7          1 centroid       1     1     7 -0.331    1.47       0.486
#>  8          1 centroid       1     1     8 -1.61     0.677      0.619
#>  9          1 centroid       1     1     9  0.197    0.380      0.469
#> 10          1 centroid       1     1    10  0.263   -0.193      0.787
#> # ℹ 50 more rows
```
