# aniprocess 0.2.0 (development version)

* `filter_na_speed()` now flags single-frame outliers correctly. Speed at each
  row is the minimum of the backward and forward step speeds, so a row is only
  flagged when both the step in and the step out are fast (#14). The previous
  central-difference implementation read the slope through neighbors and
  therefore left the outlier itself untouched while blanking its neighbors.
* NA contamination is now limited: a missing coordinate at row `i` no longer
  affects the speed estimate at neighboring rows.
* Removed dependency on `animetric` (was only used by `filter_na_speed()`).

# aniprocess 0.1.2

* Added a `NEWS.md` file to track changes to the package.
* Update to work with tidy movement logic.
* Use `differentiate` from *animetric* for `filter_na_speed`.
* `filter_na_roi` now works with 3D ROIs.
