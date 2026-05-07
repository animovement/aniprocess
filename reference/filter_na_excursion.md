# Filter Out Position Excursions That Return

Flags multi-frame tracking errors as `NA` using the criterion from Todd,
Kain & de Bivort (2017): a frame-to-frame jump of more than `outlier_sd`
standard deviations starts an excursion, which is then rejected if (and
only if) the trajectory eventually returns either close to the
pre-excursion position or close to the overall median position.

## Usage

``` r
filter_na_excursion(data, outlier_sd = 5, return_sd = 1, by_axis = TRUE)
```

## Arguments

- data:

  An aniframe.

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
  [`filter_na_speed()`](http://animovement.dev/aniprocess/reference/filter_na_speed.md)).

## Value

An aniframe of the same shape, with flagged rows blanked.

## Details

For each spatial coordinate listed in the metadata field
`variables_where` (and within each existing aniframe group), the
algorithm:

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

Spatial columns and `confidence` (if present) are set to `NA` at flagged
rows, matching the convention used by
[`filter_na_speed()`](http://animovement.dev/aniprocess/reference/filter_na_speed.md).

## References

Todd, J. G., Kain, J. S., & de Bivort, B. L. (2017). Systematic
exploration of unsupervised methods for mapping behavior. *Physical
Biology*, 14(1), 015002.
[doi:10.1088/1478-3975/14/1/015002](https://doi.org/10.1088/1478-3975/14/1/015002)
.

## See also

[`filter_na_speed()`](http://animovement.dev/aniprocess/reference/filter_na_speed.md)
for single-frame outliers.

## Examples

``` r
if (FALSE) { # \dontrun{
# Default Todd thresholds, per-axis.
filter_na_excursion(tracking_data)

# Joint Euclidean variant, looser thresholds.
filter_na_excursion(tracking_data, outlier_sd = 4, by_axis = FALSE)
} # }
```
