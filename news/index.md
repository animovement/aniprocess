# Changelog

## aniprocess (development version)

### Added

- [`mask_na_segment_length()`](https://animovement.dev/aniprocess/reference/mask_na_segment_length.md)
  masks points whose segments are far off their usual length
  ([\#91](https://github.com/animovement/aniprocess/issues/91)), such as
  a foot matched wrongly in multi-camera 3D that stays confident and
  steady for many frames. Each segment of the structure attached with
  [`anicore::set_structure()`](https://animovement.dev/anicore/reference/structures.html)
  is compared with the structure’s `length`, or else with its median
  length over the track, and is off when it differs by more than both
  `tolerance` (relative) and `min_difference` (absolute). The point to
  blame is masked rather than its neighbours: a wrong ankle stretches
  shin and foot, so the ankle goes and the knee and the toe stay.
  `segments` restricts the judging to the segments meant to be rigid.

- [`mask_na_hampel()`](https://animovement.dev/aniprocess/reference/mask_na_hampel.md)
  masks spikes — a point that jumps away for a frame or two and comes
  back — by its distance from the rolling median of the window around
  it, against `k` robust deviations of that window
  ([\#90](https://github.com/animovement/aniprocess/issues/90)). The
  threshold is local, so it is tight on slow stretches and loose on fast
  ones, where a single speed threshold has to accommodate the fastest
  movement in the track. With several coordinate columns the distance is
  Euclidean and a point is masked in all axes at once; `min_distance`
  floors the threshold so a keypoint that barely moves does not lose its
  noise. Also available as `mask_na_across(method = "hampel")` and
  `mask_na_with(method = "hampel")`.

### Changed

- The NA-masking functions are renamed from `filter_na_*()` to
  `mask_na_*()`
  ([\#94](https://github.com/animovement/aniprocess/issues/94)). They
  set bad values to `NA` and keep every row, which `filter_` — the
  prefix of
  [`dplyr::filter()`](https://dplyr.tidyverse.org/reference/filter.html),
  and of this package’s smoothers — suggested they did not. Masking then
  filling now reads as `mask_na_*()` then `replace_na_*()`.

- Works with anicore’s `anipoint` class and rebuilt accessor API
  (animovement/anicore#154). The `*_across()` verbs take their default
  columns from `get_variables(data, "where", "position")`.

- [`filter_rollmean()`](https://animovement.dev/aniprocess/reference/filter_rollmean.md)
  and
  [`filter_rollmedian()`](https://animovement.dev/aniprocess/reference/filter_rollmedian.md)
  centre their window by default, instead of aligning it to the right
  ([\#83](https://github.com/animovement/aniprocess/issues/83)). A
  right-aligned window looks only backwards, so the filtered signal
  lagged by `(window_width - 1) / 2` samples: with `window_width = 11` a
  feature peaking at frame 100 came out at frame 105, and smoothing
  before `calculate_kinematics()` moved every speed peak 200 ms later at
  30 Hz. Nothing warned, because a lagged trace looks entirely
  plausible.

  The other five smoothers do not shift the signal —
  [`filter_triangular()`](https://animovement.dev/aniprocess/reference/filter_triangular.md)
  already defaulted to `"center"`, and the Butterworth filters use
  `filtfilt()` precisely to avoid it — so this brings the rolling pair
  into line rather than introducing a new convention.

  **Results change.** Centred output keeps its timing but has no data
  beyond the ends of the series, so the first and last
  `(window_width - 1) / 2` values are now `NA` where a partial window
  used to fill them. Pass `align = "right"` for the old behaviour, which
  is still the right choice when the next sample does not exist yet —
  real-time tracking, closed-loop experiments.

- [`filter_lowpass()`](https://animovement.dev/aniprocess/reference/filter_lowpass.md),
  [`filter_highpass()`](https://animovement.dev/aniprocess/reference/filter_highpass.md),
  [`filter_lowpass_fft()`](https://animovement.dev/aniprocess/reference/filter_lowpass_fft.md)
  and
  [`filter_highpass_fft()`](https://animovement.dev/aniprocess/reference/filter_highpass_fft.md)
  share one reflection-padding helper, so the width applied and the
  width removed cannot drift apart again
  ([\#79](https://github.com/animovement/aniprocess/issues/79)).

### Deprecated

- [`filter_na_across()`](https://animovement.dev/aniprocess/reference/filter_na_deprecated.md),
  [`filter_na_with()`](https://animovement.dev/aniprocess/reference/filter_na_deprecated.md),
  [`filter_na_confidence()`](https://animovement.dev/aniprocess/reference/filter_na_deprecated.md),
  [`filter_na_excursion()`](https://animovement.dev/aniprocess/reference/filter_na_deprecated.md),
  [`filter_na_range()`](https://animovement.dev/aniprocess/reference/filter_na_deprecated.md),
  [`filter_na_roi()`](https://animovement.dev/aniprocess/reference/filter_na_deprecated.md)
  and
  [`filter_na_speed()`](https://animovement.dev/aniprocess/reference/filter_na_deprecated.md)
  are deprecated in favour of
  [`mask_na_across()`](https://animovement.dev/aniprocess/reference/mask_na_across.md),
  [`mask_na_with()`](https://animovement.dev/aniprocess/reference/mask_na_with.md),
  [`mask_na_confidence()`](https://animovement.dev/aniprocess/reference/mask_na_confidence.md),
  [`mask_na_excursion()`](https://animovement.dev/aniprocess/reference/mask_na_excursion.md),
  [`mask_na_range()`](https://animovement.dev/aniprocess/reference/mask_na_range.md),
  [`mask_na_roi()`](https://animovement.dev/aniprocess/reference/mask_na_roi.md)
  and
  [`mask_na_speed()`](https://animovement.dev/aniprocess/reference/mask_na_speed.md)
  ([\#94](https://github.com/animovement/aniprocess/issues/94)). They
  warn and forward to the new name, and will be removed after the next
  release.

### Fixed

- [`filter_lowpass()`](https://animovement.dev/aniprocess/reference/filter_lowpass.md)
  and
  [`filter_highpass()`](https://animovement.dev/aniprocess/reference/filter_highpass.md)
  return the filtered signal rather than its reversed tail, for any
  signal shorter than the padding they apply
  ([\#79](https://github.com/animovement/aniprocess/issues/79)). The
  reflection padding is clamped to the length of the signal, but the
  code that removed it afterwards used the width it had *asked* for.
  With the default order of 4 the pad is at least 40 samples, so every
  signal shorter than that was affected: under about 20 samples the
  result was entirely `NA`, and between there and 40 it was the mirrored
  end of the signal, reversed in time, with no `NA` and no warning to
  show for it. A 20-sample trace came back correlating `-0.73` with its
  own filtered self. Signals longer than the pad were never affected and
  are unchanged.

- The four bandwidth filters return an empty vector for an empty signal,
  instead of two `NA`s
  ([\#79](https://github.com/animovement/aniprocess/issues/79)). `1:0`
  counts backwards, so the padding indexed positions 1 and 0 of a vector
  with neither.

## aniprocess 0.5.0 (2026-08-28)

### Added

- [`replace_na_linear()`](https://animovement.dev/aniprocess/reference/replace_na_linear.md),
  [`replace_na_spline()`](https://animovement.dev/aniprocess/reference/replace_na_spline.md)
  and
  [`replace_na_stine()`](https://animovement.dev/aniprocess/reference/replace_na_stine.md)
  take a `times` argument, the positions the values sit at. It defaults
  to row position, which is what they used before.

### Changed

- The minimum `anicore` is 0.8.0, which is the first version published
  under that name. The constraint read `>= 0.7.0` — a version of
  `anicore` that never existed, carried over unchanged from `aniframe`
  when the dependency was renamed.

- The core data structures come from `anicore`, which is what the
  `aniframe` package was renamed to in its 0.8.0
  (animovement/anicore#84). The `aniframe` class keeps its name; only
  the package providing it changed, so `anicore` replaces `aniframe` in
  `Imports` and in every `aniframe::` call.

### Fixed

- The interpolators fill gaps against the index rather than row position
  ([\#67](https://github.com/animovement/aniprocess/issues/67)). They
  built their abscissa as `seq_len(n)`. On a regularly sampled frame row
  position and elapsed time are proportional and the two agree; on an
  irregular one they do not, and the imputed value landed at the wrong
  moment with no error or warning:

  ``` r

  time <- c(0, 1, 10); x <- c(0, NA, 100)
  #>  50   interpolating on row position
  #>  10   interpolating on the index
  ```

  A factor of five on three points, and it grows with how uneven the
  sampling is.
  [`replace_na_across()`](https://animovement.dev/aniprocess/reference/replace_na_across.md)
  resolves the index and passes it down.

  Two further faults surfaced while fixing it. The data was indexed by
  *time value* rather than position — correct only while the abscissa
  was `seq_len(n)`. And
  [`replace_na_spline()`](https://animovement.dev/aniprocess/reference/replace_na_spline.md)
  asked [`stats::spline()`](https://rdrr.io/r/stats/splinefun.html) for
  `n` points spread across the whole range rather than evaluated at the
  positions being filled, so with leading or trailing `NA`s the
  interpolated values were misaligned even on regularly sampled data.

- The column holding time is read from the frame’s index rather than the
  first `variables_when` entry. `variables_when` now holds only the
  temporal context, so on an ordinary frame it is empty and the lookup
  failed with `Cannot determine which column holds time.` It also
  repairs a latent fault: the first entry was `session` on any frame
  carrying a temporal context, so the wrong column was used whenever one
  was present.

- [`filter_ccma()`](https://animovement.dev/aniprocess/reference/filter_ccma.md)’s
  documentation no longer promises an aniframe path it does not have
  ([\#71](https://github.com/animovement/aniprocess/issues/71)). It is a
  column-level function; the aniframe tier is
  `filter_across(data, "ccma")`, and both are now shown in a runnable
  example rather than a `\dontrun{}` block referring to an undefined
  object.

- Handing a whole aniframe to a column-level filter now says which tier
  takes one
  ([\#71](https://github.com/animovement/aniprocess/issues/71)). It was
  rejected for its identity columns not being numeric —
  `Coordinate column "keypoint" must be numeric` — which reads as a
  problem with the data rather than with the function being called.
  [`filter_ccma()`](https://animovement.dev/aniprocess/reference/filter_ccma.md)
  points at
  [`filter_across()`](https://animovement.dev/aniprocess/reference/filter_across.md),
  and
  [`filter_na_confidence()`](https://animovement.dev/aniprocess/reference/filter_na_deprecated.md),
  [`filter_na_excursion()`](https://animovement.dev/aniprocess/reference/filter_na_deprecated.md),
  [`filter_na_roi()`](https://animovement.dev/aniprocess/reference/filter_na_deprecated.md)
  and
  [`filter_na_speed()`](https://animovement.dev/aniprocess/reference/filter_na_deprecated.md)
  at
  [`filter_na_across()`](https://animovement.dev/aniprocess/reference/filter_na_deprecated.md).

## aniprocess 0.4.0 (2026-08-18)

### Added

- [`filter_na_across()`](https://animovement.dev/aniprocess/reference/filter_na_deprecated.md)
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
  [`filter_na_speed()`](https://animovement.dev/aniprocess/reference/filter_na_deprecated.md),
  [`filter_na_excursion()`](https://animovement.dev/aniprocess/reference/filter_na_deprecated.md),
  [`filter_na_roi()`](https://animovement.dev/aniprocess/reference/filter_na_deprecated.md)
  and
  [`filter_na_confidence()`](https://animovement.dev/aniprocess/reference/filter_na_deprecated.md)
  now take a frame of coordinate columns rather than an aniframe. Use
  [`filter_across()`](https://animovement.dev/aniprocess/reference/filter_across.md)
  /
  [`filter_na_across()`](https://animovement.dev/aniprocess/reference/filter_na_deprecated.md)
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
  [`filter_na_range()`](https://animovement.dev/aniprocess/reference/filter_na_deprecated.md).

- [`filter_na_confidence()`](https://animovement.dev/aniprocess/reference/filter_na_deprecated.md)
  no longer masks rows whose confidence is `NA`, and warns instead — a
  missing score means *not assessed*, not *poor*.

- `filter_na_across(method = "speed")` estimates an `"auto"` threshold
  per group. Pass `threshold = "pooled"` for a single estimate across
  all groups, which is steadier when tracks are short.

- [`filter_ccma()`](https://animovement.dev/aniprocess/reference/filter_ccma.md)
  and
  [`filter_na_excursion()`](https://animovement.dev/aniprocess/reference/filter_na_deprecated.md)
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

- [`filter_na_speed()`](https://animovement.dev/aniprocess/reference/filter_na_deprecated.md)
  computes speed within each group, so a step is never formed between
  one track and the next. Where `time` restarts per track that step
  inflated the `"auto"` threshold and caused genuine outliers to be
  missed ([\#37](https://github.com/animovement/aniprocess/issues/37)).
- Differencing filters (`on_deltas`, formerly `use_derivatives`)
  re-integrate from the original starting value; they previously dropped
  the first sample and shifted the whole series
  ([\#30](https://github.com/animovement/aniprocess/issues/30)).
- [`filter_na_speed()`](https://animovement.dev/aniprocess/reference/filter_na_deprecated.md)
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
  [`filter_na_excursion()`](https://animovement.dev/aniprocess/reference/filter_na_deprecated.md):
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
- [`filter_na_speed()`](https://animovement.dev/aniprocess/reference/filter_na_deprecated.md)
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
- [`filter_na_speed()`](https://animovement.dev/aniprocess/reference/filter_na_deprecated.md)
  uses `differentiate()` from animetric rather than its own derivative.
- [`filter_na_roi()`](https://animovement.dev/aniprocess/reference/filter_na_deprecated.md)
  accepts 3D regions of interest.

## aniprocess 0.1.1

The package takes its present shape: masking, gap filling and smoothing.

### Added

- NA masking:
  [`filter_na_confidence()`](https://animovement.dev/aniprocess/reference/filter_na_deprecated.md),
  [`filter_na_speed()`](https://animovement.dev/aniprocess/reference/filter_na_deprecated.md),
  [`filter_na_range()`](https://animovement.dev/aniprocess/reference/filter_na_deprecated.md)
  and
  [`filter_na_roi()`](https://animovement.dev/aniprocess/reference/filter_na_deprecated.md).
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
