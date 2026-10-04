# Mask spikes against a rolling median

**\[experimental\]**

Masks spikes — a point that jumps away for a frame or two and comes back
— by judging each point against its own neighbourhood, after Hampel. A
point is set to `NA` when its distance from the rolling median of the
window around it exceeds `k` robust deviations of that window. Because
both the median and the spread are local, the threshold follows the
movement: tight where the keypoint moves slowly, loose where it moves
fast — which a single threshold on speed or on position cannot be.

Unlike the classic Hampel filter, the point is masked rather than
replaced with the median, so it composes like the rest of the
`mask_na_*()` family: mask, then fill with
[`replace_na_with()`](https://animovement.dev/aniprocess/reference/replace_na_with.md).

## Usage

``` r
mask_na_hampel(data, window_width = 5, k = 3, min_distance = 0)
```

## Arguments

- data:

  A data frame of numeric coordinate columns — typically supplied by
  [`dplyr::pick()`](https://dplyr.tidyverse.org/reference/pick.html)
  inside
  [`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html).
  To mask a whole aniframe, use
  [`mask_na_across()`](https://animovement.dev/aniprocess/reference/mask_na_across.md).

- window_width:

  An odd whole number, at least 3 (default `5`): the number of rows in
  the window, centred on the point being judged. Up to
  `(window_width - 1) / 2` consecutive spike frames can be caught.

- k:

  A single non-negative number (default `3`): how many robust deviations
  a point may lie from the rolling median before it is masked.

- min_distance:

  A single non-negative number (default `0`), in the units of the
  coordinates: a floor on the threshold. A point that lies within
  `min_distance` of its rolling median is never masked, however small
  the spread of its window.

## Value

`data`, with every coordinate set to `NA` on rows judged to be spikes.

## Details

Each row is judged against the window of `window_width` rows centred on
it:

1.  The window's median position is taken axis by axis, with
    [`filter_rollmedian()`](https://animovement.dev/aniprocess/reference/filter_rollmedian.md).

2.  The row's deviation `d` is the Euclidean distance of its point from
    that median.

3.  The window's robust spread `S` is `1.4826` times the median of the
    distances of all the window's points from the same median: the
    median absolute deviation (MAD) of the window, scaled.

4.  The row is masked when `d > max(k * S, min_distance)`.

With one coordinate column this is the Hampel identifier of Pearson et
al. (2016). With several, the distance is Euclidean, so a point is
masked in all axes at once, and the axes should share a unit. The factor
1.4826 makes the MAD estimate the standard deviation of one-dimensional
Gaussian noise; a Euclidean distance in two or three dimensions is not
distributed that way, so there `k` is a multiple of the robust spread
rather than a number of standard deviations, and more conservative.

`min_distance` is what keeps a keypoint that barely moves from losing
its noise: there the MAD of a window can be tiny, or zero, and any
deviation at all exceeds `k` of it.

The spread is that of the window's points about the window's own median,
as in Pearson et al., so it includes the distance travelled within the
window. On steady motion a spike therefore has to reach several times
the per-frame step to be masked — about nine at the defaults — while on
a slow stretch the same settings catch spikes far smaller than the fast
stretch's steps. A spread taken instead over each point's distance to
its *own* rolling median is scaled by the noise rather than the motion,
and so is more sensitive on fast stretches; but it is exactly zero
wherever every axis moves monotonically through the window, so it flags
noise there unless `min_distance` is set.

Every row is judged against the original data in a single pass, so a
spike does not shift the verdict on its neighbours: the median and the
MAD both ignore up to `(window_width - 1) / 2` aberrant points in the
window. A run of spikes longer than that dominates the window and is not
caught — that is what
[`mask_na_excursion()`](https://animovement.dev/aniprocess/reference/mask_na_excursion.md)
is for.

### Missing values and edges

A row with any coordinate missing is neither judged nor used to judge
its neighbours: it is not a point, and is left as it is. A row is judged
only when a majority of its window — at least `(window_width + 1) / 2`
rows — holds complete points, which is also the fewest that leave a
spike in the minority. Positions beyond either end of the series count
as missing, so the first and last rows are judged against the part of
the window that exists, provided it is complete.

The window counts rows, not time, so rows are taken to be in temporal
order; on irregularly sampled data it spans a varying duration.

## Input shape

Takes and returns a frame of coordinate columns, so it composes inside
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html):

    data |> mutate(mask_na_hampel(pick(all_of(c("x", "y")))))

The deviation depends on all coordinates jointly, so this cannot be used
with
[`dplyr::across()`](https://dplyr.tidyverse.org/reference/across.html).
Every row of `data` is treated as one continuous track; called via
[`mask_na_across()`](https://animovement.dev/aniprocess/reference/mask_na_across.md),
or with
[`dplyr::pick()`](https://dplyr.tidyverse.org/reference/pick.html)
inside a grouped
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html),
a window never spans a track boundary. `confidence` is not a coordinate
and so is never modified here;
[`mask_na_across()`](https://animovement.dev/aniprocess/reference/mask_na_across.md)
blanks it on masked rows.

## References

Pearson, R. K., Neuvo, Y., Astola, J., & Gabbouj, M. (2016). Generalized
Hampel filters. *EURASIP Journal on Advances in Signal Processing*,
2016, 87.
[doi:10.1186/s13634-016-0383-6](https://doi.org/10.1186/s13634-016-0383-6)
.

## See also

[`mask_na_speed()`](https://animovement.dev/aniprocess/reference/mask_na_speed.md)
and
[`mask_na_excursion()`](https://animovement.dev/aniprocess/reference/mask_na_excursion.md),
which judge steps and excursions rather than deviations from a
neighbourhood;
[`filter_rollmedian()`](https://animovement.dev/aniprocess/reference/filter_rollmedian.md)
to smooth with the median instead.

## Examples

``` r
# One unit per frame, then twenty, with a 15-unit spike at row 4
coords <- data.frame(
  x = c(0, 1, 2, 3, 4, 5, 6, 26, 46, 66, 86, 106),
  y = c(0, 0, 0, 15, 0, 0, 0, 0, 0, 0, 0, 0)
)
mask_na_hampel(coords)
#>      x  y
#> 1    0  0
#> 2    1  0
#> 3    2  0
#> 4   NA NA
#> 5    4  0
#> 6    5  0
#> 7    6  0
#> 8   26  0
#> 9   46  0
#> 10  66  0
#> 11  86  0
#> 12 106  0

# A speed threshold low enough to catch the spike also takes the fast
# stretch, whose steps are larger than the spike
mask_na_speed(coords, threshold = 10, time = 1:12)
#>     x  y
#> 1   0  0
#> 2   1  0
#> 3   2  0
#> 4  NA NA
#> 5   4  0
#> 6   5  0
#> 7   6  0
#> 8  NA NA
#> 9  NA NA
#> 10 NA NA
#> 11 NA NA
#> 12 NA NA

# A keypoint that barely moves: without a floor, its noise is flagged
still <- data.frame(x = c(5, 5, 5.01, 5, 5, 5, 4.99, 5))
mask_na_hampel(still)
#>    x
#> 1  5
#> 2  5
#> 3 NA
#> 4  5
#> 5  5
#> 6  5
#> 7 NA
#> 8  5
mask_na_hampel(still, min_distance = 0.05)
#>      x
#> 1 5.00
#> 2 5.00
#> 3 5.01
#> 4 5.00
#> 5 5.00
#> 6 5.00
#> 7 4.99
#> 8 5.00
```
