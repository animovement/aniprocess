# Mask position excursions that return

Flags multi-frame tracking errors as `NA` using the criterion from Todd,
Kain & de Bivort (2017): a frame-to-frame jump of more than `outlier_sd`
standard deviations starts an excursion, which is then rejected if (and
only if) the trajectory eventually returns either close to the
pre-excursion position or close to the overall median position.

## Usage

``` r
mask_na_excursion(data, outlier_sd = 5, return_sd = 1, by_axis = TRUE)
```

## Arguments

- data:

  A data frame of numeric coordinate columns — typically supplied by
  [`dplyr::pick()`](https://dplyr.tidyverse.org/reference/pick.html)
  inside
  [`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html).
  To mask a whole aniframe, use
  [`mask_na_across()`](https://animovement.dev/aniprocess/reference/mask_na_across.md).

- outlier_sd:

  Threshold (in standard deviations) for flagging frame-to-frame jumps
  and for the "return to pre-excursion position" acceptance check.
  Todd's default is `5`.

- return_sd:

  Threshold (in standard deviations) for the "return to overall median
  position" acceptance check. Todd's default is `1`.

- by_axis:

  Logical. If `TRUE` (the default), Todd's literal per-axis behaviour is
  used: each spatial column has its own σ, median, and excursion state
  machine, and a row is blanked if any axis flags it. If `FALSE`, a
  single state machine runs on the joint Euclidean displacement
  (consistent with
  [`mask_na_speed()`](https://animovement.dev/aniprocess/reference/mask_na_speed.md)).

## Value

`data`, with flagged rows blanked.

## Details

For each coordinate column, the algorithm:

1.  Computes the standard deviation `σ` of the coordinate over the full
    series and the overall median `m`.

2.  Walks the series. When a frame-to-frame change exceeds
    `outlier_sd * σ`, an excursion starts: that frame is flagged and
    subsequent frames are flagged until the position is either within
    `outlier_sd * σ` of its pre-excursion value, or within
    `return_sd * σ` of the overall median. The first such frame is
    accepted (not flagged), and the state machine resets.

This distinguishes transient excursions (a tracking glitch where the
position eventually comes back) from sustained shifts (the animal
genuinely moved to a new region) — the latter never satisfy the return
condition unless the new region happens to be near the median, in which
case it is accepted via the second criterion.

Every coordinate column is set to `NA` at a flagged row. `confidence` is
not a coordinate and so is never modified here;
[`mask_na_across()`](https://animovement.dev/aniprocess/reference/mask_na_across.md)
blanks it too.

## References

Todd, J. G., Kain, J. S., & de Bivort, B. L. (2017). Systematic
exploration of unsupervised methods for mapping behavior. *Physical
Biology*, 14(1), 015002.
[doi:10.1088/1478-3975/14/1/015002](https://doi.org/10.1088/1478-3975/14/1/015002)
.

## See also

[`mask_na_speed()`](https://animovement.dev/aniprocess/reference/mask_na_speed.md)
for single-frame outliers.

## Examples

``` r
# A two-frame glitch: x jumps away at row 41 and returns at row 43
coords <- data.frame(
  x = c(rep(0:1, 20), 50, 50, rep(0:1, 19)),
  y = rep(0:1, 40)
)

# Default Todd thresholds, per-axis.
mask_na_excursion(coords)
#>     x  y
#> 1   0  0
#> 2   1  1
#> 3   0  0
#> 4   1  1
#> 5   0  0
#> 6   1  1
#> 7   0  0
#> 8   1  1
#> 9   0  0
#> 10  1  1
#> 11  0  0
#> 12  1  1
#> 13  0  0
#> 14  1  1
#> 15  0  0
#> 16  1  1
#> 17  0  0
#> 18  1  1
#> 19  0  0
#> 20  1  1
#> 21  0  0
#> 22  1  1
#> 23  0  0
#> 24  1  1
#> 25  0  0
#> 26  1  1
#> 27  0  0
#> 28  1  1
#> 29  0  0
#> 30  1  1
#> 31  0  0
#> 32  1  1
#> 33  0  0
#> 34  1  1
#> 35  0  0
#> 36  1  1
#> 37  0  0
#> 38  1  1
#> 39  0  0
#> 40  1  1
#> 41 NA NA
#> 42 NA NA
#> 43  0  0
#> 44  1  1
#> 45  0  0
#> 46  1  1
#> 47  0  0
#> 48  1  1
#> 49  0  0
#> 50  1  1
#> 51  0  0
#> 52  1  1
#> 53  0  0
#> 54  1  1
#> 55  0  0
#> 56  1  1
#> 57  0  0
#> 58  1  1
#> 59  0  0
#> 60  1  1
#> 61  0  0
#> 62  1  1
#> 63  0  0
#> 64  1  1
#> 65  0  0
#> 66  1  1
#> 67  0  0
#> 68  1  1
#> 69  0  0
#> 70  1  1
#> 71  0  0
#> 72  1  1
#> 73  0  0
#> 74  1  1
#> 75  0  0
#> 76  1  1
#> 77  0  0
#> 78  1  1
#> 79  0  0
#> 80  1  1

# Joint Euclidean variant, looser thresholds.
mask_na_excursion(coords, outlier_sd = 4, by_axis = FALSE)
#>     x  y
#> 1   0  0
#> 2   1  1
#> 3   0  0
#> 4   1  1
#> 5   0  0
#> 6   1  1
#> 7   0  0
#> 8   1  1
#> 9   0  0
#> 10  1  1
#> 11  0  0
#> 12  1  1
#> 13  0  0
#> 14  1  1
#> 15  0  0
#> 16  1  1
#> 17  0  0
#> 18  1  1
#> 19  0  0
#> 20  1  1
#> 21  0  0
#> 22  1  1
#> 23  0  0
#> 24  1  1
#> 25  0  0
#> 26  1  1
#> 27  0  0
#> 28  1  1
#> 29  0  0
#> 30  1  1
#> 31  0  0
#> 32  1  1
#> 33  0  0
#> 34  1  1
#> 35  0  0
#> 36  1  1
#> 37  0  0
#> 38  1  1
#> 39  0  0
#> 40  1  1
#> 41 NA NA
#> 42 NA NA
#> 43  0  0
#> 44  1  1
#> 45  0  0
#> 46  1  1
#> 47  0  0
#> 48  1  1
#> 49  0  0
#> 50  1  1
#> 51  0  0
#> 52  1  1
#> 53  0  0
#> 54  1  1
#> 55  0  0
#> 56  1  1
#> 57  0  0
#> 58  1  1
#> 59  0  0
#> 60  1  1
#> 61  0  0
#> 62  1  1
#> 63  0  0
#> 64  1  1
#> 65  0  0
#> 66  1  1
#> 67  0  0
#> 68  1  1
#> 69  0  0
#> 70  1  1
#> 71  0  0
#> 72  1  1
#> 73  0  0
#> 74  1  1
#> 75  0  0
#> 76  1  1
#> 77  0  0
#> 78  1  1
#> 79  0  0
#> 80  1  1
```
