# Tests for filter_na_range
# - Basic filtering with min and max
# - Edge cases: Inf, -Inf, equal min/max
# - Preserves existing NAs
# - Validates input types
# - Validates min/max are single numeric values
# - Validates min <= max

test_that("filter_na_range filters values outside range", {
  expect_equal(
    filter_na_range(c(1, 5, 10, 15), min = 3, max = 12),
    c(NA, 5, 10, NA)
  )

  expect_equal(
    filter_na_range(c(1, 5, 10, 15), min = 5),
    c(NA, 5, 10, 15)
  )

  expect_equal(
    filter_na_range(c(1, 5, 10, 15), max = 10),
    c(1, 5, 10, NA)
  )
})

test_that("filter_na_range handles edge cases", {
  # No filtering with defaults
  expect_equal(
    filter_na_range(c(1, 5, 10)),
    c(1, 5, 10)
  )

  # Equal min and max
  expect_equal(
    filter_na_range(c(1, 5, 10), min = 5, max = 5),
    c(NA, 5, NA)
  )

  # Negative values
  expect_equal(
    filter_na_range(c(-10, -5, 0, 5, 10), min = -5, max = 5),
    c(NA, -5, 0, 5, NA)
  )
})

test_that("filter_na_range preserves existing NAs", {
  expect_equal(
    filter_na_range(c(1, NA, 10, 15), min = 5, max = 12),
    c(NA, NA, 10, NA)
  )
})

test_that("filter_na_range validates x is numeric", {
  expect_error(
    filter_na_range("not numeric"),
    class = "rlang_error"
  )

  expect_error(
    filter_na_range(factor(c(1, 2, 3))),
    class = "rlang_error"
  )
})

test_that("filter_na_range validates min and max", {
  # min not numeric
  expect_error(
    filter_na_range(c(1, 2, 3), min = "a"),
    class = "rlang_error"
  )

  # max not numeric
  expect_error(
    filter_na_range(c(1, 2, 3), max = "a"),
    class = "rlang_error"
  )

  # min is NA
  expect_error(
    filter_na_range(c(1, 2, 3), min = NA),
    class = "rlang_error"
  )

  # max is NA
  expect_error(
    filter_na_range(c(1, 2, 3), max = NA),
    class = "rlang_error"
  )

  # min is vector
  expect_error(
    filter_na_range(c(1, 2, 3), min = c(1, 2)),
    class = "rlang_error"
  )

  # max is vector
  expect_error(
    filter_na_range(c(1, 2, 3), max = c(10, 20)),
    class = "rlang_error"
  )
})

test_that("filter_na_range validates min <= max", {
  expect_error(
    filter_na_range(c(1, 2, 3), min = 10, max = 5),
    class = "rlang_error"
  )
})
