# Tests for filter_rollmedian
# - Computes correct values on simple inputs (right alignment)
# - Robust to outliers (median property)
# - Handles NAs (na.rm semantics)
# - Partial windows at edges for right/left alignment
# - NA edges for center alignment
# - min_obs masks rows with too few observations
# - Returns NA (not NaN) for all-NA windows

test_that("filter_rollmedian computes correct values (right align)", {
  x <- c(1, 2, 3, 4, 5)
  expect_equal(
    filter_rollmedian(x, window_width = 3, align = "right"),
    c(1, 1.5, 2, 3, 4)
  )
})

test_that("filter_rollmedian is robust to a single outlier", {
  # Plain mean would smear the outlier; median should ignore it.
  x <- c(1, 2, 100, 4, 5, 6, 7)
  result <- filter_rollmedian(x, window_width = 3, align = "center")
  # Centered window at i=3: c(2, 100, 4) -> median = 4
  # Centered window at i=4: c(100, 4, 5) -> median = 5
  expect_equal(result[3], 4)
  expect_equal(result[4], 5)
})

test_that("filter_rollmedian center alignment leaves NA at edges", {
  x <- c(1, 2, 3, 4, 5)
  result <- filter_rollmedian(x, window_width = 3, align = "center")
  expect_true(is.na(result[1]))
  expect_true(is.na(result[5]))
  expect_equal(result[2:4], c(2, 3, 4))
})

test_that("filter_rollmedian handles NAs", {
  x <- c(1, NA, 3, 4, 5)
  result <- filter_rollmedian(
    x,
    window_width = 3,
    align = "right",
    keep_na = FALSE
  )
  # i=2: c(1, NA) -> median(1) = 1
  # i=3: c(1, NA, 3) -> median(c(1,3)) = 2
  # i=4: c(NA, 3, 4) -> median(c(3,4)) = 3.5
  # i=5: c(3, 4, 5) -> median = 4
  expect_equal(result, c(1, 1, 2, 3.5, 4))
})

test_that("filter_rollmedian preserves input NAs by default", {
  x <- c(1, NA, 3, 4, 5)
  result <- filter_rollmedian(x, window_width = 3, align = "right")
  expect_equal(result, c(1, NA, 2, 3.5, 4))
})

test_that("filter_rollmedian returns NA for all-NA windows", {
  x <- c(NA_real_, NA_real_, NA_real_, 4, 5)
  result <- filter_rollmedian(x, window_width = 3, align = "right")
  expect_true(all(is.na(result[1:3])))
  expect_false(any(is.nan(result[1:3])))
})

test_that("filter_rollmedian masks rows with fewer than min_obs non-NA", {
  x <- c(1, NA, NA, 4, 5)
  result <- filter_rollmedian(
    x,
    window_width = 3,
    min_obs = 2,
    align = "right"
  )
  expect_true(is.na(result[1]))
  expect_true(is.na(result[4]))
  expect_equal(result[5], 4.5)
})
