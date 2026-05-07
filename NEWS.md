# aniprocess 0.2.0 (development version)

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
