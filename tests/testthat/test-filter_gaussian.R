# Tests for filter_gaussian
# - Reduces an outlier (smoothing actually does something)
# - Constant input passes through unchanged
# - NA in middle is filled (kernel weights renormalised over neighbours)
# - All-NA window returns NA
# - Default window_width derived from sigma
# - Even window_width is rounded up to odd
# - Validates sigma and window_width

test_that("filter_gaussian dampens a single outlier", {
  x <- c(1, 2, 3, 100, 5, 6, 7, 8, 9)
  # sigma = 2 spreads the kernel enough to pull the outlier well below itself
  result <- filter_gaussian(x, sigma = 2)
  expect_lt(result[4], 50)
  expect_gt(result[4], 5)
})

test_that("filter_gaussian preserves a constant signal", {
  x <- rep(5, 20)
  expect_equal(filter_gaussian(x, sigma = 2), x)
})

test_that("filter_gaussian fills isolated NA via weight renormalisation", {
  x <- c(1, 2, 3, NA, 5, 6, 7, 8, 9)
  result <- filter_gaussian(x, sigma = 1)
  # Position 4 was NA in input but should not be NA in output
  expect_false(is.na(result[4]))
  # Should be approximately the average of nearby non-NA values (around 4)
  expect_gt(result[4], 3)
  expect_lt(result[4], 5)
})

test_that("filter_gaussian returns NA for all-NA window", {
  x <- c(NA_real_, NA_real_, NA_real_, NA_real_, NA_real_)
  result <- filter_gaussian(x, sigma = 1)
  expect_true(all(is.na(result)))
  expect_false(any(is.nan(result)))
})

test_that("filter_gaussian default window_width is 2*ceiling(3*sigma)+1", {
  # We can't directly inspect window_width, but we can check that sigma=1
  # gives window_width=7 by checking that values at offset 4 don't influence
  # the centre. Use an impulse: zeros except a 1 at position 1.
  x <- c(1, rep(0, 9))
  # With sigma=1, window=7, half=3 — position 1 + offset 3 = position 4 is in
  # window; position 5 is out. Output at position 5 should be 0.
  result <- filter_gaussian(x, sigma = 1)
  expect_equal(result[5], 0)
})

test_that("filter_gaussian rounds even window_width up to odd", {
  # window_width = 4 should become 5; check by computing impulse response
  # length: result at position 4 from impulse at position 1 with width=5
  # (half=2) is out of range, so should be 0.
  x <- c(1, rep(0, 9))
  result <- filter_gaussian(x, sigma = 1, window_width = 4)
  expect_equal(result[4], 0)
})

test_that("filter_gaussian validates sigma", {
  expect_error(filter_gaussian(1:5, sigma = 0))
  expect_error(filter_gaussian(1:5, sigma = -1))
  expect_error(filter_gaussian(1:5, sigma = c(1, 2)))
})

test_that("filter_gaussian validates window_width", {
  expect_error(filter_gaussian(1:5, sigma = 1, window_width = 0))
  expect_error(filter_gaussian(1:5, sigma = 1, window_width = -1))
})
