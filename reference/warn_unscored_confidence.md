# Warn that rows without a confidence score were left unmasked.

Raised once per call: by
[`mask_na_confidence()`](https://animovement.dev/aniprocess/reference/mask_na_confidence.md)
when called on its own, and by
[`mask_na_across()`](https://animovement.dev/aniprocess/reference/mask_na_across.md)
for the whole frame, which keeps it from being repeated per group and
wrapped in
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)'s
context.

## Usage

``` r
warn_unscored_confidence(n)
```

## Arguments

- n:

  Number of unscored rows that were left unmasked.

## Value

Invisibly `NULL`. Called for its side effect.
