# Tests for replace_na_across()
# - Every method is forwarded to replace_na_with()
# - Gap constraints are forwarded
# - `variables` restricts which columns are filled
# - Grouping is respected: a gap is never filled across a track boundary

gap_fixture <- function() {
  np <- 10
  d <- anicore::aniframe(
    time = rep(seq_len(np), 2),
    individual = rep(c("a", "b"), each = np),
    x = c(c(1, NA, 3, 4, 5, 6, 7, 8, 9, 10), c(101:110)),
    y = c(seq_len(np), c(201, NA, 203:210)),
    variables_what = "individual"
  ) |>
    dplyr::group_by(individual)
  d
}

test_that("replace_na_across forwards every method", {
  d <- gap_fixture()

  for (m in c("linear", "spline", "stine", "locf")) {
    out <- replace_na_across(d, m)
    expect_false(is.na(out$x[2]), info = m)
    expect_false(is.na(out$y[12]), info = m)
  }

  out <- replace_na_across(d, "value", value = -1)
  expect_equal(out$x[2], -1)
  expect_equal(out$y[12], -1)
})

test_that("replace_na_across forwards gap constraints", {
  d <- gap_fixture()

  # A single-frame gap is below min_gap = 2, so it stays NA
  out <- replace_na_across(d, "linear", min_gap = 2)
  expect_true(is.na(out$x[2]))

  out <- replace_na_across(d, "linear", max_gap = 1)
  expect_false(is.na(out$x[2]))
})

test_that("replace_na_across restricts to the selected variables", {
  d <- gap_fixture()

  out <- replace_na_across(d, "linear", variables = x)
  expect_false(is.na(out$x[2]))
  expect_true(is.na(out$y[12]))
})

test_that("replace_na_across fills within groups only", {
  # Track a ends with a gap; track b starts far away. A cross-boundary
  # fill would interpolate between the two.
  np <- 5
  d <- anicore::aniframe(
    time = rep(seq_len(np), 2),
    individual = rep(c("a", "b"), each = np),
    x = c(c(1, 2, 3, 4, NA), c(1000, 1001, 1002, 1003, 1004)),
    y = rep(0, 2 * np),
    variables_what = "individual"
  ) |>
    dplyr::group_by(individual)

  out <- replace_na_across(d, "locf")
  # Carried forward from within track a, not pulled toward track b
  expect_equal(out$x[5], 4)
})

test_that("replace_na_across matches replace_na_with per column", {
  d <- gap_fixture()
  out <- replace_na_across(d, "linear")

  expect_equal(out$x[1:10], replace_na_with(d$x[1:10], "linear"))
})

test_that("replace_na_across returns an aniframe and preserves grouping", {
  d <- gap_fixture()
  out <- replace_na_across(d, "linear")

  expect_s3_class(out, "aniframe")
  expect_equal(dplyr::group_vars(out), "individual")
})

test_that("replace_na_across rejects an unknown method", {
  expect_error(replace_na_across(gap_fixture(), "nope"), "should be one of")
})
