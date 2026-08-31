# aniprocess (development version)

## Changed

* `filter_rollmean()` and `filter_rollmedian()` centre their window by default, instead of aligning it to the right (#83). A right-aligned window looks only backwards, so the filtered signal lagged by `(window_width - 1) / 2` samples: with `window_width = 11` a feature peaking at frame 100 came out at frame 105, and smoothing before `calculate_kinematics()` moved every speed peak 200 ms later at 30 Hz. Nothing warned, because a lagged trace looks entirely plausible.

  The other five smoothers do not shift the signal — `filter_triangular()` already defaulted to `"center"`, and the Butterworth filters use `filtfilt()` precisely to avoid it — so this brings the rolling pair into line rather than introducing a new convention.

  **Results change.** Centred output keeps its timing but has no data beyond the ends of the series, so the first and last `(window_width - 1) / 2` values are now `NA` where a partial window used to fill them. Pass `align = "right"` for the old behaviour, which is still the right choice when the next sample does not exist yet — real-time tracking, closed-loop experiments.

## Fixed

* `filter_lowpass()` and `filter_highpass()` return the filtered signal rather than its reversed tail, for any signal shorter than the padding they apply (#79). The reflection padding is clamped to the length of the signal, but the code that removed it afterwards used the width it had *asked* for. With the default order of 4 the pad is at least 40 samples, so every signal shorter than that was affected: under about 20 samples the result was entirely `NA`, and between there and 40 it was the mirrored end of the signal, reversed in time, with no `NA` and no warning to show for it. A 20-sample trace came back correlating `-0.73` with its own filtered self. Signals longer than the pad were never affected and are unchanged.

* The four bandwidth filters return an empty vector for an empty signal, instead of two `NA`s (#79). `1:0` counts backwards, so the padding indexed positions 1 and 0 of a vector with neither.

## Changed

* `filter_lowpass()`, `filter_highpass()`, `filter_lowpass_fft()` and `filter_highpass_fft()` share one reflection-padding helper, so the width applied and the width removed cannot drift apart again (#79).

# aniprocess 0.5.0 (2026-08-28)

## Added

* `replace_na_linear()`, `replace_na_spline()` and `replace_na_stine()` take a `times` argument, the positions the values sit at. It defaults to row position, which is what they used before.

## Changed

* The minimum `anicore` is 0.8.0, which is the first version published under that name. The constraint read `>= 0.7.0` — a version of `anicore` that never existed, carried over unchanged from `aniframe` when the dependency was renamed.

* The core data structures come from `anicore`, which is what the `aniframe` package was renamed to in its 0.8.0 (animovement/anicore#84). The `aniframe` class keeps its name; only the package providing it changed, so `anicore` replaces `aniframe` in `Imports` and in every `aniframe::` call.

## Fixed

* The interpolators fill gaps against the index rather than row position (#67). They built their abscissa as `seq_len(n)`. On a regularly sampled frame row position and elapsed time are proportional and the two agree; on an irregular one they do not, and the imputed value landed at the wrong moment with no error or warning:

  ```r
  time <- c(0, 1, 10); x <- c(0, NA, 100)
  #>  50   interpolating on row position
  #>  10   interpolating on the index
  ```

  A factor of five on three points, and it grows with how uneven the sampling is. `replace_na_across()` resolves the index and passes it down.

  Two further faults surfaced while fixing it. The data was indexed by *time value* rather than position — correct only while the abscissa was `seq_len(n)`. And `replace_na_spline()` asked `stats::spline()` for `n` points spread across the whole range rather than evaluated at the positions being filled, so with leading or trailing `NA`s the interpolated values were misaligned even on regularly sampled data.

* The column holding time is read from the frame's index rather than the first `variables_when` entry. `variables_when` now holds only the temporal context, so on an ordinary frame it is empty and the lookup failed with `Cannot determine which column holds time.` It also repairs a latent fault: the first entry was `session` on any frame carrying a temporal context, so the wrong column was used whenever one was present.

* `filter_ccma()`'s documentation no longer promises an aniframe path it does not have (#71). It is a column-level function; the aniframe tier is `filter_across(data, "ccma")`, and both are now shown in a runnable example rather than a `\dontrun{}` block referring to an undefined object.

* Handing a whole aniframe to a column-level filter now says which tier takes one (#71). It was rejected for its identity columns not being numeric — `Coordinate column "keypoint" must be numeric` — which reads as a problem with the data rather than with the function being called. `filter_ccma()` points at `filter_across()`, and `filter_na_confidence()`, `filter_na_excursion()`, `filter_na_roi()` and `filter_na_speed()` at `filter_na_across()`.

# aniprocess 0.4.0 (2026-08-18)

## Added

* `filter_na_across()` gains `on_deltas`, matching `filter_across()`: it differences each column, masks the differences, and re-integrates from the original starting value (#54). Where coordinates are cumulative — trackball data, whose readings are per-window displacements — masking a position blanks the flagged sample but leaves the spurious jump in every position after it; masking the displacement removes the jump itself.

  Only `"range"` accepts it. `"speed"` and `"excursion"` already judge between-sample change, and `"roi"` and `"confidence"` are not about displacement, so each errors with the reason rather than computing something odd.

## Changed

* The aniframe-aware filters use `anicore::ensure_is_spatial()` in place of a local copy, so the metadata contract is enforced by the package that defines it (animovement/aniframe#79). Requires aniframe 0.7.0.

# aniprocess 0.3.0

## Changed

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
* `filter_ccma()` and `filter_na_excursion()` no longer scale quadratically in the number of groups. At 3,000 groups they are roughly 8× and 3.5× faster (#37).

## Added

* New `filter_one_euro()`: the One Euro filter (Casiez, Roussel & Vogel, 2012), an adaptive low-pass whose cutoff rises with the speed of the signal — smooth when the animal is still, responsive when it moves (#35).
* `*_across()` uses what the aniframe already knows: `sampling_rate` and the time column come from its metadata. `variables` selects columns with tidyselect, defaulting to `variables_where`.
* `keep_na` is available on every filter, and validated.

## Fixed

* `filter_na_speed()` computes speed within each group, so a step is never formed between one track and the next. Where `time` restarts per track that step inflated the `"auto"` threshold and caused genuine outliers to be missed (#37).
* Differencing filters (`on_deltas`, formerly `use_derivatives`) re-integrate from the original starting value; they previously dropped the first sample and shifted the whole series (#30).
* `filter_na_speed()` no longer blanks groups too short to contain a step (#37).
* The `data.table (>= 1.18.0)` requirement is enforced when the package loads, not only when it is installed (#33).

# aniprocess 0.2.0

## Added

* New `filter_ccma()`: Curvature-Corrected Moving Average for 2D/3D Cartesian trajectories (Steinecker & Wuensche, 2023). Hanning and uniform kernels; padding boundary mode (#11).
* New `filter_na_excursion()`: flags multi-frame tracking excursions using the criterion from Todd, Kain & de Bivort (2017) — a jump that eventually returns counts as an outlier; a sustained shift does not (#13).
* New `filter_gaussian()`: Gaussian kernel smoother with NA-aware weight renormalisation (#1).
* New `filter_triangular()`: triangular smoother as two passes of `filter_rollmean()` (#1).

## Fixed

* `filter_lowpass_fft()` / `filter_highpass_fft()`: fixed an asymmetric frequency-domain mask that halved the passband amplitude. Lowpass + highpass at the same cutoff now reconstruct the input exactly.
* `filter_na_speed()` now flags single-frame outliers correctly (the outlier itself is blanked, not its neighbours), and a single NA in the input no longer contaminates adjacent rows (#14).
* `filter_aniframe()` works on aniframes without an `individual` column. Identity columns now come from `variables_what`, spatial columns from `variables_where` (#16).
* `find_peaks()` / `find_troughs()`: prominence now matches the documented topographic definition (saddle = max of left/right valley min). Previously could overestimate prominence and let peaks slip past `min_prominence`.
* `filter_sgolay()`: `preserve_edges` had two bugs and is removed — `signal::sgolayfilt()` already handles edges correctly.
* `filter_kalman()` documentation: corrected the default `base_Q` formula.
* `replace_na_stine()` and the inline installer in `filter_bandwidth.R` now point at the current r-universe (#17).

## Changed

* `filter_sgolay()`: dropped `preserve_edges`.
* `filter_rollmean()` / `filter_rollmedian()`: dropped `...`, gained an explicit `align` argument (#7).
* `data.table (>= 1.18.0)` promoted from `Suggests` to `Imports` (now backs the rolling filters and the LOCF interpolation step).
* Removed `roll`, `collapse`, and `animetric`.

# aniprocess 0.1.2

## Added

* A `NEWS.md` file, to track changes to the package.

## Changed

* Updated to the tidy movement data model of aniframe 0.4.0.
* `filter_na_speed()` uses `differentiate()` from animetric rather than its own derivative.
* `filter_na_roi()` accepts 3D regions of interest.

# aniprocess 0.1.1

The package takes its present shape: masking, gap filling and smoothing.

## Added

* NA masking: `filter_na_confidence()`, `filter_na_speed()`, `filter_na_range()` and `filter_na_roi()`.
* Gap filling: `replace_na_linear()`, `replace_na_spline()`, `replace_na_stine()`, `replace_na_locf()`, `replace_na_value()` and the generic `replace_na()`.
* Smoothing and filtering: `filter_sgolay()`, `filter_rollmean()`, `filter_rollmedian()`, `filter_lowpass()`, `filter_highpass()`, their `_fft()` counterparts, `filter_kalman()` and `filter_kalman_irregular()`.
* Peak detection: `find_peaks()` and `find_troughs()`.
* `filter_aniframe()`, the frame-level entry point.

# aniprocess 0.1.0

Package skeleton. No filters yet.

