# Tests for filter_gaussian
#
# - Returns numeric vector of same length as input
# - Basic smoothing reduces noise (variance decreases)
# - Window size validation (positive integer, smaller than data)
# - Alpha validation (positive number)
# - x validation (must be numeric)
# - NA handling with different na_action methods
# - keep_na restores NAs to original positions
# - keep_edges = FALSE sets edge values to NA
# - keep_edges = TRUE returns no NAs (when input has none)
# - Larger window_size produces more smoothing
# - Different alpha values affect smoothing

test_that("filter_gaussian returns numeric vector of same length", {
  x <- rnorm(100)
  result <- filter_gaussian(x)

  expect_type(result, "double")
  expect_length(result, length(x))
})

test_that("filter_gaussian reduces noise", {
  set.seed(123)
  signal <- sin(seq(0, 4 * pi, length.out = 100))
  noisy <- signal + rnorm(100, sd = 0.5)

  smoothed <- filter_gaussian(noisy, window_size = 11)

  # Smoothed should be closer to true signal than noisy input
  expect_lt(
    sum((smoothed - signal)^2),
    sum((noisy - signal)^2)
  )
})

test_that("filter_gaussian validates x", {
  expect_error(
    filter_gaussian(x = "not numeric"),
    "must be numeric"
  )

  expect_error(
    filter_gaussian(x = list(1, 2, 3)),
    "must be numeric"
  )
})

test_that("filter_gaussian validates window_size", {
  x <- rnorm(100)

  expect_error(
    filter_gaussian(x, window_size = -5),
    "must be a positive integer"
  )

  expect_error(
    filter_gaussian(x, window_size = 0),
    "must be a positive integer"
  )

  expect_error(
    filter_gaussian(x, window_size = 100),
    "must be smaller than data length"
  )

  expect_error(
    filter_gaussian(x, window_size = 150),
    "must be smaller than data length"
  )
})

test_that("filter_gaussian validates alpha", {
  x <- rnorm(100)

  expect_error(
    filter_gaussian(x, alpha = -1),
    "must be a positive number"
  )

  expect_error(
    filter_gaussian(x, alpha = 0),
    "must be a positive number"
  )

  expect_error(
    filter_gaussian(x, alpha = "high"),
    "must be a positive number"
  )
})

test_that("filter_gaussian handles NA with na_action = 'error'
", {
  x <- c(1, 2, NA, 4, 5, 6, 7, 8, 9, 10)

  expect_error(
    filter_gaussian(x, window_size = 3L, na_action = "error"),
    "contains NA values"
  )
})
test_that("filter_gaussian handles NA with interpolation methods", {
  x <- c(1, 2, NA, 4, 5, 6, 7, 8, 9, 10)

  expect_no_error(filter_gaussian(x, window_size = 3L, na_action = "linear"))
  expect_no_error(filter_gaussian(x, window_size = 3L, na_action = "spline"))
  expect_no_error(filter_gaussian(x, window_size = 3L, na_action = "locf"))

  # Results should have no NAs when keep_na = FALSE
  result <- filter_gaussian(
    x,
    window_size = 3L,
    na_action = "linear",
    keep_na = FALSE
  )
  expect_false(any(is.na(result)))
})

test_that("filter_gaussian respects keep_na", {
  x <- c(1, 2, NA, 4, 5, NA, 7, 8, 9, 10)
  na_positions <- which(is.na(x))

  result <- filter_gaussian(
    x,
    window_size = 3L,
    na_action = "linear",
    keep_na = TRUE
  )

  expect_true(all(is.na(result[na_positions])))
  expect_false(any(is.na(result[-na_positions])))
})

test_that("filter_gaussian keep_edges = FALSE sets edges to NA", {
  x <- rnorm(100)

  result <- filter_gaussian(x, window_size = 11, keep_edges = FALSE)

  # With window_size = 11, half_left = 5
  expect_true(all(is.na(result[1:5])))
  expect_true(all(is.na(result[96:100])))
  expect_false(any(is.na(result[6:95])))
})

test_that("filter_gaussian keep_edges = TRUE returns no edge NAs", {
  x <- rnorm(100)

  result <- filter_gaussian(x, window_size = 11, keep_edges = TRUE)

  expect_false(any(is.na(result)))
})

test_that("larger window_size produces more smoothing", {
  set.seed(456)
  x <- rnorm(100)

  small_window <- filter_gaussian(x, window_size = 5)
  large_window <- filter_gaussian(x, window_size = 21)

  # Larger window should have lower variance (more smoothing)
  expect_lt(var(large_window), var(small_window))
})

test_that("alpha affects smoothing characteristics", {
  set.seed(789)
  x <- rnorm(100)

  low_alpha <- filter_gaussian(x, window_size = 11, alpha = 1.5)
  high_alpha <- filter_gaussian(x, window_size = 11, alpha = 4)

  # Lower alpha = broader kernel = more smoothing = lower variance
  expect_lt(var(low_alpha), var(high_alpha))
})

test_that("filter_gaussian works with minimum viable input", {
  x <- c(1, 2, 3, 4, 5)

  result <- filter_gaussian(x, window_size = 3)

  expect_length(result, 5)
  expect_false(any(is.na(result)))
})

test_that("filter_gaussian coerces window_size to integer", {
  x <- rnorm(100)

  # Should work with numeric that can be coerced
  result <- filter_gaussian(x, window_size = 11.7)

  expect_length(result, 100)
})
