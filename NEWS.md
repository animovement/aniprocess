# aniprocess 0.2.0 (development version)

* `filter_lowpass_fft()` / `filter_highpass_fft()`: fixed a Hermitian-
  symmetry bug in the frequency-domain mask construction. The previous
  code overwrote both spectral halves with a recycled-and-mirrored
  version of itself due to a length mismatch, producing an asymmetric
  mask. After `Re()` of the inverse FFT, this dropped half of the
  passband signal energy — a 2 Hz sinusoid passed through a 5 Hz
  low-pass came out at half its input amplitude. Now passband signals
  are preserved (`out_RMS ≈ in_RMS`), and `filter_lowpass_fft + filter_highpass_fft`
  at the same cutoff exactly reconstructs the input. Added a dedicated
  test file for the FFT filters with passband / stopband / complementary-
  pair / NA / `keep_na` / validation tests.
* `find_peaks()` / `find_troughs()`: prominence is now computed
  according to the standard topographic definition documented in the
  function help — `peak − max(min(left_valley), min(right_valley))` —
  instead of `peak − min(everything in the surrounding valley)`. The
  two definitions only diverge when the left and right valley minima
  differ; in that case the previous implementation overestimated
  prominence, so a peak that should have been excluded by
  `min_prominence` could slip through. Behaviour now matches
  `pracma::findpeaks` and SciPy's `find_peaks`.
* Two internal validation helpers added: `ensure_replace_na_args()`
  consolidates the checks shared across the `replace_na_*()` family;
  `ensure_aniframe_spatial()` consolidates the ensure-is-aniframe +
  variables_where-present + numeric checks shared across the
  aniframe-aware filters.
* Removed three dead files (`R/calculate_speed.R`,
  `R/filter_na_poses.R`, `R/replace_na_aniframe.R`) and several dead
  branches in `R/find_extrema.R`. Future work tracked in #29
  (`filter_by_pose`) and #30 (across-style API).

* New filter `filter_ccma()`: Curvature-Corrected Moving Average
  (Steinecker & Wuensche, 2023). Smooths a 2D or 3D Cartesian
  trajectory while undoing the inward "corner-cutting" bias that a
  plain moving average introduces on curved paths. Operates on the
  spatial coordinates jointly (rather than per column) and respects
  the aniframe's existing grouping. Rejects polar / cylindrical /
  spherical (and `unknown`) aniframes by checking the
  `coordinate_system` metadata directly, since the underlying
  curvature math (cross product, Euclidean norm, circumradius) is
  Cartesian-specific. Hanning and uniform kernels supported in this
  release; padding boundary mode (#11).
* New filter `filter_na_excursion()`: flags multi-frame tracking
  excursions — jumps that eventually return to where they started, or
  to the typical resting position. Implements Todd, Kain & de Bivort
  (2017): a frame-to-frame jump greater than `outlier_sd` standard
  deviations starts an excursion, which is rejected only if the
  trajectory returns within `outlier_sd σ` of the pre-excursion
  position or `return_sd σ` of the overall median position. Defaults
  match the paper (`outlier_sd = 5`, `return_sd = 1`). Per-axis by
  default (Todd's literal behaviour); `by_axis = FALSE` gives a joint-
  Euclidean variant consistent with `filter_na_speed()` (#13).
* `filter_sgolay()`: removed the `preserve_edges` argument. The
  hand-rolled edge handling had two bugs (positions 1 and 2 were left
  as raw input, and the right-edge slice was off-by-one), and the
  default behaviour from `signal::sgolayfilt()` already handles edges
  correctly via extrapolation from the nearest interior polynomial fit
  — the standard Savitzky-Golay convention. Added a polynomial-
  reproduction test that locks in the SG defining property.
* `filter_kalman()`: the documentation incorrectly stated that the
  default `base_Q ≈ 0.15 / sampling_rate`. The actual default has
  always been `var(measurements) / sampling_rate`; the docstring is now
  rewritten to match. Added correctness tests covering the
  hand-computed first update, limit behaviours (`R → ∞` ignores
  measurements; `R → 0` tracks them), and convergence to a constant
  truth.
* New filter `filter_gaussian()`: Gaussian kernel smoother. Native
  implementation (no extra dependency) with NA-aware weight
  renormalisation at edges and around isolated `NA`s. Parameterised by
  `sigma` (in samples); `window_width` is derived from `sigma` by
  default. Wired into `filter_aniframe(method = "gaussian")` (#1).
* New filter `filter_triangular()`: triangular smoother implemented as
  two passes of `filter_rollmean()`. Effective kernel width is
  `2 * window_width - 1`. Wired into
  `filter_aniframe(method = "triangular")` (#1).
* `filter_aniframe()` now reads identity columns from the `variables_what`
  metadata field and spatial columns from `variables_where`, instead of
  hard-coding `individual` / `keypoint` / `x` / `y` / `z`. Identity columns
  named in metadata but absent from the data are silently skipped, so the
  function works on single-track data (e.g. Octron) without an `individual`
  column (#16).
* `filter_na_speed()` now flags single-frame outliers correctly. Speed at each
  row is the minimum of the backward and forward step speeds, so a row is only
  flagged when both the step in and the step out are fast (#14). The previous
  central-difference implementation read the slope through neighbors and
  therefore left the outlier itself untouched while blanking its neighbors.
* NA contamination is now limited: a missing coordinate at row `i` no longer
  affects the speed estimate at neighboring rows.
* Removed dependency on `animetric` (was only used by `filter_na_speed()`).
* Point `replace_na_stine()` and `filter_bandwidth.R`'s inline package
  installer at `animovement.r-universe.dev` (#17). Both were still
  referencing the old `roaldarbol` r-universe after the repo move.
  Both call sites now route through `check_*()` helpers in
  `R/check_installed.R` (added `check_stinepack()`, replaced an inline
  `check_installed("signal", …)` in `filter_highpass()` with
  `check_signal()`) so the canonical URL only lives in one place.
* `filter_rollmean()` and `filter_rollmedian()` now use
  `data.table::frollmean()` / `frollmedian()` instead of the `roll`
  package (#7). `data.table` is the rolling-function backend already used
  elsewhere in animovement and is more actively maintained. Both filters
  gain an `align` argument (`"right"` (default), `"left"`, `"center"`)
  and drop the `...` passthrough — only the wrapper's documented
  parameters are accepted now.
* `roll` is no longer a dependency.
* `replace_na_locf()` and `replace_na_stine()` now use
  `data.table::nafill(type = "locf")` for the LOCF step instead of
  `collapse::na_locf()`. `data.table` was already needed for the rolling
  filters; consolidating on it lets us drop `collapse` as a dependency.
  Same behaviour, comparable performance. `data.table` is now in
  `Imports` rather than `Suggests` since it backs four functions in the
  package, and `check_data_table()` is no longer needed.

# aniprocess 0.1.2

* Added a `NEWS.md` file to track changes to the package.
* Update to work with tidy movement logic.
* Use `differentiate` from *animetric* for `filter_na_speed`.
* `filter_na_roi` now works with 3D ROIs.
