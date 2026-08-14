# Tests for filter_rollmean
# - Computes correct values on simple inputs (right alignment)
# - Left and center alignment work
# - Handles NAs (na.rm semantics)
# - Partial windows at edges for right/left alignment
# - NA edges for center alignment
# - min_obs masks rows with too few observations
# - Returns NA (not NaN) for all-NA windows

test_that("filter_rollmean computes correct values (right align)", {
  x <- c(1, 2, 3, 4, 5)
  expect_equal(
    filter_rollmean(x, window_width = 3, align = "right"),
    c(1, 1.5, 2, 3, 4)
  )
})

test_that("filter_rollmean center alignment leaves NA at edges", {
  x <- c(1, 2, 3, 4, 5)
  result <- filter_rollmean(x, window_width = 3, align = "center")
  expect_true(is.na(result[1]))
  expect_equal(result[2], 2)
  expect_equal(result[3], 3)
  expect_equal(result[4], 4)
  expect_true(is.na(result[5]))
})

test_that("filter_rollmean left alignment uses partial windows at end", {
  x <- c(1, 2, 3, 4, 5)
  result <- filter_rollmean(x, window_width = 3, align = "left")
  expect_equal(result, c(2, 3, 4, 4.5, 5))
})

test_that("filter_rollmean handles NAs", {
  x <- c(1, NA, 3, 4, 5)
  result <- filter_rollmean(
    x,
    window_width = 3,
    align = "right",
    keep_na = FALSE
  )
  # window at i=2: c(1, NA) -> mean = 1
  # window at i=3: c(1, NA, 3) -> mean = 2
  # window at i=4: c(NA, 3, 4) -> mean = 3.5
  # window at i=5: c(3, 4, 5) -> mean = 4
  expect_equal(result, c(1, 1, 2, 3.5, 4))
})

test_that("filter_rollmean preserves input NAs by default", {
  x <- c(1, NA, 3, 4, 5)
  result <- filter_rollmean(x, window_width = 3, align = "right")
  # Position 2 was NA in the input, so it stays NA regardless of the
  # window having enough observations to produce a value.
  expect_equal(result, c(1, NA, 2, 3.5, 4))
})

test_that("filter_rollmean returns NA for all-NA windows (not NaN)", {
  x <- c(NA_real_, NA_real_, NA_real_, 4, 5)
  result <- filter_rollmean(x, window_width = 3, align = "right")
  expect_true(is.na(result[1]))
  expect_true(is.na(result[2]))
  expect_true(is.na(result[3]))
  expect_false(is.nan(result[1]))
  expect_equal(result[4], 4)
  expect_equal(result[5], 4.5)
})

test_that("filter_rollmean masks rows with fewer than min_obs non-NA values", {
  x <- c(1, NA, NA, 4, 5)
  result <- filter_rollmean(x, window_width = 3, min_obs = 2, align = "right")
  # i=1: 1 obs (1) -> NA (min_obs=2)
  # i=2: 1 obs (1) -> NA
  # i=3: 1 obs (1) -> NA
  # i=4: 2 obs (NA, 4) wait, window covers c(NA, NA, 4) -> 1 obs -> NA
  # i=5: window c(NA, 4, 5) -> 2 obs -> mean = 4.5
  expect_true(is.na(result[1]))
  expect_true(is.na(result[2]))
  expect_true(is.na(result[3]))
  expect_true(is.na(result[4]))
  expect_equal(result[5], 4.5)
})

test_that("filter_rollmean validates align argument", {
  expect_error(filter_rollmean(1:5, align = "bogus"))
})
