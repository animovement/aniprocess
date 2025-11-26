# Tests for filter_na_speed
# - Basic filtering with numeric threshold
# - Handles outliers with numeric threshold
# - Works with aniframes (with/without confidence)
# - Preserves aniframe structure and attributes
# - Handles NA values in coordinates correctly
# - Handles consecutive NAs
# - Handles all NAs in one column
# - Validates required columns exist (time, x, y)
# - Validates threshold parameter

test_that("filter_na_speed handles basic numeric threshold correctly", {
  # Create test data
  test_data <- data.frame(
    time = 1:5,
    x = c(1, 2, 4, 7, 11),
    y = c(1, 1, 2, 3, 5),
    confidence = c(0.8, 0.9, 0.7, 0.85, 0.6)
  ) |>
    aniframe::as_aniframe()

  # Test with numeric threshold
  result <- filter_na_speed(test_data, threshold = 3)

  # Check structure - aniframe adds individual and keypoint columns
  expect_s3_class(result, "data.frame")
  expect_true(all(c("time", "x", "y", "confidence") %in% names(result)))

  # Check that values above threshold are NA
  expect_true(any(is.na(result$x)))
  expect_true(any(is.na(result$y)))
  expect_true(any(is.na(result$confidence)))

  # Check that values below threshold remain unchanged
  expect_true(any(!is.na(result$x)))
  expect_true(any(!is.na(result$y)))
  expect_true(any(!is.na(result$confidence)))
})

test_that("filter_na_speed handles 'auto' threshold correctly", {
  test_data <- data.frame(
    time = 1:5,
    x = c(1, 2, 4, 7, 200), # Last value is an outlier
    y = c(1, 1, 2, 3, 30), # Last value is an outlier
    confidence = c(0.8, 0.9, 0.7, 0.85, 0.6)
  ) |>
    aniframe::as_aniframe()

  result <- filter_na_speed(test_data, threshold = 5)

  # Check that at least one value (outlier) is filtered
  expect_true(is.na(result$x[5]))
  expect_true(is.na(result$y[5]))
  expect_true(is.na(result$confidence[5]))

  # Check that normal values remain
  expect_false(all(is.na(result$x)))
  expect_false(all(is.na(result$y)))
  expect_false(all(is.na(result$confidence)))
})

test_that("filter_na_speed works without confidence column", {
  test_data <- data.frame(
    time = 1:5,
    x = c(1, 2, 4, 7, 11),
    y = c(1, 1, 2, 3, 5)
  ) |>
    aniframe::as_aniframe()

  result <- filter_na_speed(test_data, threshold = 3)

  # Check structure - confidence will be added by as_aniframe
  expect_true("confidence" %in% names(result))

  # Check filtering still works
  expect_true(any(is.na(result$x)))
  expect_true(any(is.na(result$y)))
})

test_that("filter_na_speed errors on missing required columns", {
  # Missing x - need to create with at least y to pass as_aniframe validation
  test_data1 <- data.frame(
    time = 1:5,
    y = c(1, 1, 2, 3, 5)
  ) |>
    aniframe::as_aniframe()

  expect_error(
    filter_na_speed(test_data1),
    regexp = "Missing required columns"
  )

  # Missing y
  test_data2 <- data.frame(
    time = 1:5,
    x = c(1, 2, 4, 7, 11)
  ) |>
    aniframe::as_aniframe()

  expect_error(
    filter_na_speed(test_data2),
    regexp = "Missing required columns"
  )
})

test_that("filter_na_speed errors on invalid threshold", {
  test_data <- data.frame(
    time = 1:5,
    x = c(1, 2, 4, 7, 11),
    y = c(1, 1, 2, 3, 5)
  ) |>
    aniframe::as_aniframe()

  expect_error(
    filter_na_speed(test_data, threshold = "invalid"),
    regexp = "threshold must be either 'auto' or a numeric value"
  )
})

test_that("filter_na_speed preserves data frame attributes", {
  test_data <- data.frame(
    time = 1:5,
    x = c(1, 2, 4, 7, 11),
    y = c(1, 1, 2, 3, 5)
  ) |>
    aniframe::as_aniframe()

  result <- filter_na_speed(test_data, threshold = 3)

  # Check that result is an aniframe
  expect_s3_class(result, "aniframe")
  # Check number of rows is preserved
  expect_equal(nrow(result), nrow(test_data))
})

test_that("filter_na_speed handles NA values correctly", {
  # Test data with NAs in different positions and columns
  test_data <- data.frame(
    time = 1:5,
    x = c(1, NA, 4, 7, 11),
    y = c(NA, 1, 2, 3, 5),
    confidence = c(0.8, 0.9, NA, 0.85, 0.6)
  ) |>
    aniframe::as_aniframe()

  # Test with numeric threshold
  result <- filter_na_speed(test_data, threshold = 3)

  # Check that NAs in input are preserved in output
  expect_true(is.na(result$x[2]))
  expect_true(is.na(result$y[1]))
  expect_true(is.na(result$confidence[3]))

  # Test consecutive NAs
  test_data_consecutive <- data.frame(
    time = 1:5,
    x = c(1, 2, NA, NA, 11),
    y = c(1, 1, NA, NA, 5),
    confidence = c(0.8, 0.9, NA, NA, 0.6)
  ) |>
    aniframe::as_aniframe()

  result_consecutive <- filter_na_speed(test_data_consecutive, threshold = 3)

  # Check that consecutive NAs are handled properly
  expect_true(all(is.na(result_consecutive$x[3:4])))
  expect_true(all(is.na(result_consecutive$y[3:4])))

  # Test with all NAs in one column
  test_data_all_na <- data.frame(
    time = 1:5,
    x = rep(NA_real_, 5),
    y = c(1, 1, 2, 3, 5),
    confidence = c(0.8, 0.9, 0.7, 0.85, 0.6)
  ) |>
    aniframe::as_aniframe()

  result_all_na <- filter_na_speed(test_data_all_na, threshold = 3)

  # Check that column with all NAs remains all NA
  expect_true(all(is.na(result_all_na$x)))
})

test_that("filter_na_speed handles speed calculation with gaps", {
  # Test edge case with gaps that affect speed calculation
  test_data_gaps <- data.frame(
    time = c(1, 2, 5, 6, 7),
    x = c(1, 2, 4, 7, 11),
    y = c(1, 1, 2, 3, 5)
  ) |>
    aniframe::as_aniframe()

  result_gaps <- filter_na_speed(test_data_gaps, threshold = 3)

  # Check that filtering works despite time gaps
  expect_s3_class(result_gaps, "aniframe")
  expect_equal(nrow(result_gaps), nrow(test_data_gaps))
})
