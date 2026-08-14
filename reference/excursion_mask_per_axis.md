# Per-axis excursion state machine.

Returns a logical vector (length `nrow(coords)`) with `TRUE` at rows
where any spatial axis is currently inside an excursion run.

## Usage

``` r
excursion_mask_per_axis(coords, outlier_sd, return_sd)
```
