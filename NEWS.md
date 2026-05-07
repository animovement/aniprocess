# aniprocess 0.2.0 (development version)

* Point `replace_na_stine()` and `filter_bandwidth.R`'s inline package
  installer at `animovement.r-universe.dev` (#17). Both were still
  referencing the old `roaldarbol` r-universe after the repo move.

# aniprocess 0.1.2

* Added a `NEWS.md` file to track changes to the package.
* Update to work with tidy movement logic.
* Use `differentiate` from *animetric* for `filter_na_speed`.
* `filter_na_roi` now works with 3D ROIs.
