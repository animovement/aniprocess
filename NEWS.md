# aniprocess 0.4.0 (2026-08-18)

## New features

* `filter_na_across()` gains `on_deltas`, matching `filter_across()`: it differences each column, masks the differences, and re-integrates from the original starting value (#54). Where coordinates are cumulative — trackball data, whose readings are per-window displacements — masking a position blanks the flagged sample but leaves the spurious jump in every position after it; masking the displacement removes the jump itself.

  Only `"range"` accepts it. `"speed"` and `"excursion"` already judge between-sample change, and `"roi"` and `"confidence"` are not about displacement, so each errors with the reason rather than computing something odd.

## Improvements

* The aniframe-aware filters use `anicore::ensure_is_spatial()` in place of a local copy, so the metadata contract is enforced by the package that defines it (animovement/aniframe#79). Requires aniframe 0.7.0.

# aniprocess 0.3.0

## Breaking changes

* The interface is now split into three tiers (#30). The individual functions work on a vector or a frame of coordinate columns, `*_with()` selects a method by name, and `*_across()` applies one to a whole aniframe.

  ```r
  filter_across(data, "lowpass", cutoff_freq = 5)
  filter_with(x, "gaussian", sigma = 2)
  data |> mutate(filter_ccma(pick(all_of(c("x", "y")))))
  ```

* `filter_aniframe()` is removed — use `filter_across()`.
* `replace_na()` is removed — use `replace_na_with()`, which does not collide with `tidyr::replace_na()`.
* `filter_ccma()`, `filter_na_speed()`, `filter_na_excursion()`, `filter_na_roi()` and `filter_na_confidence()` now take a frame of coordinate columns rather than an aniframe. Use `filter_across()` / `filter_na_across()` for a whole aniframe.
* Filters preserve gaps by default: `keep_na` is `TRUE` everywhere except the Kalman filters, where inferring across gaps is the point. Pass `keep_na = FALSE` for the old behaviour (#38).
* Argument names are consistent across the package: `window_width` replaces `window_size` in `filter_sgolay()`, `find_peaks()` and `find_troughs()`; `x` replaces `measurements` in the Kalman filters; `min_value`/`max_value` replace `min`/`max` in `filter_na_range()`.
* `filter_na_confidence()` no longer masks rows whose confidence is `NA`, and warns instead — a missing score means *not assessed*, not *poor*.
* `filter_na_across(method = "speed")` estimates an `"auto"` threshold per group. Pass `threshold = "pooled"` for a single estimate across all groups, which is steadier when tracks are short.

## New features

* New `filter_one_euro()`: the One Euro filter (Casiez, Roussel & Vogel, 2012), an adaptive low-pass whose cutoff rises with the speed of the signal — smooth when the animal is still, responsive when it moves (#35).
* `*_across()` uses what the aniframe already knows: `sampling_rate` and the time column come from its metadata. `variables` selects columns with tidyselect, defaulting to `variables_where`.
* `keep_na` is available on every filter, and validated.

## Bug fixes

* `filter_na_speed()` computes speed within each group, so a step is never formed between one track and the next. Where `time` restarts per track that step inflated the `"auto"` threshold and caused genuine outliers to be missed (#37).
* Differencing filters (`on_deltas`, formerly `use_derivatives`) re-integrate from the original starting value; they previously dropped the first sample and shifted the whole series (#30).
* `filter_na_speed()` no longer blanks groups too short to contain a step (#37).
* The `data.table (>= 1.18.0)` requirement is enforced when the package loads, not only when it is installed (#33).

## Performance

* `filter_ccma()` and `filter_na_excursion()` no longer scale quadratically in the number of groups. At 3,000 groups they are roughly 8× and 3.5× faster (#37).

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
