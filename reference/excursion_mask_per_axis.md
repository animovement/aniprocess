# Per-axis excursion state machine.

Returns a logical vector (length `length(rows)`) with `TRUE` at rows
where any spatial axis is currently inside an excursion run.

## Usage

``` r
excursion_mask_per_axis(data, rows, variables_where, outlier_sd, return_sd)
```
