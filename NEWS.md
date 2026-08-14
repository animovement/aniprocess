# aniprocess (development version)

## Breaking changes

* Filters no longer fill gaps by default. `keep_na` now defaults to `TRUE` in `filter_sgolay()`, `filter_lowpass()`, `filter_highpass()`, `filter_lowpass_fft()`, `filter_highpass_fft()` and `filter_ccma()`, so positions that were `NA` in the input are `NA` in the output. Previously the default was `FALSE`, which meant genuinely-missing stretches came back as smoothed interpolations with no indication that any interpolation had happened. Pass `keep_na = FALSE` for the old behaviour (#38).
* `keep_na` is now available on every filter. `filter_gaussian()`, `filter_rollmean()`, `filter_rollmedian()` and `filter_triangular()` gain the argument, defaulting to `TRUE`; they previously filled gaps — fully or partially — with no way to opt out (#38).
* `filter_kalman()` and `filter_kalman_irregular()` also gain `keep_na`, but default to `FALSE`. A Kalman filter's predict step is designed to carry the state estimate through missing observations, so inferring across gaps is intended rather than accidental. Pass `keep_na = TRUE` to leave gaps as gaps (#38).

## New features

* `na_action` and `keep_na` are now documented from a single shared source, so the contract is stated identically across the filter family (#38).
* `keep_na` is validated: a non-logical, `NA`, or non-scalar value now aborts with a clear message rather than being silently coerced.

## Bug fixes

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
