# Tests for the internal ensure_* helpers used by the replace_na_*
# family. These cover the validation paths that the public
# replace_na_*() functions delegate to.

test_that("ensure_replace_na_args rejects non-numeric input", {
  expect_error(
    ensure_replace_na_args("not numeric", min_gap = 1, max_gap = Inf),
    "Input must be numeric"
  )
  expect_error(
    ensure_replace_na_args(factor(1:3), min_gap = 1, max_gap = Inf),
    "Input must be numeric"
  )
})

test_that("ensure_replace_na_args rejects min_gap < 1", {
  expect_error(
    ensure_replace_na_args(1:5, min_gap = 0, max_gap = Inf),
    "min_gap must be >= 1"
  )
  expect_error(
    ensure_replace_na_args(1:5, min_gap = -1, max_gap = Inf),
    "min_gap must be >= 1"
  )
})

test_that("ensure_replace_na_args rejects max_gap < min_gap", {
  expect_error(
    ensure_replace_na_args(1:5, min_gap = 3, max_gap = 2),
    "max_gap must be >= min_gap"
  )
})

test_that("ensure_replace_na_args returns invisibly on valid input", {
  expect_silent(ensure_replace_na_args(1:5, min_gap = 1, max_gap = Inf))
  expect_invisible(ensure_replace_na_args(1:5, min_gap = 1, max_gap = Inf))
  expect_null(ensure_replace_na_args(1:5, min_gap = 1, max_gap = Inf))
})

test_that("ensure_coords() names the aniframe tier when it knows it", {
  af <- anicore::example_aniframe(n_obs = 5, n_individuals = 1, n_keypoints = 1)

  with_hint <- tryCatch(
    ensure_coords(af, across = "filter_na_across"),
    error = function(e) e
  )
  without <- tryCatch(ensure_coords(af), error = function(e) e)
  expect_match(conditionMessage(with_hint), "must be numeric")

  expect_true(any(grepl("filter_na_across", with_hint$body)))
  expect_true(any(grepl("Pass the spatial columns", without$body)))
})

test_that("ensure_coords() still rejects a non-data-frame", {
  expect_error(ensure_coords(1:5), "aniframe or a data frame")
})
