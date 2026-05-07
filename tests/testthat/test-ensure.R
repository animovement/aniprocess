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

test_that("ensure_aniframe_spatial accepts a valid aniframe", {
  d <- aniframe::aniframe(
    time = 1:5,
    x = 1:5,
    y = 1:5,
    variables_what = character(0)
  )
  expect_invisible(ensure_aniframe_spatial(d))
  expect_identical(ensure_aniframe_spatial(d), d)
})

test_that("ensure_aniframe_spatial rejects non-aniframe input", {
  d <- data.frame(time = 1:5, x = 1:5, y = 1:5)
  expect_error(ensure_aniframe_spatial(d), class = "rlang_error")
})

test_that("ensure_aniframe_spatial reports the missing column by name", {
  d <- aniframe::aniframe(
    time = 1:5,
    x = 1:5,
    y = 1:5,
    variables_what = character(0)
  )
  d <- aniframe::set_metadata(d, variables_where = c("x", "y", "z"))
  expect_error(ensure_aniframe_spatial(d), "Missing spatial column.*z")
})

test_that("ensure_aniframe_spatial reports the non-numeric column by name", {
  d <- aniframe::aniframe(
    time = 1:5,
    x = 1:5,
    y = 1:5,
    variables_what = character(0)
  )
  d$x <- as.character(d$x)
  expect_error(ensure_aniframe_spatial(d), "Column.*x.*must be numeric")
})
