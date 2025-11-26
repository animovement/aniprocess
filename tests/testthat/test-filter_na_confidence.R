# Tests for filter_na_confidence
# - Basic filtering with default threshold (2D)
# - Basic filtering with default threshold (3D with z)
# - Custom threshold values
# - Boundary cases (0, 1, values on threshold)
# - Preserves existing NAs in x, y, z, confidence
# - Preserves other columns in data
# - Works without z column
# - Works with z column
# - Works when confidence is all NAs
# - Validates data is an aniframe
# - Validates required columns exist (x, y)
# - Validates threshold is single numeric value
# - Validates threshold is between 0 and 1

test_that("filter_na_confidence filters with default threshold (2D)", {
  data <- data.frame(
    time = 1:5,
    x = 1:5,
    y = 6:10,
    confidence = c(0.5, 0.7, 0.4, 0.8, 0.9)
  ) |>
    aniframe::as_aniframe()

  result <- filter_na_confidence(data)

  # threshold = 0.6, so rows 1 and 3 should be NA
  expect_equal(result$x, c(NA, 2, NA, 4, 5))
  expect_equal(result$y, c(NA, 7, NA, 9, 10))
  expect_equal(result$confidence, c(NA, 0.7, NA, 0.8, 0.9))
})

test_that("filter_na_confidence filters with default threshold (3D)", {
  data <- data.frame(
    time = 1:5,
    x = 1:5,
    y = 6:10,
    z = 11:15,
    confidence = c(0.5, 0.7, 0.4, 0.8, 0.9)
  ) |>
    aniframe::as_aniframe()

  result <- filter_na_confidence(data)

  # threshold = 0.6, so rows 1 and 3 should be NA
  expect_equal(result$x, c(NA, 2, NA, 4, 5))
  expect_equal(result$y, c(NA, 7, NA, 9, 10))
  expect_equal(result$z, c(NA, 12, NA, 14, 15))
  expect_equal(result$confidence, c(NA, 0.7, NA, 0.8, 0.9))
})

test_that("filter_na_confidence filters with custom threshold", {
  data <- data.frame(
    time = 1:5,
    x = 1:5,
    y = 6:10,
    z = 11:15,
    confidence = c(0.5, 0.7, 0.4, 0.8, 0.9)
  ) |>
    aniframe::as_aniframe()

  result <- filter_na_confidence(data, threshold = 0.75)

  # threshold = 0.75, so rows 1, 2, and 3 should be NA
  expect_equal(result$x, c(NA, NA, NA, 4, 5))
  expect_equal(result$y, c(NA, NA, NA, 9, 10))
  expect_equal(result$z, c(NA, NA, NA, 14, 15))
  expect_equal(result$confidence, c(NA, NA, NA, 0.8, 0.9))
})

test_that("filter_na_confidence handles boundary values", {
  data <- data.frame(
    time = 1:4,
    x = 1:4,
    y = 5:8,
    confidence = c(0.5, 0.6, 0.7, 0.8)
  ) |>
    aniframe::as_aniframe()

  result <- filter_na_confidence(data, threshold = 0.6)

  # 0.6 exactly should be kept (threshold is minimum to retain)
  expect_equal(result$x, c(NA, 2, 3, 4))
  expect_equal(result$y, c(NA, 6, 7, 8))
  expect_equal(result$confidence, c(NA, 0.6, 0.7, 0.8))
})

test_that("filter_na_confidence handles threshold of 0", {
  data <- data.frame(
    time = 1:3,
    x = 1:3,
    y = 4:6,
    confidence = c(-0.1, 0, 0.5)
  ) |>
    aniframe::as_aniframe()

  result <- filter_na_confidence(data, threshold = 0)

  # Only negative values should be filtered
  expect_equal(result$x, c(NA, 2, 3))
  expect_equal(result$confidence, c(NA, 0, 0.5))
})

test_that("filter_na_confidence handles threshold of 1", {
  data <- data.frame(
    time = 1:3,
    x = 1:3,
    y = 4:6,
    confidence = c(0.5, 0.99, 1)
  ) |>
    aniframe::as_aniframe()

  result <- filter_na_confidence(data, threshold = 1)

  # Only value >= 1 should be kept
  expect_equal(result$x, c(NA, NA, 3))
  expect_equal(result$confidence, c(NA, NA, 1))
})

test_that("filter_na_confidence preserves existing NAs in x and y", {
  data <- data.frame(
    time = 1:4,
    x = c(1, NA, 3, 4),
    y = c(5, 6, NA, 8),
    confidence = c(0.5, 0.7, 0.8, 0.4)
  ) |>
    aniframe::as_aniframe()

  result <- filter_na_confidence(data, threshold = 0.6)

  # Row 1: confidence < 0.6, becomes NA
  # Row 2: x already NA, confidence >= 0.6
  # Row 3: y already NA, confidence >= 0.6
  # Row 4: confidence < 0.6, becomes NA
  expect_true(is.na(result$x[1]))
  expect_true(is.na(result$x[2]))
  expect_equal(result$x[3], 3)
  expect_true(is.na(result$x[4]))

  expect_true(is.na(result$y[3]))
})

test_that("filter_na_confidence preserves existing NAs in z", {
  data <- data.frame(
    time = 1:4,
    x = 1:4,
    y = 5:8,
    z = c(9, NA, 11, 12),
    confidence = c(0.7, 0.8, 0.5, 0.9)
  ) |>
    aniframe::as_aniframe()

  result <- filter_na_confidence(data, threshold = 0.6)

  # Row 2: z already NA, confidence >= 0.6
  # Row 3: confidence < 0.6, becomes NA
  expect_true(is.na(result$z[2]))
  expect_true(is.na(result$z[3]))
  expect_equal(result$z[1], 9)
  expect_equal(result$z[4], 12)
})

test_that("filter_na_confidence preserves existing NAs in confidence", {
  data <- data.frame(
    time = 1:4,
    x = 1:4,
    y = 5:8,
    confidence = c(0.5, NA, 0.8, 0.9)
  ) |>
    aniframe::as_aniframe()

  result <- filter_na_confidence(data, threshold = 0.6)

  # Row with NA confidence should have NA x, y, confidence
  expect_true(is.na(result$x[2]))
  expect_true(is.na(result$y[2]))
  expect_true(is.na(result$confidence[2]))
})

test_that("filter_na_confidence handles all NAs in confidence", {
  data <- data.frame(
    time = 1:3,
    x = 1:3,
    y = 4:6
  ) |>
    aniframe::as_aniframe()

  # as_aniframe creates confidence column with all NAs
  result <- filter_na_confidence(data, threshold = 0.6)

  # All rows should become NA since confidence is all NA
  expect_true(all(is.na(result$x)))
  expect_true(all(is.na(result$y)))
  expect_true(all(is.na(result$confidence)))
})

test_that("filter_na_confidence preserves other columns", {
  data <- data.frame(
    time = 1:3,
    x = 1:3,
    y = 4:6,
    confidence = c(0.5, 0.7, 0.9),
    id = c("a", "b", "c"),
    value = c(10, 20, 30)
  ) |>
    aniframe::as_aniframe()

  result <- filter_na_confidence(data, threshold = 0.6)

  # Other columns should remain unchanged
  expect_equal(result$id, c("a", "b", "c"))
  expect_equal(result$value, c(10, 20, 30))
})

test_that("filter_na_confidence works without z column", {
  data <- data.frame(
    time = 1:3,
    x = 1:3,
    y = 4:6,
    confidence = c(0.5, 0.7, 0.9)
  ) |>
    aniframe::as_aniframe()

  result <- filter_na_confidence(data, threshold = 0.6)

  # Should work fine without z
  expect_equal(result$x, c(NA, 2, 3))
  expect_equal(result$y, c(NA, 5, 6))
  expect_false("z" %in% names(result))
})

test_that("filter_na_confidence works with z column", {
  data <- data.frame(
    time = 1:3,
    x = 1:3,
    y = 4:6,
    z = 7:9,
    confidence = c(0.5, 0.7, 0.9)
  ) |>
    aniframe::as_aniframe()

  result <- filter_na_confidence(data, threshold = 0.6)

  # Should filter z along with x and y
  expect_equal(result$x, c(NA, 2, 3))
  expect_equal(result$y, c(NA, 5, 6))
  expect_equal(result$z, c(NA, 8, 9))
})

test_that("filter_na_confidence validates data is an aniframe", {
  # Regular data frame should error
  data <- data.frame(
    time = 1:3,
    x = 1:3,
    y = 4:6,
    confidence = c(0.5, 0.7, 0.9)
  )

  expect_error(
    filter_na_confidence(data),
    class = "rlang_error"
  )

  # Vector should error
  expect_error(
    filter_na_confidence(c(1, 2, 3)),
    class = "rlang_error"
  )
})

test_that("filter_na_confidence validates required columns exist", {
  # Missing x column
  data <- data.frame(
    time = 1:3,
    y = 1:3,
    confidence = c(0.5, 0.7, 0.9)
  ) |>
    aniframe::as_aniframe()
  expect_error(
    filter_na_confidence(data),
    class = "rlang_error"
  )

  # Missing y column
  data <- data.frame(
    time = 1:3,
    x = 1:3,
    confidence = c(0.5, 0.7, 0.9)
  ) |>
    aniframe::as_aniframe()
  expect_error(
    filter_na_confidence(data),
    class = "rlang_error"
  )
})

test_that("filter_na_confidence does not require z column", {
  # z is optional, should not error if missing
  data <- data.frame(
    time = 1:3,
    x = 1:3,
    y = 4:6,
    confidence = c(0.5, 0.7, 0.9)
  ) |>
    aniframe::as_aniframe()

  expect_no_error(filter_na_confidence(data))
})

test_that("filter_na_confidence validates threshold is single numeric", {
  data <- data.frame(
    time = 1:3,
    x = 1:3,
    y = 4:6,
    confidence = c(0.5, 0.7, 0.9)
  ) |>
    aniframe::as_aniframe()

  # Non-numeric
  expect_error(
    filter_na_confidence(data, threshold = "0.5"),
    class = "rlang_error"
  )

  # NA threshold
  expect_error(
    filter_na_confidence(data, threshold = NA),
    class = "rlang_error"
  )

  # Vector threshold
  expect_error(
    filter_na_confidence(data, threshold = c(0.5, 0.6)),
    class = "rlang_error"
  )
})

test_that("filter_na_confidence validates threshold is between 0 and 1", {
  data <- data.frame(
    time = 1:3,
    x = 1:3,
    y = 4:6,
    confidence = c(0.5, 0.7, 0.9)
  ) |>
    aniframe::as_aniframe()

  # Below 0
  expect_error(
    filter_na_confidence(data, threshold = -0.1),
    class = "rlang_error"
  )

  # Above 1
  expect_error(
    filter_na_confidence(data, threshold = 1.1),
    class = "rlang_error"
  )
})

test_that("filter_na_confidence returns an aniframe", {
  data <- data.frame(
    time = 1:3,
    x = 1:3,
    y = 4:6,
    z = 7:9,
    confidence = c(0.5, 0.7, 0.9)
  ) |>
    aniframe::as_aniframe()

  result <- filter_na_confidence(data, threshold = 0.6)

  expect_s3_class(result, "aniframe")
  expect_equal(result$x, c(NA, 2, 3))
  expect_equal(result$z, c(NA, 8, 9))
})
