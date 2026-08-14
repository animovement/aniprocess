# aniprocess (development version)

## Breaking changes

* `replace_na()` is deprecated in favour of `replace_na_with()`. It still works and delegates to the new function, but warns. Internally the filters' `na_action` argument now calls `replace_na_with()`, so filtering data with `NA`s does not emit the deprecation warning (#30).

* Argument names are now consistent across the package, so that a generic wrapper can forward them without special-casing. This is the first step towards the unified interface in #30 (#30).
  * `window_size` is now `window_width` in `filter_sgolay()`, `find_peaks()` and `find_troughs()`, matching `filter_gaussian()`, `filter_rollmean()`, `filter_rollmedian()` and `filter_triangular()`.
  * The first argument of `filter_kalman()` and `filter_kalman_irregular()` is now `x` rather than `measurements`. They were the only vector-level functions whose first argument was not `x`, which prevented their use with `dplyr::across()`.
  * `filter_na_range()` takes `min_value`/`max_value` rather than `min`/`max`, which shadowed the base functions of those names and did not match the `min_gap`/`max_gap`/`min_obs` convention used elsewhere.

  No deprecation cycle: nothing in the animovement org passes these names, verified across `aniread`, `animetric`, `aniframe`, `anicheck`, `anispace`, `anivis` and the `animovement` meta-package.

* Filters no longer fill gaps by default. `keep_na` now defaults to `TRUE` in `filter_sgolay()`, `filter_lowpass()`, `filter_highpass()`, `filter_lowpass_fft()`, `filter_highpass_fft()` and `filter_ccma()`, so positions that were `NA` in the input are `NA` in the output. Previously the default was `FALSE`, which meant genuinely-missing stretches came back as smoothed interpolations with no indication that any interpolation had happened. Pass `keep_na = FALSE` for the old behaviour (#38).
* `keep_na` is now available on every filter. `filter_gaussian()`, `filter_rollmean()`, `filter_rollmedian()` and `filter_triangular()` gain the argument, defaulting to `TRUE`; they previously filled gaps — fully or partially — with no way to opt out (#38).
* `filter_kalman()` and `filter_kalman_irregular()` also gain `keep_na`, but default to `FALSE`. A Kalman filter's predict step is designed to carry the state estimate through missing observations, so inferring across gaps is intended rather than accidental. Pass `keep_na = TRUE` to leave gaps as gaps (#38).

## New features

* New `filter_with()`, `filter_na_with()` and `replace_na_with()`: generic entry points that select a method by name rather than by choosing a function, which is the third step towards the unified interface in #30 (#30).

  ```r
  filter_with(x, "gaussian", sigma = 2)
  filter_na_with(coords, "speed", threshold = 10, time = time)
  replace_na_with(x, "linear", max_gap = 3)
  ```

  All three preserve shape: a vector gives a vector, a data frame of columns gives a data frame. Univariate methods are applied column by column, so `replace_na_with()` and most of `filter_with()` work with `dplyr::across()` as well as `dplyr::pick()`. The multivariate methods — `"ccma"` in `filter_with()`, and everything except `"range"` in `filter_na_with()` — require a data frame and say so when handed a bare vector.

  They reject an aniframe. An aniframe *is* a data frame, so without that guard it would be filtered column by column, `time` and identity columns included.
* `replace_na_with()` replaces `replace_na()`, which collides with `tidyr::replace_na()` — a function that does something different (it substitutes a fixed value per column rather than interpolating gaps).

* The aniframe-aware filters now accept a data frame of coordinate columns as well as an aniframe, and return whichever shape they were given. This makes them usable inside `dplyr::mutate()` via `dplyr::pick()`, which is the second step towards the unified interface in #30 (#30).
  ```r
  data |> mutate(filter_ccma(pick(all_of(c("x", "y")))))
  data |> mutate(filter_na_speed(pick(all_of(c("x", "y"))), time = time))
  ```
  Applies to `filter_ccma()`, `filter_na_speed()`, `filter_na_excursion()`, `filter_na_roi()` and `filter_na_confidence()`. These operations are multivariate — each result depends on all coordinates jointly — so they work with `pick()` but not with `dplyr::across()`, which passes one column at a time.
* `filter_na_speed()` gains a `time` argument and `filter_na_confidence()` a `confidence` argument. Both are required when the input is a coordinate frame and default to the corresponding aniframe column otherwise. Neither `time` nor `confidence` is a coordinate, so the coordinate-frame form cannot mask `confidence`; only the aniframe form does.
* `filter_na_roi()` now aborts with a clear message when the coordinates it needs (`x` and `y`) are absent, rather than failing further in.
* `filter_na_confidence()` no longer masks rows whose confidence is `NA`. A missing confidence means *not scored* rather than *scored badly* — a human annotator has no natural number to enter for "not assessed", and tracker scores are not bounded at 1 (SLEAP can exceed it), so `NA` is the sensible thing to record. Those rows are left unfiltered and a rate-limited warning reports how many there were. To drop them as well, filter `confidence` directly with `filter_na_range()`.
* `na_action` and `keep_na` are now documented from a single shared source, so the contract is stated identically across the filter family (#38).
* `keep_na` is validated: a non-logical, `NA`, or non-scalar value now aborts with a clear message rather than being silently coerced.

## Bug fixes

* `filter_na_speed()` now computes speed within each group of a grouped aniframe. It previously worked on the raw column vectors, so a step was formed between the last row of one track and the first row of the next. Where `time` restarts per track that step has a negative duration and yields a negative "speed", which inflated the `"auto"` threshold and caused genuine outliers to be **missed** — how badly depended on how far apart the tracks happened to be. The cross-track step never produced false positives, because per-row speed is the minimum of the backward and forward step and a track boundary is one-sided (#37).
* `filter_na_speed()` no longer blanks rows belonging to groups shorter than two rows. Such a group has no step, so its speed is `NA`, and `dplyr::if_else()` propagates a missing condition (#37).

## Internal

* `filter_na_speed()`, `filter_na_excursion()` and `filter_ccma()` all resolve groups through `dplyr::mutate()` and `dplyr::pick()` rather than re-deriving row indices with `dplyr::group_indices()`. Only `filter_na_speed()` changes behaviour; for the other two the output is unchanged, verified byte-for-byte against the previous implementation. The manual loops rescanned the group vector on every iteration — and in `filter_ccma()` rebuilt the whole data frame — making them quadratic in group count. At 3,000 groups × 20 rows, `filter_ccma()` goes from 47.8s to 5.9s and `filter_na_excursion()` from 2.19s to 0.63s. `filter_na_speed()` becomes slower (0.02s to 0.31s) because it previously did no per-group work at all (#37).
* `calculate_speed_2d()` and `calculate_speed_3d()` are replaced by a single dimension-agnostic `calculate_step_speed()`, which sums the squared step over whatever coordinate columns it is given.

* The `data.table (>= 1.18.0)` requirement is now enforced when the package loads, not only when it is installed. Because the rolling filters reached `data.table` solely via `data.table::`, R had no namespace import to version-check, so an older `data.table` arriving after installation (conda, a stale `renv` lockfile, a manual downgrade) failed with `unused argument (partial = use_partial)` from inside `filter_rollmean()` rather than a version error naming `data.table` (#33).

# aniprocess 0.2.0

## New features

* New `filter_ccma()`: Curvature-Corrected Moving Average for 2D/3D Cartesian trajectories (Steinecker & Wuensche, 2023). Hanning and uniform kernels; padding boundary mode (#11).
* New `filter_na_excursion()`: flags multi-frame tracking excursions using the criterion from Todd, Kain & de Bivort (2017) — a jump that eventually returns counts as an outlier; a sustained shift does not (#13).
* New `filter_gaussian()`: Gaussian kernel smoother with NA-aware weight renormalisation (#1).
* New `filter_triangular()`: triangular smoother as two passes of `filter_rollmean()` (#1).

## Bug fixes

* `filter_lowpass_fft()` / `filter_highpass_fft()`: fixed an asymmetric frequency-domain mask that halved the passband amplitude. Lowpass + highpass at the same cutoff now reconstruct the input exactly.
* `filter_na_speed()` now flags single-frame outliers correctly (the outlier itself is blanked, not its neighbours), and a single NA in the input no longer contaminates adjacent rows (#14).
* `filter_aniframe()` works on aniframes without an `individual` column. Identity columns now come from `variables_what`, spatial columns from `variables_where` (#16).
* `find_peaks()` / `find_troughs()`: prominence now matches the documented topographic definition (saddle = max of left/right valley min). Previously could overestimate prominence and let peaks slip past `min_prominence`.
* `filter_sgolay()`: `preserve_edges` had two bugs and is removed — `signal::sgolayfilt()` already handles edges correctly.
* `filter_kalman()` documentation: corrected the default `base_Q` formula.
* `replace_na_stine()` and the inline installer in `filter_bandwidth.R` now point at the current r-universe (#17).

## Breaking changes

* `filter_sgolay()`: dropped `preserve_edges`.
* `filter_rollmean()` / `filter_rollmedian()`: dropped `...`, gained an explicit `align` argument (#7).

## Dependencies

* `data.table (>= 1.18.0)` promoted from `Suggests` to `Imports` (now backs the rolling filters and the LOCF interpolation step).
* Removed `roll`, `collapse`, and `animetric`.

## Internal / housekeeping

* New helpers `ensure_replace_na_args()` and `ensure_aniframe_spatial()` replace duplicated input validation across the `replace_na_*()` and `filter_na_*()` families.
* `check_*()` helpers for optional packages consolidated, so the canonical r-universe URL lives in a single place.
* Three dead files removed; future work tracked in #29 (`filter_by_pose`) and #30 (an across-style API).
* Package now at 100% line coverage; `covr` added to `Suggests`.

# aniprocess 0.1.2

* Added a `NEWS.md` file to track changes to the package.
* Update to work with tidy movement logic.
* Use `differentiate` from *animetric* for `filter_na_speed`.
* `filter_na_roi` now works with 3D ROIs.
