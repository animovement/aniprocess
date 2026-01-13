# Tests for filter_na_speed
# - Basic filtering with numeric threshold (2D)
# - Basic filtering with numeric threshold (3D)
# - Automatic threshold calculation
# - Preserves existing NAs
# - Preserves other columns
# - Filters confidence when present
# - Works without confidence column
# - Validates data is an aniframe
# - Validates required columns exist
# - Validates threshold input
# - Returns an aniframe

test_that("filter_na_speed filters with numeric threshold (2D)", {
  data <- aniframe::aniframe(
    time = 1:5,
    x = c(0, 1, 2, 10, 11),
    y = c(0, 1, 2, 10, 11)
  )

  result <- filter_na_speed(data, threshold = 5)

  # Points 3->4 have high speed, should be filtered
  expect_true(is.na(result$x[4]))
  expect_true(is.na(result$y[4]))
  # Other points should remain
  expect_false(is.na(result$x[1]))
  expect_false(is.na(result$x[2]))
})

test_that("filter_na_speed filters with numeric threshold (3D)", {
  data <- aniframe::aniframe(
    time = 1:5,
    x = c(0, 1, 2, 10, 11),
    y = c(0, 1, 2, 10, 11),
    z = c(0, 1, 2, 10, 11),
    variables_where = c("x", "y", "z")
  )

  result <- filter_na_speed(data, threshold = 5)

  # Points 3 and 4 have high speed due to the jump, should be filtered
  expect_true(is.na(result$x[3]))
  expect_true(is.na(result$y[3]))
  expect_true(is.na(result$z[3]))
  expect_true(is.na(result$x[4]))
  expect_true(is.na(result$y[4]))
  expect_true(is.na(result$z[4]))
  # Endpoints should remain (speed ~1.73)
  expect_false(is.na(result$x[1]))
  expect_false(is.na(result$x[5]))
})

test_that("filter_na_speed calculates auto threshold", {
  # Create data with one outlier
  data <- aniframe::aniframe(
    time = 1:100,
    x = c(1:50, 200, 201:249),
    y = 1:100
  )

  result <- filter_na_speed(data, threshold = "auto")

  # The jump at point 50+51 should be filtered
  expect_true(is.na(result$x[50]))
  # Most other points should remain
  expect_false(is.na(result$x[70]))
})

test_that("filter_na_speed preserves existing NAs", {
  data <- aniframe::aniframe(
    time = 1:5,
    x = c(0, NA, 2, 3, 4),
    y = c(0, 1, NA, 3, 4)
  )

  result <- filter_na_speed(data, threshold = 100)

  # Existing NAs should remain
  expect_true(is.na(result$x[2]))
  expect_true(is.na(result$y[3]))
})

test_that("filter_na_speed preserves other columns", {
  data <- aniframe::aniframe(
    time = 1:5,
    x = c(0, 1, 2, 3, 4),
    y = c(0, 1, 2, 3, 4),
    id = c("a", "b", "c", "d", "e"),
    value = c(10, 20, 30, 40, 50)
  )

  result <- filter_na_speed(data, threshold = 100)

  # Other columns should remain unchanged
  expect_equal(result$id, c("a", "b", "c", "d", "e"))
  expect_equal(result$value, c(10, 20, 30, 40, 50))
})

test_that("filter_na_speed filters confidence when present", {
  data <- aniframe::aniframe(
    time = 1:5,
    x = c(0, 1, 2, 10, 11),
    y = c(0, 1, 2, 10, 11),
    confidence = c(0.9, 0.9, 0.9, 0.9, 0.9)
  )

  result <- filter_na_speed(data, threshold = 5)

  # Confidence should be NA where speed exceeds threshold
  expect_true(is.na(result$confidence[4]))
  expect_false(is.na(result$confidence[1]))
})

test_that("filter_na_speed works without confidence column", {
  data <- aniframe::aniframe(
    time = 1:5,
    x = c(0, 1, 2, 3, 4),
    y = c(0, 1, 2, 3, 4)
  )

  expect_no_error(filter_na_speed(data, threshold = 100))
  expect_false("confidence" %in% names(filter_na_speed(data, threshold = 100)))
})

test_that("filter_na_speed validates data is an aniframe", {
  data <- data.frame(
    time = 1:5,
    x = c(0, 1, 2, 3, 4),
    y = c(0, 1, 2, 3, 4)
  )

  expect_error(
    filter_na_speed(data, threshold = 5),
    class = "rlang_error"
  )
})

test_that("filter_na_speed validates required columns exist", {
  data <- aniframe::aniframe(
    time = 1:5,
    x = c(0, 1, 2, 3, 4),
    y = c(0, 1, 2, 3, 4)
  )

  # Set metadata to expect z column that doesn't exist
  data <- aniframe::set_metadata(data, variables_where = c("x", "y", "z"))

  expect_error(
    filter_na_speed(data, threshold = 5),
    "Missing required column"
  )
})

test_that("filter_na_speed validates columns are numeric", {
  data <- aniframe::aniframe(
    time = 1:5,
    x = c(0, 1, 2, 3, 4),
    y = c(0, 1, 2, 3, 4)
  )

  # Force time to character (normally wouldn't happen)
  data$time <- as.character(data$time)

  expect_error(
    filter_na_speed(data, threshold = 5)
  )
})

test_that("filter_na_speed validates threshold is auto or numeric", {
  data <- aniframe::aniframe(
    time = 1:5,
    x = c(0, 1, 2, 3, 4),
    y = c(0, 1, 2, 3, 4)
  )

  expect_error(
    filter_na_speed(data, threshold = "high"),
    "must be either"
  )

  expect_error(
    filter_na_speed(data, threshold = c(1, 2)),
    "single numeric value"
  )
})

test_that("filter_na_speed returns an aniframe", {
  data <- aniframe::aniframe(
    time = 1:5,
    x = c(0, 1, 2, 3, 4),
    y = c(0, 1, 2, 3, 4)
  )

  result <- filter_na_speed(data, threshold = 100)

  expect_s3_class(result, "aniframe")
})

test_that("filter_na_speed handles constant position", {
  data <- aniframe::aniframe(
    time = 1:5,
    x = c(5, 5, 5, 5, 5),
    y = c(5, 5, 5, 5, 5)
  )

  result <- filter_na_speed(data, threshold = 1)

  # All speeds should be 0, nothing filtered
  expect_false(any(is.na(result$x)))
  expect_false(any(is.na(result$y)))
})

test_that("filter_na_speed handles uneven time spacing", {
  data <- aniframe::aniframe(
    time = c(0, 1, 2, 2.1, 3),
    x = c(0, 1, 2, 10, 11),
    y = c(0, 1, 2, 10, 11)
  )

  result <- filter_na_speed(data, threshold = 50)

  # The jump at time 2->2.1 has very high speed (distance 11.3 / time 0.1)
  expect_true(is.na(result$x[4]))
})

test_that("calculate_speed_2d computes correct values", {
  # Simple case: constant velocity of 1 in x direction
  x <- c(0, 1, 2, 3, 4)
  y <- c(0, 0, 0, 0, 0)
  time <- c(0, 1, 2, 3, 4)

  speed <- calculate_speed_2d(x, y, time)

  # Speed should be approximately 1 everywhere
  expect_true(all(abs(speed - 1) < 0.01))
})

test_that("calculate_speed_3d computes correct values", {
  # Simple case: constant velocity of 1 in x direction
  x <- c(0, 1, 2, 3, 4)
  y <- c(0, 0, 0, 0, 0)
  z <- c(0, 0, 0, 0, 0)
  time <- c(0, 1, 2, 3, 4)

  speed <- calculate_speed_3d(x, y, z, time)

  # Speed should be approximately 1 everywhere
  expect_true(all(abs(speed - 1) < 0.01))
})
