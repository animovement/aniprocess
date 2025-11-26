# Tests for filter_na_roi and helper functions
# - Rectangular ROI with individual boundaries (x_min, x_max, y_min, y_max)
# - Rectangular ROI with multiple boundaries
# - Circular ROI filters correctly
# - Points on boundaries are handled correctly
# - Preserves existing NAs
# - Validates ROI parameters are provided
# - Validates circular ROI has all required parameters
# - Error messages are clear

test_that("filter_na_roi filters rectangular ROI with x_min", {
  data <- data.frame(x = c(0, 5, 10, 15), y = c(0, 5, 10, 15))

  result <- filter_na_roi(data, x_min = 7)

  expect_equal(result$x, c(NA, NA, 10, 15))
  expect_equal(result$y, c(NA, NA, 10, 15))
})

test_that("filter_na_roi filters rectangular ROI with x_max", {
  data <- data.frame(x = c(0, 5, 10, 15), y = c(0, 5, 10, 15))

  result <- filter_na_roi(data, x_max = 7)

  expect_equal(result$x, c(0, 5, NA, NA))
  expect_equal(result$y, c(0, 5, NA, NA))
})

test_that("filter_na_roi filters rectangular ROI with y_min", {
  data <- data.frame(x = c(0, 5, 10, 15), y = c(0, 5, 10, 15))

  result <- filter_na_roi(data, y_min = 7)

  expect_equal(result$x, c(NA, NA, 10, 15))
  expect_equal(result$y, c(NA, NA, 10, 15))
})

test_that("filter_na_roi filters rectangular ROI with y_max", {
  data <- data.frame(x = c(0, 5, 10, 15), y = c(0, 5, 10, 15))

  result <- filter_na_roi(data, y_max = 7)

  expect_equal(result$x, c(0, 5, NA, NA))
  expect_equal(result$y, c(0, 5, NA, NA))
})

test_that("filter_na_roi filters rectangular ROI with multiple boundaries", {
  data <- data.frame(
    x = c(0, 5, 10, 15, 20),
    y = c(0, 5, 10, 15, 20)
  )

  result <- filter_na_roi(data, x_min = 5, x_max = 15, y_min = 5, y_max = 15)

  expect_equal(result$x, c(NA, 5, 10, 15, NA))
  expect_equal(result$y, c(NA, 5, 10, 15, NA))
})

test_that("filter_na_roi handles points on rectangular boundary correctly", {
  data <- data.frame(
    x = c(5, 10, 15),
    y = c(5, 10, 15)
  )

  result <- filter_na_roi(data, x_min = 5, x_max = 15, y_min = 5, y_max = 15)

  # Boundary points should be included
  expect_equal(result$x, c(5, 10, 15))
  expect_equal(result$y, c(5, 10, 15))
})

test_that("filter_na_roi filters circular ROI correctly", {
  data <- data.frame(
    x = c(0, 3, 6, 9),
    y = c(0, 0, 0, 0)
  )

  result <- filter_na_roi(data, x_center = 5, y_center = 0, radius = 3)

  # Points at x=0 and x=9 are outside (distance > 3)
  # Points at x=3 and x=6 are inside
  expect_equal(result$x, c(NA, 3, 6, NA))
  expect_equal(result$y, c(NA, 0, 0, NA))
})

test_that("filter_na_roi handles circular ROI with various distances", {
  data <- data.frame(
    x = c(5, 8, 10),
    y = c(5, 5, 5)
  )

  # Circle centered at (5, 5) with radius 4
  result <- filter_na_roi(data, x_center = 5, y_center = 5, radius = 4)

  # (5, 5): distance = 0, inside
  # (8, 5): distance = 3, inside
  # (10, 5): distance = 5, outside
  expect_equal(result$x, c(5, 8, NA))
  expect_equal(result$y, c(5, 5, NA))
})

test_that("filter_na_roi preserves existing NAs in rectangular ROI", {
  data <- data.frame(
    x = c(0, NA, 10, 15),
    y = c(0, 5, NA, 15)
  )

  result <- filter_na_roi(data, x_min = 5, x_max = 12)

  expect_equal(result$x, c(NA, NA, 10, NA))
  expect_true(is.na(result$y[2]))
  expect_true(is.na(result$y[3]))
})

test_that("filter_na_roi preserves existing NAs in circular ROI", {
  data <- data.frame(
    x = c(5, NA, 6),
    y = c(5, 5, NA)
  )

  result <- filter_na_roi(data, x_center = 5, y_center = 5, radius = 2)

  expect_true(is.na(result$x[2]))
  expect_true(is.na(result$y[3]))
})

test_that("filter_na_roi errors when no parameters provided", {
  data <- data.frame(x = c(1, 2, 3), y = c(1, 2, 3))

  expect_error(
    filter_na_roi(data),
    class = "rlang_error"
  )
})

test_that("filter_na_roi errors when circular ROI parameters incomplete", {
  data <- data.frame(x = c(1, 2, 3), y = c(1, 2, 3))

  # Only x_center provided
  expect_error(
    filter_na_roi(data, x_center = 5),
    class = "rlang_error"
  )

  # Only x_center and y_center provided
  expect_error(
    filter_na_roi(data, x_center = 5, y_center = 5),
    class = "rlang_error"
  )

  # Only radius provided
  expect_error(
    filter_na_roi(data, radius = 5),
    class = "rlang_error"
  )
})

test_that("filter_na_roi_square handles each boundary independently", {
  data <- data.frame(x = c(0, 10, 20), y = c(0, 10, 20))

  # Test x_min only
  result <- filter_na_roi_square(data, x_min = 5, NULL, NULL, NULL)
  expect_equal(result$x, c(NA, 10, 20))

  # Test x_max only
  result <- filter_na_roi_square(data, NULL, x_max = 15, NULL, NULL)
  expect_equal(result$x, c(0, 10, NA))

  # Test y_min only
  result <- filter_na_roi_square(data, NULL, NULL, y_min = 5, NULL)
  expect_equal(result$y, c(NA, 10, 20))

  # Test y_max only
  result <- filter_na_roi_square(data, NULL, NULL, NULL, y_max = 15)
  expect_equal(result$y, c(0, 10, NA))
})

test_that("filter_na_roi_circle calculates distance correctly", {
  data <- data.frame(
    x = c(2, 3, 5, 7, 8),
    y = c(4, 4, 4, 4, 4)
  )

  # Circle at (5, 4) with radius 2
  # (2, 4): distance = 3, outside
  # (3, 4): distance = 2, on boundary (included)
  # (5, 4): distance = 0, inside
  # (7, 4): distance = 2, on boundary (included)
  # (8, 4): distance = 3, outside
  result <- filter_na_roi_circle(data, x_center = 5, y_center = 4, radius = 2)

  expect_equal(result$x, c(NA, 3, 5, 7, NA))
  expect_equal(result$y, c(NA, 4, 4, 4, NA))
})

test_that("filter_na_roi_circle calculates distance correctly, exclusion", {
  data <- data.frame(
    x = c(2, 3, 5, 7, 8),
    y = c(4, 4, 4, 4, 4)
  )

  # Circle at (5, 4) with radius 2
  # (2, 4): distance = 3, outside
  # (3, 4): distance = 2, on boundary (included)
  # (5, 4): distance = 0, inside
  # (7, 4): distance = 2, on boundary (included)
  # (8, 4): distance = 3, outside
  result <- filter_na_roi_circle(data, x_center = 5, y_center = 4, radius = 2)

  expect_equal(result$x, c(NA, 3, 5, 7, NA))
  expect_equal(result$y, c(NA, 4, 4, 4, NA))
})

test_that("filter_na_roi_circle removes temporary column", {
  data <- data.frame(x = c(1, 2), y = c(1, 2))

  result <- filter_na_roi_circle(data, x_center = 5, y_center = 5, radius = 10)

  # Should not have is_outside column
  expect_false("is_outside" %in% names(result))
  expect_equal(names(result), c("x", "y"))
})

test_that("filter_na_roi works with grid data", {
  data <- expand.grid(
    x = seq(0, 10, by = 5),
    y = seq(0, 10, by = 5)
  ) |> as.data.frame()

  result <- filter_na_roi(data, x_min = 3, x_max = 8, y_min = 3, y_max = 8)

  # Only (5, 5) should remain
  non_na_rows <- result[!is.na(result$x) & !is.na(result$y), ]
  expect_equal(nrow(non_na_rows), 1)
  expect_equal(non_na_rows$x, 5)
  expect_equal(non_na_rows$y, 5)
})
