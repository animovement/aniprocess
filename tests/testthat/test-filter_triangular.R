# Tests for filter_triangular
# - Equals two passes of filter_rollmean
# - Dampens an outlier
# - Constant input passes through unchanged
# - NA edges with center alignment match filter_rollmean's behaviour
# - Default align is "center"

test_that("filter_triangular equals two filter_rollmean passes", {
  x <- c(1, 2, 3, 100, 5, 6, 7, 8, 9, 10)
  expected <- filter_rollmean(
    filter_rollmean(x, window_width = 3, align = "right"),
    window_width = 3,
    align = "right"
  )
  result <- filter_triangular(x, window_width = 3, align = "right")
  expect_equal(result, expected)
})

test_that("filter_triangular dampens a single outlier", {
  x <- c(1, 2, 3, 100, 5, 6, 7, 8, 9)
  result <- filter_triangular(x, window_width = 3, align = "right")
  expect_lt(result[4], 50)
  expect_gt(result[4], 1)
})

test_that("filter_triangular preserves a constant signal", {
  x <- rep(5, 20)
  expect_equal(filter_triangular(x, window_width = 3, align = "right"), x)
})

test_that("filter_triangular has NA edges with center alignment", {
  x <- 1:10
  result <- filter_triangular(x, window_width = 3, align = "center")
  # filter_rollmean(align="center") returns NA at the first/last (w-1)/2 positions.
  # Two passes amplify this; expect at least one NA at each edge.
  expect_true(is.na(result[1]))
  expect_true(is.na(result[length(result)]))
})

test_that("filter_triangular default align is center", {
  x <- 1:10
  expect_equal(
    filter_triangular(x, window_width = 3),
    filter_triangular(x, window_width = 3, align = "center")
  )
})
