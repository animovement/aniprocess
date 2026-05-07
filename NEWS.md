# aniprocess 0.2.0 (development version)

* `filter_aniframe()` now reads identity columns from the `variables_what`
  metadata field and spatial columns from `variables_where`, instead of
  hard-coding `individual` / `keypoint` / `x` / `y` / `z`. Identity columns
  named in metadata but absent from the data are silently skipped, so the
  function works on single-track data (e.g. Octron) without an `individual`
  column (#16).

# aniprocess 0.1.2

* Added a `NEWS.md` file to track changes to the package.
* Update to work with tidy movement logic.
* Use `differentiate` from *animetric* for `filter_na_speed`.
* `filter_na_roi` now works with 3D ROIs.
