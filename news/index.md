# Changelog

## aniprocess (development version)

### Changed

- The core data structures come from `anicore`, which is what the
  `aniframe` package was renamed to in its 0.8.0
  (animovement/anicore#84). The `aniframe` class keeps its name; only
  the package providing it changed, so `anicore` replaces `aniframe` in
  `Imports` and in every `aniframe::` call.

## aniprocess 0.4.0 (2026-08-18)

### Added

- [`filter_na_across()`](https://animovement.dev/aniprocess/reference/filter_na_across.md)
  gains `on_deltas`, matching
  [`filter_across()`](https://animovement.dev/aniprocess/reference/filter_across.md):
  it differences each column, masks the differences, and re-integrates
  from the original starting value
  ([\#54](https://github.com/animovement/aniprocess/issues/54)). Where
  coordinates are cumulative — trackball data, whose readings are
  per-window displacements — masking a position blanks the flagged
  sample but leaves the spurious jump in every position after it;
  masking the displacement removes the jump itself.

  Only `"range"` accepts it. `"speed"` and `"excursion"` already judge
  between-sample change, and `"roi"` and `"confidence"` are not about
  displacement, so each errors with the reason rather than computing
  something odd.

### Changed

- The aniframe-aware filters use
  [`anicore::ensure_is_spatial()`](https://animovement.dev/anicore/reference/ensure_is_spatial.html)
  in place of a local copy, so the metadata contract is enforced by the
  package that defines it (animovement/aniframe#79). Requires aniframe
  0.7.0.

## aniprocess 0.3.0

### Changed

- The interface is now split into three tiers
  ([\#30](https://github.com/animovement/aniprocess/issues/30)). The
  individual functions work on a vector or a frame of coordinate
  columns, `*_with()` selects a method by name, and `*_across()` applies
  one to a whole aniframe.

  ``` r

  filter_across(data, "lowpass", cutoff_freq = 5)
  filter_with(x, "gaussian", sigma = 2)
  data |> mutate(filter_ccma(pick(all_of(c("x", "y")))))
  ```

- `filter_aniframe()` is removed — use
  [`filter_across()`](https://animovement.dev/aniprocess/reference/filter_across.md).

- `replace_na()` is removed — use
  [`replace_na_with()`](https://animovement.dev/aniprocess/reference/replace_na_with.md),
  which does not collide with `tidyr::replace_na()`.

- [`filter_ccma()`](https://animovement.dev/aniprocess/reference/filter_ccma.md),
  [`filter_na_speed()`](https://animovement.dev/aniprocess/reference/filter_na_speed.md),
  [`filter_na_excursion()`](https://animovement.dev/aniprocess/reference/filter_na_excursion.md),
  [`filter_na_roi()`](https://animovement.dev/aniprocess/reference/filter_na_roi.md)
  and
  [`filter_na_confidence()`](https://animovement.dev/aniprocess/reference/filter_na_confidence.md)
  now take a frame of coordinate columns rather than an aniframe. Use
  [`filter_across()`](https://animovement.dev/aniprocess/reference/filter_across.md)
  /
  [`filter_na_across()`](https://animovement.dev/aniprocess/reference/filter_na_across.md)
  for a whole aniframe.

- Filters preserve gaps by default: `keep_na` is `TRUE` everywhere
  except the Kalman filters, where inferring across gaps is the point.
  Pass `keep_na = FALSE` for the old behaviour
  ([\#38](https://github.com/animovement/aniprocess/issues/38)).

- Argument names are consistent across the package: `window_width`
  replaces `window_size` in
  [`filter_sgolay()`](https://animovement.dev/aniprocess/reference/filter_sgolay.md),
  [`find_peaks()`](https://animovement.dev/aniprocess/reference/find_peaks.md)
  and
  [`find_troughs()`](https://animovement.dev/aniprocess/reference/find_troughs.md);
  `x` replaces `measurements` in the Kalman filters;
  `min_value`/`max_value` replace `min`/`max` in
  [`filter_na_range()`](https://animovement.dev/aniprocess/reference/filter_na_range.md).

- [`filter_na_confidence()`](https://animovement.dev/aniprocess/reference/filter_na_confidence.md)
  no longer masks rows whose confidence is `NA`, and warns instead — a
  missing score means *not assessed*, not *poor*.

- `filter_na_across(method = "speed")` estimates an `"auto"` threshold
  per group. Pass `threshold = "pooled"` for a single estimate across
  all groups, which is steadier when tracks are short.

- [`filter_ccma()`](https://animovement.dev/aniprocess/reference/filter_ccma.md)
  and
  [`filter_na_excursion()`](https://animovement.dev/aniprocess/reference/filter_na_excursion.md)
  no longer scale quadratically in the number of groups. At 3,000 groups
  they are roughly 8× and 3.5× faster
  ([\#37](https://github.com/animovement/aniprocess/issues/37)).

### Added

- New
  [`filter_one_euro()`](https://animovement.dev/aniprocess/reference/filter_one_euro.md):
  the One Euro filter (Casiez, Roussel & Vogel, 2012), an adaptive
  low-pass whose cutoff rises with the speed of the signal — smooth when
  the animal is still, responsive when it moves
  ([\#35](https://github.com/animovement/aniprocess/issues/35)).
- `*_across()` uses what the aniframe already knows: `sampling_rate` and
  the time column come from its metadata. `variables` selects columns
  with tidyselect, defaulting to `variables_where`.
- `keep_na` is available on every filter, and validated.

### Fixed

- [`filter_na_speed()`](https://animovement.dev/aniprocess/reference/filter_na_speed.md)
  computes speed within each group, so a step is never formed between
  one track and the next. Where `time` restarts per track that step
  inflated the `"auto"` threshold and caused genuine outliers to be
  missed ([\#37](https://github.com/animovement/aniprocess/issues/37)).
- Differencing filters (`on_deltas`, formerly `use_derivatives`)
  re-integrate from the original starting value; they previously dropped
  the first sample and shifted the whole series
  ([\#30](https://github.com/animovement/aniprocess/issues/30)).
- [`filter_na_speed()`](https://animovement.dev/aniprocess/reference/filter_na_speed.md)
  no longer blanks groups too short to contain a step
  ([\#37](https://github.com/animovement/aniprocess/issues/37)).
- The `data.table (>= 1.18.0)` requirement is enforced when the package
  loads, not only when it is installed
  ([\#33](https://github.com/animovement/aniprocess/issues/33)).

## aniprocess 0.2.0

### Added

- New
  [`filter_ccma()`](https://animovement.dev/aniprocess/reference/filter_ccma.md):
  Curvature-Corrected Moving Average for 2D/3D Cartesian trajectories
  (Steinecker & Wuensche, 2023). Hanning and uniform kernels; padding
  boundary mode
  ([\#11](https://github.com/animovement/aniprocess/issues/11)).
- New
  [`filter_na_excursion()`](https://animovement.dev/aniprocess/reference/filter_na_excursion.md):
  flags multi-frame tracking excursions using the criterion from Todd,
  Kain & de Bivort (2017) — a jump that eventually returns counts as an
  outlier; a sustained shift does not
  ([\#13](https://github.com/animovement/aniprocess/issues/13)).
- New
  [`filter_gaussian()`](https://animovement.dev/aniprocess/reference/filter_gaussian.md):
  Gaussian kernel smoother with NA-aware weight renormalisation
  ([\#1](https://github.com/animovement/aniprocess/issues/1)).
- New
  [`filter_triangular()`](https://animovement.dev/aniprocess/reference/filter_triangular.md):
  triangular smoother as two passes of
  [`filter_rollmean()`](https://animovement.dev/aniprocess/reference/filter_rollmean.md)
  ([\#1](https://github.com/animovement/aniprocess/issues/1)).

### Fixed

- [`filter_lowpass_fft()`](https://animovement.dev/aniprocess/reference/filter_lowpass_fft.md)
  /
  [`filter_highpass_fft()`](https://animovement.dev/aniprocess/reference/filter_highpass_fft.md):
  fixed an asymmetric frequency-domain mask that halved the passband
  amplitude. Lowpass + highpass at the same cutoff now reconstruct the
  input exactly.
- [`filter_na_speed()`](https://animovement.dev/aniprocess/reference/filter_na_speed.md)
  now flags single-frame outliers correctly (the outlier itself is
  blanked, not its neighbours), and a single NA in the input no longer
  contaminates adjacent rows
  ([\#14](https://github.com/animovement/aniprocess/issues/14)).
- `filter_aniframe()` works on aniframes without an `individual` column.
  Identity columns now come from `variables_what`, spatial columns from
  `variables_where`
  ([\#16](https://github.com/animovement/aniprocess/issues/16)).
- [`find_peaks()`](https://animovement.dev/aniprocess/reference/find_peaks.md)
  /
  [`find_troughs()`](https://animovement.dev/aniprocess/reference/find_troughs.md):
  prominence now matches the documented topographic definition (saddle =
  max of left/right valley min). Previously could overestimate
  prominence and let peaks slip past `min_prominence`.
- [`filter_sgolay()`](https://animovement.dev/aniprocess/reference/filter_sgolay.md):
  `preserve_edges` had two bugs and is removed —
  [`signal::sgolayfilt()`](https://rdrr.io/pkg/signal/man/sgolayfilt.html)
  already handles edges correctly.
- [`filter_kalman()`](https://animovement.dev/aniprocess/reference/filter_kalman.md)
  documentation: corrected the default `base_Q` formula.
- [`replace_na_stine()`](https://animovement.dev/aniprocess/reference/replace_na_stine.md)
  and the inline installer in `filter_bandwidth.R` now point at the
  current r-universe
  ([\#17](https://github.com/animovement/aniprocess/issues/17)).

### Changed

- [`filter_sgolay()`](https://animovement.dev/aniprocess/reference/filter_sgolay.md):
  dropped `preserve_edges`.
- [`filter_rollmean()`](https://animovement.dev/aniprocess/reference/filter_rollmean.md)
  /
  [`filter_rollmedian()`](https://animovement.dev/aniprocess/reference/filter_rollmedian.md):
  dropped `...`, gained an explicit `align` argument
  ([\#7](https://github.com/animovement/aniprocess/issues/7)).
- `data.table (>= 1.18.0)` promoted from `Suggests` to `Imports` (now
  backs the rolling filters and the LOCF interpolation step).
- Removed `roll`, `collapse`, and `animetric`.

## aniprocess 0.1.2

### Added

- A `NEWS.md` file, to track changes to the package.

### Changed

- Updated to the tidy movement data model of aniframe 0.4.0.
- [`filter_na_speed()`](https://animovement.dev/aniprocess/reference/filter_na_speed.md)
  uses `differentiate()` from animetric rather than its own derivative.
- [`filter_na_roi()`](https://animovement.dev/aniprocess/reference/filter_na_roi.md)
  accepts 3D regions of interest.

## aniprocess 0.1.1

The package takes its present shape: masking, gap filling and smoothing.

### Added

- NA masking:
  [`filter_na_confidence()`](https://animovement.dev/aniprocess/reference/filter_na_confidence.md),
  [`filter_na_speed()`](https://animovement.dev/aniprocess/reference/filter_na_speed.md),
  [`filter_na_range()`](https://animovement.dev/aniprocess/reference/filter_na_range.md)
  and
  [`filter_na_roi()`](https://animovement.dev/aniprocess/reference/filter_na_roi.md).
- Gap filling:
  [`replace_na_linear()`](https://animovement.dev/aniprocess/reference/replace_na_linear.md),
  [`replace_na_spline()`](https://animovement.dev/aniprocess/reference/replace_na_spline.md),
  [`replace_na_stine()`](https://animovement.dev/aniprocess/reference/replace_na_stine.md),
  [`replace_na_locf()`](https://animovement.dev/aniprocess/reference/replace_na_locf.md),
  [`replace_na_value()`](https://animovement.dev/aniprocess/reference/replace_na_value.md)
  and the generic `replace_na()`.
- Smoothing and filtering:
  [`filter_sgolay()`](https://animovement.dev/aniprocess/reference/filter_sgolay.md),
  [`filter_rollmean()`](https://animovement.dev/aniprocess/reference/filter_rollmean.md),
  [`filter_rollmedian()`](https://animovement.dev/aniprocess/reference/filter_rollmedian.md),
  [`filter_lowpass()`](https://animovement.dev/aniprocess/reference/filter_lowpass.md),
  [`filter_highpass()`](https://animovement.dev/aniprocess/reference/filter_highpass.md),
  their `_fft()` counterparts,
  [`filter_kalman()`](https://animovement.dev/aniprocess/reference/filter_kalman.md)
  and
  [`filter_kalman_irregular()`](https://animovement.dev/aniprocess/reference/filter_kalman_irregular.md).
- Peak detection:
  [`find_peaks()`](https://animovement.dev/aniprocess/reference/find_peaks.md)
  and
  [`find_troughs()`](https://animovement.dev/aniprocess/reference/find_troughs.md).
- `filter_aniframe()`, the frame-level entry point.

## aniprocess 0.1.0

Package skeleton. No filters yet.
