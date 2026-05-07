# Tests for filter_na_speed
# - Flags single-frame outliers (2D and 3D)
# - Leaves legitimate step changes alone
# - Does not contaminate neighbors of NA inputs
# - Automatic threshold calculation
# - Preserves existing NAs
# - Preserves other columns
# - Filters confidence when present
# - Works without confidence column
# - Validates inputs
# - Returns an aniframe

test_that("filter_na_speed flags a single-frame outlier (2D)", {
  # Smooth motion with one position outlier at index 5
  data <- aniframe::aniframe(
    time = 1:9,
    x = c(1, 2, 3, 4, 100, 6, 7, 8, 9),
    y = c(1, 2, 3, 4, 100, 6, 7, 8, 9)
  )

  result <- filter_na_speed(data, threshold = 20)

  # The outlier itself is flagged
  expect_true(is.na(result$x[5]))
  expect_true(is.na(result$y[5]))
  # Innocent neighbors are not
  expect_false(is.na(result$x[4]))
  expect_false(is.na(result$x[6]))
  expect_false(is.na(result$y[4]))
  expect_false(is.na(result$y[6]))
})

test_that("filter_na_speed flags a single-frame outlier (3D)", {
  data <- aniframe::aniframe(
    time = 1:9,
    x = c(1, 2, 3, 4, 100, 6, 7, 8, 9),
    y = c(1, 2, 3, 4, 100, 6, 7, 8, 9),
    z = c(1, 2, 3, 4, 100, 6, 7, 8, 9),
    variables_where = c("x", "y", "z")
  )

  result <- filter_na_speed(data, threshold = 20)

  expect_true(is.na(result$x[5]))
  expect_true(is.na(result$y[5]))
  expect_true(is.na(result$z[5]))
  expect_false(is.na(result$x[4]))
  expect_false(is.na(result$x[6]))
})

test_that("filter_na_speed leaves legitimate step changes alone", {
  # Sustained move to a new region (not an outlier)
  data <- aniframe::aniframe(
    time = 1:8,
    x = c(1, 2, 3, 100, 101, 102, 103, 104),
    y = c(1, 2, 3, 100, 101, 102, 103, 104)
  )

  result <- filter_na_speed(data, threshold = 20)

  # Nothing should be flagged - this is a state change, not an outlier
  expect_false(any(is.na(result$x)))
  expect_false(any(is.na(result$y)))
})

test_that("filter_na_speed calculates auto threshold", {
  # Data with one single-frame outlier at index 51
  data <- aniframe::aniframe(
    time = 1:100,
    x = c(1:50, 500, 51:99),
    y = 1:100
  )

  result <- filter_na_speed(data, threshold = "auto")

  # The outlier at 51 should be flagged
  expect_true(is.na(result$x[51]))
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

test_that("filter_na_speed does not contaminate neighbors of NA inputs", {
  # Single NA in x at row 3 of an otherwise clean series
  data <- aniframe::aniframe(
    time = 1:7,
    x = c(1, 2, NA, 4, 5, 6, 7),
    y = c(1, 2, 3, 4, 5, 6, 7)
  )

  result <- filter_na_speed(data, threshold = 100)

  # Neighbors of the NA row remain clean
  expect_false(is.na(result$x[2]))
  expect_false(is.na(result$x[4]))
  expect_false(is.na(result$y[2]))
  expect_false(is.na(result$y[4]))
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

  expect_equal(result$id, c("a", "b", "c", "d", "e"))
  expect_equal(result$value, c(10, 20, 30, 40, 50))
})

test_that("filter_na_speed filters confidence when present", {
  data <- aniframe::aniframe(
    time = 1:7,
    x = c(1, 2, 3, 100, 5, 6, 7),
    y = c(1, 2, 3, 100, 5, 6, 7),
    confidence = rep(0.9, 7)
  )

  result <- filter_na_speed(data, threshold = 20)

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
  # Single-frame outlier on an uneven time grid
  data <- aniframe::aniframe(
    time = c(0, 1, 2, 2.1, 2.2, 3, 4),
    x = c(0, 1, 2, 100, 4, 5, 6),
    y = c(0, 1, 2, 100, 4, 5, 6)
  )

  result <- filter_na_speed(data, threshold = 50)

  # The outlier at index 4 should be flagged
  expect_true(is.na(result$x[4]))
})

test_that("calculate_speed_2d computes correct values", {
  # Constant velocity of 1 in x direction
  x <- c(0, 1, 2, 3, 4)
  y <- c(0, 0, 0, 0, 0)
  time <- c(0, 1, 2, 3, 4)

  speed <- calculate_speed_2d(x, y, time)

  expect_true(all(abs(speed - 1) < 1e-9))
})

test_that("calculate_speed_3d computes correct values", {
  x <- c(0, 1, 2, 3, 4)
  y <- c(0, 0, 0, 0, 0)
  z <- c(0, 0, 0, 0, 0)
  time <- c(0, 1, 2, 3, 4)

  speed <- calculate_speed_3d(x, y, z, time)

  expect_true(all(abs(speed - 1) < 1e-9))
})

test_that("calculate_speed_2d uses one-sided fallback at endpoints", {
  # Step speeds: 1, 1, 1, 1
  x <- c(0, 1, 2, 3, 4)
  y <- c(0, 0, 0, 0, 0)
  time <- c(0, 1, 2, 3, 4)

  speed <- calculate_speed_2d(x, y, time)

  # Endpoints should fall back to the one-sided step (no NA)
  expect_false(is.na(speed[1]))
  expect_false(is.na(speed[length(speed)]))
})
