# aniprocess 0.2.0 (development version)

* New filter `filter_ccma()`: Curvature-Corrected Moving Average
  (Steinecker & Wuensche, 2023). Smooths a 2D or 3D trajectory while
  undoing the inward "corner-cutting" bias that a plain moving average
  introduces on curved paths. Operates on the spatial coordinates
  jointly (rather than per column) and respects the aniframe's existing
  grouping. Hanning and uniform kernels supported in this release;
  padding boundary mode (#11).
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

# aniprocess 0.1.2

* Added a `NEWS.md` file to track changes to the package.
* Update to work with tidy movement logic.
* Use `differentiate` from *animetric* for `filter_na_speed`.
* `filter_na_roi` now works with 3D ROIs.
