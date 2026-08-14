# Tests for filter_na_confidence
# - Basic filtering with default threshold (2D)
# - Basic filtering with default threshold (3D with z)
# - Custom threshold values
# - Boundary cases (0, 1, values on threshold)
# - Preserves existing NAs in spatial and confidence columns
# - Preserves other columns in data
# - Works with different coordinate systems
# - Works when confidence is all NAs
# - Validates data is an aniframe
# - Validates required columns exist (spatial variables from metadata)
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

  result <- filter_na_across(data, "confidence")

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
    aniframe::as_aniframe(variables_where = c("x", "y", "z"))

  result <- filter_na_across(data, "confidence")

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
    aniframe::as_aniframe(variables_where = c("x", "y", "z"))

  result <- filter_na_across(data, "confidence", threshold = 0.75)

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

  result <- filter_na_across(data, "confidence", threshold = 0.6)

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

  result <- filter_na_across(data, "confidence", threshold = 0)

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

  result <- filter_na_across(data, "confidence", threshold = 1)

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

  result <- filter_na_across(data, "confidence", threshold = 0.6)

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
    aniframe::as_aniframe(variables_where = c("x", "y", "z"))

  result <- filter_na_across(data, "confidence", threshold = 0.6)

  # Row 2: z already NA, confidence >= 0.6
  # Row 3: confidence < 0.6, becomes NA
  expect_true(is.na(result$z[2]))
  expect_true(is.na(result$z[3]))
  expect_equal(result$z[1], 9)
  expect_equal(result$z[4], 12)
})

test_that("filter_na_confidence leaves rows with a missing confidence alone", {
  data <- data.frame(
    time = 1:4,
    x = 1:4,
    y = 5:8,
    confidence = c(0.5, NA, 0.8, 0.9)
  ) |>
    aniframe::as_aniframe()

  result <- suppressWarnings(filter_na_across(
    data,
    "confidence",
    threshold = 0.6
  ))

  # A missing confidence means "not scored", not "scored badly"
  expect_false(is.na(result$x[2]))
  expect_false(is.na(result$y[2]))
  expect_equal(result$x[2], 2)
  # It was NA on the way in, so it is still NA on the way out
  expect_true(is.na(result$confidence[2]))
  # Row 1 is genuinely below threshold and is still masked
  expect_true(is.na(result$x[1]))
})

test_that("filter_na_confidence warns about missing confidence values", {
  # The warning is rate-limited so a grouped mutate() does not emit one per
  # group; reset the counter so this test sees it regardless of run order.
  rlang::reset_warning_verbosity("aniprocess_confidence_na")

  data <- data.frame(
    time = 1:4,
    x = 1:4,
    y = 5:8,
    confidence = c(0.5, NA, NA, 0.9)
  ) |>
    aniframe::as_aniframe()

  expect_warning(
    filter_na_across(data, "confidence", threshold = 0.6),
    "2 confidence values are missing"
  )
})

test_that("filter_na_confidence handles all NAs in confidence", {
  data <- data.frame(
    time = 1:3,
    x = 1:3,
    y = 4:6,
    confidence = c(NA_real_, NA_real_, NA_real_)
  ) |>
    aniframe::as_aniframe()

  result <- suppressWarnings(filter_na_across(
    data,
    "confidence",
    threshold = 0.6
  ))

  # Nothing was scored, so nothing is filtered
  expect_equal(result$x, 1:3)
  expect_equal(result$y, 4:6)
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

  result <- filter_na_across(data, "confidence", threshold = 0.6)

  # Other columns should remain unchanged
  expect_equal(result$id, c("a", "b", "c"))
  expect_equal(result$value, c(10, 20, 30))
})

test_that("filter_na_confidence works with 2D data", {
  data <- data.frame(
    time = 1:3,
    x = 1:3,
    y = 4:6,
    confidence = c(0.5, 0.7, 0.9)
  ) |>
    aniframe::as_aniframe()

  result <- filter_na_across(data, "confidence", threshold = 0.6)

  expect_equal(result$x, c(NA, 2, 3))
  expect_equal(result$y, c(NA, 5, 6))
  expect_false("z" %in% names(result))
})

test_that("filter_na_confidence works with 3D data", {
  data <- data.frame(
    time = 1:3,
    x = 1:3,
    y = 4:6,
    z = 7:9,
    confidence = c(0.5, 0.7, 0.9)
  ) |>
    aniframe::as_aniframe(variables_where = c("x", "y", "z"))

  result <- filter_na_across(data, "confidence", threshold = 0.6)

  # Should filter z along with x and y
  expect_equal(result$x, c(NA, 2, 3))
  expect_equal(result$y, c(NA, 5, 6))
  expect_equal(result$z, c(NA, 8, 9))
})

test_that("filter_na_confidence works with polar coordinates", {
  data <- data.frame(
    time = 1:3,
    rho = c(1, 2, 3),
    phi = c(0.5, 1.0, 1.5),
    confidence = c(0.5, 0.7, 0.9)
  ) |>
    aniframe::as_aniframe(variables_where = c("rho", "phi"))

  result <- filter_na_across(data, "confidence", threshold = 0.6)

  expect_equal(result$rho, c(NA, 2, 3))
  expect_equal(result$phi, c(NA, 1.0, 1.5))
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
    filter_na_across(data, "confidence"),
    class = "rlang_error"
  )

  # Vector should error
  expect_error(
    filter_na_confidence(c(1, 2, 3)),
    class = "rlang_error"
  )
})

test_that("filter_na_confidence validates required columns exist", {
  # Create aniframe then modify metadata to have missing spatial variable
  data <- data.frame(
    time = 1:3,
    x = 1:3,
    y = 4:6,
    confidence = c(0.5, 0.7, 0.9)
  ) |>
    aniframe::as_aniframe()

  # Set metadata to expect z column that doesn't exist
  data <- aniframe::set_metadata(data, variables_where = c("x", "y", "z"))

  expect_error(
    filter_na_across(data, "confidence"),
    "Missing spatial column"
  )
})

test_that("filter_na_confidence validates confidence column exists", {
  data <- data.frame(
    time = 1:3,
    x = 1:3,
    y = 4:6
  ) |>
    aniframe::as_aniframe()

  expect_error(
    filter_na_across(data, "confidence"),
    "Missing required column.*confidence"
  )
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
    filter_na_across(data, "confidence", threshold = "0.5"),
    class = "rlang_error"
  )

  # NA threshold
  expect_error(
    filter_na_across(data, "confidence", threshold = NA),
    class = "rlang_error"
  )

  # Vector threshold
  expect_error(
    filter_na_across(data, "confidence", threshold = c(0.5, 0.6)),
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
    filter_na_across(data, "confidence", threshold = -0.1),
    class = "rlang_error"
  )

  # Above 1
  expect_error(
    filter_na_across(data, "confidence", threshold = 1.1),
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
    aniframe::as_aniframe(variables_where = c("x", "y", "z"))

  result <- filter_na_across(data, "confidence", threshold = 0.6)

  expect_s3_class(result, "aniframe")
  expect_equal(result$x, c(NA, 2, 3))
  expect_equal(result$z, c(NA, 8, 9))
})

test_that("filter_na_confidence validates confidence column is numeric", {
  data <- data.frame(
    time = 1:3,
    x = 1:3,
    y = 4:6,
    confidence = c("low", "medium", "high")
  ) |>
    aniframe::as_aniframe()

  expect_error(
    filter_na_across(data, "confidence"),
    "confidence.*must be numeric"
  )
})

# --- coordinate-frame form (#30 step 2) -------------------------------------

test_that("filter_na_confidence requires confidence for a coordinate frame", {
  expect_error(
    filter_na_confidence(data.frame(x = 1:5, y = 1:5)),
    "`confidence` is required"
  )
})

test_that("filter_na_confidence coordinate-frame form masks the coordinates", {
  coords <- data.frame(x = c(1, 2, 3, 4), y = c(5, 6, 7, 8))
  conf <- c(0.9, 0.2, NA, 0.7)

  res <- suppressWarnings(
    filter_na_confidence(coords, threshold = 0.6, confidence = conf)
  )

  # Only the row below threshold is blanked; the missing one is left alone
  expect_equal(which(is.na(res$x)), 2L)
  expect_equal(which(is.na(res$y)), 2L)
  # `confidence` is not a coordinate, so nothing is added to the output
  expect_equal(names(res), c("x", "y"))
})

test_that("filter_na_confidence coordinate-frame form matches the aniframe form", {
  conf <- c(0.9, 0.2, NA, 0.7)
  d <- aniframe::aniframe(
    time = 1:4,
    x = c(1, 2, 3, 4),
    y = c(5, 6, 7, 8),
    confidence = conf
  )
  expect_equal(
    filter_na_confidence(
      data.frame(x = c(1, 2, 3, 4), y = c(5, 6, 7, 8)),
      threshold = 0.6,
      confidence = conf
    ),
    as.data.frame(filter_na_across(d, "confidence", threshold = 0.6))[, c(
      "x",
      "y"
    )],
    ignore_attr = TRUE
  )
})

test_that("filter_na_confidence rejects a mismatched confidence length", {
  expect_error(
    filter_na_confidence(
      data.frame(x = 1:5, y = 1:5),
      confidence = c(0.9, 0.8)
    ),
    "one value per row"
  )
})

test_that("filter_na_confidence rejects a non-numeric confidence", {
  expect_error(
    filter_na_confidence(
      data.frame(x = 1:5, y = 1:5),
      confidence = letters[1:5]
    ),
    "must be numeric"
  )
})
