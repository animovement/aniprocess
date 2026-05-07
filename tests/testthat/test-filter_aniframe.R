# Tests for filter_aniframe
# - Default example_aniframe (groups by individual + keypoint)
# - Custom variables_what (e.g. single "track" column)
# - Single-track data with no identity columns at all (#16 repro)
# - Robustness when variables_what metadata names a column not in the data
# - Errors when a variables_where column is missing
# - Filters z when listed in variables_where
# - use_derivatives branch (derive -> filter -> integrate)
# - triangular and gaussian methods dispatch correctly
# - Rejects non-aniframe input
# - Returns an aniframe

test_that("filter_aniframe works with default example_aniframe", {
  d <- aniframe::example_aniframe()
  expect_no_error(filter_aniframe(d))
  expect_s3_class(filter_aniframe(d), "aniframe")
})

test_that("filter_aniframe works with a single custom identity column", {
  n <- 20
  d <- aniframe::aniframe(
    track = rep(c("a", "b"), each = n / 2),
    time = rep(1:(n / 2), 2),
    x = rnorm(n),
    y = rnorm(n),
    variables_what = "track"
  )
  expect_no_error(filter_aniframe(d, "rollmean", window_width = 3, min_obs = 1))
})

test_that("filter_aniframe works without an `individual` column (#16)", {
  # Single trajectory, no identity columns at all.
  # Reproduces the failure path reported in #16.
  d <- aniframe::aniframe(
    time = 1:20,
    x = rnorm(20),
    y = rnorm(20),
    variables_what = character(0)
  )
  expect_no_error(filter_aniframe(d, "rollmean", window_width = 3, min_obs = 1))
})

test_that("filter_aniframe is robust when variables_what names a missing column", {
  # aniframe sometimes carries a default variables_what (e.g. "keypoint")
  # even when the column is absent. The function should silently skip those.
  d <- aniframe::aniframe(
    time = 1:20,
    x = rnorm(20),
    y = rnorm(20)
  )
  expect_no_error(filter_aniframe(d, "rollmean", window_width = 3, min_obs = 1))
})

test_that("filter_aniframe errors when a variables_where column is missing", {
  d <- aniframe::aniframe(
    time = 1:5,
    x = 1:5,
    y = 1:5
  )
  d <- aniframe::set_metadata(d, variables_where = c("x", "y", "z"))
  expect_error(filter_aniframe(d), "Missing spatial column")
})

test_that("filter_aniframe filters z when present", {
  n <- 20
  d <- aniframe::aniframe(
    time = 1:n,
    x = rnorm(n),
    y = rnorm(n),
    z = rnorm(n),
    variables_where = c("x", "y", "z")
  )
  result <- filter_aniframe(d, "rollmean", window_width = 3, min_obs = 1)
  # All three spatial columns should have been smoothed (different from input)
  expect_false(identical(result$x, d$x))
  expect_false(identical(result$y, d$y))
  expect_false(identical(result$z, d$z))
})

test_that("filter_aniframe handles use_derivatives", {
  n <- 20
  d <- aniframe::aniframe(
    time = 1:n,
    x = cumsum(rnorm(n)),
    y = cumsum(rnorm(n)),
    variables_what = character(0)
  )
  expect_no_error(
    filter_aniframe(
      d,
      "rollmean",
      window_width = 3,
      min_obs = 1,
      use_derivatives = TRUE
    )
  )
})

test_that("filter_aniframe dispatches to triangular and gaussian", {
  n <- 30
  d <- aniframe::aniframe(
    time = 1:n,
    x = cumsum(rnorm(n)),
    y = cumsum(rnorm(n)),
    variables_what = character(0)
  )
  expect_no_error(
    filter_aniframe(d, "triangular", window_width = 3, align = "right")
  )
  expect_no_error(filter_aniframe(d, "gaussian", sigma = 1))
  # Gaussian smoothing actually changes the data
  result <- filter_aniframe(d, "gaussian", sigma = 1)
  expect_false(identical(result$x, d$x))
})

test_that("filter_aniframe rejects non-aniframe input", {
  d <- data.frame(time = 1:5, x = 1:5, y = 1:5)
  expect_error(filter_aniframe(d), class = "rlang_error")
})
