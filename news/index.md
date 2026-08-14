# Changelog

## aniprocess (development version)

### Breaking changes

- Filters no longer fill gaps by default. `keep_na` now defaults to
  `TRUE` in
  [`filter_sgolay()`](http://animovement.dev/aniprocess/reference/filter_sgolay.md),
  [`filter_lowpass()`](http://animovement.dev/aniprocess/reference/filter_lowpass.md),
  [`filter_highpass()`](http://animovement.dev/aniprocess/reference/filter_highpass.md),
  [`filter_lowpass_fft()`](http://animovement.dev/aniprocess/reference/filter_lowpass_fft.md),
  [`filter_highpass_fft()`](http://animovement.dev/aniprocess/reference/filter_highpass_fft.md)
  and
  [`filter_ccma()`](http://animovement.dev/aniprocess/reference/filter_ccma.md),
  so positions that were `NA` in the input are `NA` in the output.
  Previously the default was `FALSE`, which meant genuinely-missing
  stretches came back as smoothed interpolations with no indication that
  any interpolation had happened. Pass `keep_na = FALSE` for the old
  behaviour
  ([\#38](https://github.com/animovement/aniprocess/issues/38)).
- `keep_na` is now available on every filter.
  [`filter_gaussian()`](http://animovement.dev/aniprocess/reference/filter_gaussian.md),
  [`filter_rollmean()`](http://animovement.dev/aniprocess/reference/filter_rollmean.md),
  [`filter_rollmedian()`](http://animovement.dev/aniprocess/reference/filter_rollmedian.md)
  and
  [`filter_triangular()`](http://animovement.dev/aniprocess/reference/filter_triangular.md)
  gain the argument, defaulting to `TRUE`; they previously filled gaps —
  fully or partially — with no way to opt out
  ([\#38](https://github.com/animovement/aniprocess/issues/38)).
- [`filter_kalman()`](http://animovement.dev/aniprocess/reference/filter_kalman.md)
  and
  [`filter_kalman_irregular()`](http://animovement.dev/aniprocess/reference/filter_kalman_irregular.md)
  also gain `keep_na`, but default to `FALSE`. A Kalman filter’s predict
  step is designed to carry the state estimate through missing
  observations, so inferring across gaps is intended rather than
  accidental. Pass `keep_na = TRUE` to leave gaps as gaps
  ([\#38](https://github.com/animovement/aniprocess/issues/38)).

### New features

- `na_action` and `keep_na` are now documented from a single shared
  source, so the contract is stated identically across the filter family
  ([\#38](https://github.com/animovement/aniprocess/issues/38)).
- `keep_na` is validated: a non-logical, `NA`, or non-scalar value now
  aborts with a clear message rather than being silently coerced.

### Bug fixes

- [`filter_na_speed()`](http://animovement.dev/aniprocess/reference/filter_na_speed.md)
  now computes speed within each group of a grouped aniframe. It
  previously worked on the raw column vectors, so a step was formed
  between the last row of one track and the first row of the next. Where
  `time` restarts per track that step has a negative duration and yields
  a negative “speed”, which inflated the `"auto"` threshold and caused
  genuine outliers to be **missed** — how badly depended on how far
  apart the tracks happened to be. The cross-track step never produced
  false positives, because per-row speed is the minimum of the backward
  and forward step and a track boundary is one-sided
  ([\#37](https://github.com/animovement/aniprocess/issues/37)).
- [`filter_na_speed()`](http://animovement.dev/aniprocess/reference/filter_na_speed.md)
  no longer blanks rows belonging to groups shorter than two rows. Such
  a group has no step, so its speed is `NA`, and
  [`dplyr::if_else()`](https://dplyr.tidyverse.org/reference/if_else.html)
  propagates a missing condition
  ([\#37](https://github.com/animovement/aniprocess/issues/37)).

### Internal

- [`filter_na_speed()`](http://animovement.dev/aniprocess/reference/filter_na_speed.md),
  [`filter_na_excursion()`](http://animovement.dev/aniprocess/reference/filter_na_excursion.md)
  and
  [`filter_ccma()`](http://animovement.dev/aniprocess/reference/filter_ccma.md)
  all resolve groups through
  [`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
  and [`dplyr::pick()`](https://dplyr.tidyverse.org/reference/pick.html)
  rather than re-deriving row indices with
  [`dplyr::group_indices()`](https://dplyr.tidyverse.org/reference/group_data.html).
  Only
  [`filter_na_speed()`](http://animovement.dev/aniprocess/reference/filter_na_speed.md)
  changes behaviour; for the other two the output is unchanged, verified
  byte-for-byte against the previous implementation. The manual loops
  rescanned the group vector on every iteration — and in
  [`filter_ccma()`](http://animovement.dev/aniprocess/reference/filter_ccma.md)
  rebuilt the whole data frame — making them quadratic in group count.
  At 3,000 groups × 20 rows,
  [`filter_ccma()`](http://animovement.dev/aniprocess/reference/filter_ccma.md)
  goes from 47.8s to 5.9s and
  [`filter_na_excursion()`](http://animovement.dev/aniprocess/reference/filter_na_excursion.md)
  from 2.19s to 0.63s.
  [`filter_na_speed()`](http://animovement.dev/aniprocess/reference/filter_na_speed.md)
  becomes slower (0.02s to 0.31s) because it previously did no per-group
  work at all
  ([\#37](https://github.com/animovement/aniprocess/issues/37)).

- `calculate_speed_2d()` and `calculate_speed_3d()` are replaced by a
  single dimension-agnostic
  [`calculate_step_speed()`](http://animovement.dev/aniprocess/reference/calculate_step_speed.md),
  which sums the squared step over whatever coordinate columns it is
  given.

- The `data.table (>= 1.18.0)` requirement is now enforced when the
  package loads, not only when it is installed. Because the rolling
  filters reached `data.table` solely via `data.table::`, R had no
  namespace import to version-check, so an older `data.table` arriving
  after installation (conda, a stale `renv` lockfile, a manual
  downgrade) failed with `unused argument (partial = use_partial)` from
  inside
  [`filter_rollmean()`](http://animovement.dev/aniprocess/reference/filter_rollmean.md)
  rather than a version error naming `data.table`
  ([\#33](https://github.com/animovement/aniprocess/issues/33)).

## aniprocess 0.2.0

### New features

- New
  [`filter_ccma()`](http://animovement.dev/aniprocess/reference/filter_ccma.md):
  Curvature-Corrected Moving Average for 2D/3D Cartesian trajectories
  (Steinecker & Wuensche, 2023). Hanning and uniform kernels; padding
  boundary mode
  ([\#11](https://github.com/animovement/aniprocess/issues/11)).
- New
  [`filter_na_excursion()`](http://animovement.dev/aniprocess/reference/filter_na_excursion.md):
  flags multi-frame tracking excursions using the criterion from Todd,
  Kain & de Bivort (2017) — a jump that eventually returns counts as an
  outlier; a sustained shift does not
  ([\#13](https://github.com/animovement/aniprocess/issues/13)).
- New
  [`filter_gaussian()`](http://animovement.dev/aniprocess/reference/filter_gaussian.md):
  Gaussian kernel smoother with NA-aware weight renormalisation
  ([\#1](https://github.com/animovement/aniprocess/issues/1)).
- New
  [`filter_triangular()`](http://animovement.dev/aniprocess/reference/filter_triangular.md):
  triangular smoother as two passes of
  [`filter_rollmean()`](http://animovement.dev/aniprocess/reference/filter_rollmean.md)
  ([\#1](https://github.com/animovement/aniprocess/issues/1)).

### Bug fixes

- [`filter_lowpass_fft()`](http://animovement.dev/aniprocess/reference/filter_lowpass_fft.md)
  /
  [`filter_highpass_fft()`](http://animovement.dev/aniprocess/reference/filter_highpass_fft.md):
  fixed an asymmetric frequency-domain mask that halved the passband
  amplitude. Lowpass + highpass at the same cutoff now reconstruct the
  input exactly.
- [`filter_na_speed()`](http://animovement.dev/aniprocess/reference/filter_na_speed.md)
  now flags single-frame outliers correctly (the outlier itself is
  blanked, not its neighbours), and a single NA in the input no longer
  contaminates adjacent rows
  ([\#14](https://github.com/animovement/aniprocess/issues/14)).
- [`filter_aniframe()`](http://animovement.dev/aniprocess/reference/filter_aniframe.md)
  works on aniframes without an `individual` column. Identity columns
  now come from `variables_what`, spatial columns from `variables_where`
  ([\#16](https://github.com/animovement/aniprocess/issues/16)).
- [`find_peaks()`](http://animovement.dev/aniprocess/reference/find_peaks.md)
  /
  [`find_troughs()`](http://animovement.dev/aniprocess/reference/find_troughs.md):
  prominence now matches the documented topographic definition (saddle =
  max of left/right valley min). Previously could overestimate
  prominence and let peaks slip past `min_prominence`.
- [`filter_sgolay()`](http://animovement.dev/aniprocess/reference/filter_sgolay.md):
  `preserve_edges` had two bugs and is removed —
  [`signal::sgolayfilt()`](https://rdrr.io/pkg/signal/man/sgolayfilt.html)
  already handles edges correctly.
- [`filter_kalman()`](http://animovement.dev/aniprocess/reference/filter_kalman.md)
  documentation: corrected the default `base_Q` formula.
- [`replace_na_stine()`](http://animovement.dev/aniprocess/reference/replace_na_stine.md)
  and the inline installer in `filter_bandwidth.R` now point at the
  current r-universe
  ([\#17](https://github.com/animovement/aniprocess/issues/17)).

### Breaking changes

- [`filter_sgolay()`](http://animovement.dev/aniprocess/reference/filter_sgolay.md):
  dropped `preserve_edges`.
- [`filter_rollmean()`](http://animovement.dev/aniprocess/reference/filter_rollmean.md)
  /
  [`filter_rollmedian()`](http://animovement.dev/aniprocess/reference/filter_rollmedian.md):
  dropped `...`, gained an explicit `align` argument
  ([\#7](https://github.com/animovement/aniprocess/issues/7)).

### Dependencies

- `data.table (>= 1.18.0)` promoted from `Suggests` to `Imports` (now
  backs the rolling filters and the LOCF interpolation step).
- Removed `roll`, `collapse`, and `animetric`.

### Internal / housekeeping

- New helpers
  [`ensure_replace_na_args()`](http://animovement.dev/aniprocess/reference/ensure_replace_na_args.md)
  and
  [`ensure_aniframe_spatial()`](http://animovement.dev/aniprocess/reference/ensure_aniframe_spatial.md)
  replace duplicated input validation across the `replace_na_*()` and
  `filter_na_*()` families.
- `check_*()` helpers for optional packages consolidated, so the
  canonical r-universe URL lives in a single place.
- Three dead files removed; future work tracked in
  [\#29](https://github.com/animovement/aniprocess/issues/29)
  (`filter_by_pose`) and
  [\#30](https://github.com/animovement/aniprocess/issues/30) (an
  across-style API).
- Package now at 100% line coverage; `covr` added to `Suggests`.

## aniprocess 0.1.2

- Added a `NEWS.md` file to track changes to the package.
- Update to work with tidy movement logic.
- Use `differentiate` from *animetric* for `filter_na_speed`.
- `filter_na_roi` now works with 3D ROIs.
