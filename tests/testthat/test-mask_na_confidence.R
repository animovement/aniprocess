# Tests for mask_na_confidence
# - Basic filtering with default threshold (2D)
# - Basic filtering with default threshold (3D with z)
# - Custom threshold values
# - Boundary cases (0, 1, values on threshold)
# - Preserves existing NAs in spatial and confidence columns
# - Preserves other columns in data
# - Works with different coordinate systems
# - Works when confidence is all NAs
# - `missing` keeps or masks unscored rows, through every entry point
# - Warns once, for rows that masking could change, unless `missing` is given
# - Validates data is an aniframe
# - Validates required columns exist (spatial variables from metadata)
# - Validates threshold is single numeric value
# - Validates threshold is between 0 and 1

test_that("mask_na_confidence filters with default threshold (2D)", {
  data <- data.frame(
    time = 1:5,
    x = 1:5,
    y = 6:10,
    confidence = c(0.5, 0.7, 0.4, 0.8, 0.9)
  ) |>
    anicore::as_anipoint()

  result <- mask_na_across(data, "confidence")

  # threshold = 0.6, so rows 1 and 3 should be NA
  expect_equal(result$x, c(NA, 2, NA, 4, 5))
  expect_equal(result$y, c(NA, 7, NA, 9, 10))
  expect_equal(result$confidence, c(NA, 0.7, NA, 0.8, 0.9))
})

test_that("mask_na_confidence filters with default threshold (3D)", {
  data <- data.frame(
    time = 1:5,
    x = 1:5,
    y = 6:10,
    z = 11:15,
    confidence = c(0.5, 0.7, 0.4, 0.8, 0.9)
  ) |>
    anicore::as_anipoint(variables_where = c("x", "y", "z"))

  result <- mask_na_across(data, "confidence")

  # threshold = 0.6, so rows 1 and 3 should be NA
  expect_equal(result$x, c(NA, 2, NA, 4, 5))
  expect_equal(result$y, c(NA, 7, NA, 9, 10))
  expect_equal(result$z, c(NA, 12, NA, 14, 15))
  expect_equal(result$confidence, c(NA, 0.7, NA, 0.8, 0.9))
})

test_that("mask_na_confidence filters with custom threshold", {
  data <- data.frame(
    time = 1:5,
    x = 1:5,
    y = 6:10,
    z = 11:15,
    confidence = c(0.5, 0.7, 0.4, 0.8, 0.9)
  ) |>
    anicore::as_anipoint(variables_where = c("x", "y", "z"))

  result <- mask_na_across(data, "confidence", threshold = 0.75)

  # threshold = 0.75, so rows 1, 2, and 3 should be NA
  expect_equal(result$x, c(NA, NA, NA, 4, 5))
  expect_equal(result$y, c(NA, NA, NA, 9, 10))
  expect_equal(result$z, c(NA, NA, NA, 14, 15))
  expect_equal(result$confidence, c(NA, NA, NA, 0.8, 0.9))
})

test_that("mask_na_confidence handles boundary values", {
  data <- data.frame(
    time = 1:4,
    x = 1:4,
    y = 5:8,
    confidence = c(0.5, 0.6, 0.7, 0.8)
  ) |>
    anicore::as_anipoint()

  result <- mask_na_across(data, "confidence", threshold = 0.6)

  # 0.6 exactly should be kept (threshold is minimum to retain)
  expect_equal(result$x, c(NA, 2, 3, 4))
  expect_equal(result$y, c(NA, 6, 7, 8))
  expect_equal(result$confidence, c(NA, 0.6, 0.7, 0.8))
})

test_that("mask_na_confidence handles threshold of 0", {
  data <- data.frame(
    time = 1:3,
    x = 1:3,
    y = 4:6,
    confidence = c(-0.1, 0, 0.5)
  ) |>
    anicore::as_anipoint()

  result <- mask_na_across(data, "confidence", threshold = 0)

  # Only negative values should be filtered
  expect_equal(result$x, c(NA, 2, 3))
  expect_equal(result$confidence, c(NA, 0, 0.5))
})

test_that("mask_na_confidence handles threshold of 1", {
  data <- data.frame(
    time = 1:3,
    x = 1:3,
    y = 4:6,
    confidence = c(0.5, 0.99, 1)
  ) |>
    anicore::as_anipoint()

  result <- mask_na_across(data, "confidence", threshold = 1)

  # Only value >= 1 should be kept
  expect_equal(result$x, c(NA, NA, 3))
  expect_equal(result$confidence, c(NA, NA, 1))
})

test_that("mask_na_confidence preserves existing NAs in x and y", {
  data <- data.frame(
    time = 1:4,
    x = c(1, NA, 3, 4),
    y = c(5, 6, NA, 8),
    confidence = c(0.5, 0.7, 0.8, 0.4)
  ) |>
    anicore::as_anipoint()

  result <- mask_na_across(data, "confidence", threshold = 0.6)

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

test_that("mask_na_confidence preserves existing NAs in z", {
  data <- data.frame(
    time = 1:4,
    x = 1:4,
    y = 5:8,
    z = c(9, NA, 11, 12),
    confidence = c(0.7, 0.8, 0.5, 0.9)
  ) |>
    anicore::as_anipoint(variables_where = c("x", "y", "z"))

  result <- mask_na_across(data, "confidence", threshold = 0.6)

  # Row 2: z already NA, confidence >= 0.6
  # Row 3: confidence < 0.6, becomes NA
  expect_true(is.na(result$z[2]))
  expect_true(is.na(result$z[3]))
  expect_equal(result$z[1], 9)
  expect_equal(result$z[4], 12)
})

test_that("mask_na_confidence leaves rows with a missing confidence alone", {
  data <- data.frame(
    time = 1:4,
    x = 1:4,
    y = 5:8,
    confidence = c(0.5, NA, 0.8, 0.9)
  ) |>
    anicore::as_anipoint()

  result <- suppressWarnings(mask_na_across(
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

test_that("mask_na_confidence warns about missing confidence values", {
  data <- data.frame(
    time = 1:4,
    x = 1:4,
    y = 5:8,
    confidence = c(0.5, NA, NA, 0.9)
  ) |>
    anicore::as_anipoint()

  expect_warning(
    mask_na_across(data, "confidence", threshold = 0.6),
    "2 rows have no confidence score and were left unmasked",
    class = "aniprocess_warning_unscored_confidence"
  )
})

test_that("mask_na_confidence handles all NAs in confidence", {
  data <- data.frame(
    time = 1:3,
    x = 1:3,
    y = 4:6,
    confidence = c(NA_real_, NA_real_, NA_real_)
  ) |>
    anicore::as_anipoint()

  result <- suppressWarnings(mask_na_across(
    data,
    "confidence",
    threshold = 0.6
  ))

  # Nothing was scored, so nothing is filtered
  expect_equal(result$x, 1:3)
  expect_equal(result$y, 4:6)
  expect_true(all(is.na(result$confidence)))
})

test_that("mask_na_confidence preserves other columns", {
  data <- data.frame(
    time = 1:3,
    x = 1:3,
    y = 4:6,
    confidence = c(0.5, 0.7, 0.9),
    id = c("a", "b", "c"),
    value = c(10, 20, 30)
  ) |>
    anicore::as_anipoint()

  result <- mask_na_across(data, "confidence", threshold = 0.6)

  # Other columns should remain unchanged
  expect_equal(result$id, c("a", "b", "c"))
  expect_equal(result$value, c(10, 20, 30))
})

test_that("mask_na_confidence works with 2D data", {
  data <- data.frame(
    time = 1:3,
    x = 1:3,
    y = 4:6,
    confidence = c(0.5, 0.7, 0.9)
  ) |>
    anicore::as_anipoint()

  result <- mask_na_across(data, "confidence", threshold = 0.6)

  expect_equal(result$x, c(NA, 2, 3))
  expect_equal(result$y, c(NA, 5, 6))
  expect_false("z" %in% names(result))
})

test_that("mask_na_confidence works with 3D data", {
  data <- data.frame(
    time = 1:3,
    x = 1:3,
    y = 4:6,
    z = 7:9,
    confidence = c(0.5, 0.7, 0.9)
  ) |>
    anicore::as_anipoint(variables_where = c("x", "y", "z"))

  result <- mask_na_across(data, "confidence", threshold = 0.6)

  # Should filter z along with x and y
  expect_equal(result$x, c(NA, 2, 3))
  expect_equal(result$y, c(NA, 5, 6))
  expect_equal(result$z, c(NA, 8, 9))
})

test_that("mask_na_confidence works with polar coordinates", {
  data <- data.frame(
    time = 1:3,
    rho = c(1, 2, 3),
    phi = c(0.5, 1.0, 1.5),
    confidence = c(0.5, 0.7, 0.9)
  ) |>
    anicore::as_anipoint(variables_where = c("rho", "phi"))

  result <- mask_na_across(data, "confidence", threshold = 0.6)

  expect_equal(result$rho, c(NA, 2, 3))
  expect_equal(result$phi, c(NA, 1.0, 1.5))
})

test_that("mask_na_confidence validates data is an aniframe", {
  # Regular data frame should error
  data <- data.frame(
    time = 1:3,
    x = 1:3,
    y = 4:6,
    confidence = c(0.5, 0.7, 0.9)
  )

  expect_error(
    mask_na_across(data, "confidence"),
    class = "rlang_error"
  )

  # Vector should error
  expect_error(
    mask_na_confidence(c(1, 2, 3)),
    class = "rlang_error"
  )
})

test_that("mask_na_confidence validates required columns exist", {
  # Create aniframe then modify metadata to have missing spatial variable
  data <- data.frame(
    time = 1:3,
    x = 1:3,
    y = 4:6,
    confidence = c(0.5, 0.7, 0.9)
  ) |>
    anicore::as_anipoint()

  # Dropping a declared column leaves `variables_where` promising it
  data <- dplyr::select(data, -x)

  expect_error(
    mask_na_across(data, "confidence"),
    "Missing spatial column"
  )
})

test_that("mask_na_confidence validates confidence column exists", {
  data <- data.frame(
    time = 1:3,
    x = 1:3,
    y = 4:6
  ) |>
    anicore::as_anipoint()

  expect_error(
    mask_na_across(data, "confidence"),
    "Missing required column.*confidence"
  )
})

test_that("mask_na_confidence validates threshold is single numeric", {
  data <- data.frame(
    time = 1:3,
    x = 1:3,
    y = 4:6,
    confidence = c(0.5, 0.7, 0.9)
  ) |>
    anicore::as_anipoint()

  # Non-numeric
  expect_error(
    mask_na_across(data, "confidence", threshold = "0.5"),
    class = "rlang_error"
  )

  # NA threshold
  expect_error(
    mask_na_across(data, "confidence", threshold = NA),
    class = "rlang_error"
  )

  # Vector threshold
  expect_error(
    mask_na_across(data, "confidence", threshold = c(0.5, 0.6)),
    class = "rlang_error"
  )
})

test_that("mask_na_confidence validates threshold is between 0 and 1", {
  data <- data.frame(
    time = 1:3,
    x = 1:3,
    y = 4:6,
    confidence = c(0.5, 0.7, 0.9)
  ) |>
    anicore::as_anipoint()

  # Below 0
  expect_error(
    mask_na_across(data, "confidence", threshold = -0.1),
    class = "rlang_error"
  )

  # Above 1
  expect_error(
    mask_na_across(data, "confidence", threshold = 1.1),
    class = "rlang_error"
  )
})

test_that("mask_na_confidence returns an aniframe", {
  data <- data.frame(
    time = 1:3,
    x = 1:3,
    y = 4:6,
    z = 7:9,
    confidence = c(0.5, 0.7, 0.9)
  ) |>
    anicore::as_anipoint(variables_where = c("x", "y", "z"))

  result <- mask_na_across(data, "confidence", threshold = 0.6)

  expect_s3_class(result, "anipoint")
  expect_equal(result$x, c(NA, 2, 3))
  expect_equal(result$z, c(NA, 8, 9))
})

test_that("mask_na_confidence validates confidence column is numeric", {
  data <- data.frame(
    time = 1:3,
    x = 1:3,
    y = 4:6,
    confidence = c("low", "medium", "high")
  ) |>
    anicore::as_anipoint()

  expect_error(
    mask_na_across(data, "confidence"),
    "confidence.*must be numeric"
  )
})

# --- coordinate-frame form (#30 step 2) -------------------------------------

test_that("mask_na_confidence requires confidence for a coordinate frame", {
  expect_error(
    mask_na_confidence(data.frame(x = 1:5, y = 1:5)),
    "`confidence` is required"
  )
})

test_that("mask_na_confidence coordinate-frame form masks the coordinates", {
  coords <- data.frame(x = c(1, 2, 3, 4), y = c(5, 6, 7, 8))
  conf <- c(0.9, 0.2, NA, 0.7)

  res <- suppressWarnings(
    mask_na_confidence(coords, threshold = 0.6, confidence = conf)
  )

  # Only the row below threshold is blanked; the missing one is left alone
  expect_equal(which(is.na(res$x)), 2L)
  expect_equal(which(is.na(res$y)), 2L)
  # `confidence` is not a coordinate, so nothing is added to the output
  expect_equal(names(res), c("x", "y"))
})

test_that("mask_na_confidence coordinate-frame form matches the aniframe form", {
  conf <- c(0.9, 0.2, NA, 0.7)
  d <- anicore::anipoint(
    time = 1:4,
    x = c(1, 2, 3, 4),
    y = c(5, 6, 7, 8),
    confidence = conf
  )
  for (missing in c("keep", "mask")) {
    expect_equal(
      mask_na_confidence(
        data.frame(x = c(1, 2, 3, 4), y = c(5, 6, 7, 8)),
        threshold = 0.6,
        confidence = conf,
        missing = missing
      ),
      as.data.frame(mask_na_across(
        d,
        "confidence",
        threshold = 0.6,
        missing = missing
      ))[, c("x", "y")],
      ignore_attr = TRUE,
      info = missing
    )
  }
})

test_that("mask_na_confidence rejects a mismatched confidence length", {
  expect_error(
    mask_na_confidence(
      data.frame(x = 1:5, y = 1:5),
      confidence = c(0.9, 0.8)
    ),
    "one value per row"
  )
})

test_that("mask_na_confidence rejects a non-numeric confidence", {
  expect_error(
    mask_na_confidence(
      data.frame(x = 1:5, y = 1:5),
      confidence = letters[1:5]
    ),
    "must be numeric"
  )
})

# --- missing confidence scores (#97) ----------------------------------------

unscored_fixture <- function() {
  anicore::anipoint(
    time = 1:5,
    x = c(1, 2, 3, NA, 5),
    y = c(6, 7, 8, NA, 10),
    confidence = c(0.9, NA, 0.2, NA, 0.8)
  )
}

test_that("missing = 'keep' leaves unscored rows unmasked", {
  out <- mask_na_across(unscored_fixture(), "confidence", missing = "keep")

  expect_equal(out$x, c(1, 2, NA, NA, 5))
  expect_equal(out$y, c(6, 7, NA, NA, 10))
  expect_equal(out$confidence, c(0.9, NA, NA, NA, 0.8))
})

test_that("missing = 'mask' masks unscored rows", {
  out <- mask_na_across(unscored_fixture(), "confidence", missing = "mask")

  expect_equal(out$x, c(1, NA, NA, NA, 5))
  expect_equal(out$y, c(6, NA, NA, NA, 10))
  expect_equal(out$confidence, c(0.9, NA, NA, NA, 0.8))
})

test_that("missing defaults to 'keep'", {
  d <- unscored_fixture()
  expect_equal(
    suppressWarnings(mask_na_across(d, "confidence")),
    mask_na_across(d, "confidence", missing = "keep")
  )
})

test_that("missing is passed through on a coordinate frame and by mask_na_with", {
  coords <- data.frame(x = c(1, 2, 3), y = c(4, 5, 6))
  conf <- c(0.9, NA, 0.2)

  kept <- mask_na_confidence(coords, confidence = conf, missing = "keep")
  masked <- mask_na_confidence(coords, confidence = conf, missing = "mask")
  expect_equal(kept$x, c(1, 2, NA))
  expect_equal(masked$x, c(1, NA, NA))
  expect_equal(masked$y, c(4, NA, NA))

  expect_equal(
    mask_na_with(coords, "confidence", confidence = conf, missing = "mask"),
    masked
  )
  expect_equal(
    mask_na_with(coords, "confidence", confidence = conf, missing = "keep"),
    kept
  )
})

test_that("missing confidence is not counted where positions are already NA", {
  # Row 4 has no score and no position, so masking it would change nothing
  d <- anicore::anipoint(
    time = 1:4,
    x = c(1, 2, 3, NA),
    y = c(5, 6, 7, NA),
    confidence = c(0.9, 0.8, 0.7, NA)
  )
  expect_no_warning(mask_na_across(d, "confidence"))
  expect_no_warning(
    mask_na_confidence(
      data.frame(x = c(1, NA), y = c(2, NA)),
      confidence = c(0.9, NA)
    )
  )

  # Row 2 of the fixture still has a position, row 4 does not: one is counted
  expect_warning(
    mask_na_across(unscored_fixture(), "confidence"),
    "^1 row has no confidence score and was left unmasked"
  )
})

test_that("a row with any position left counts as unscored", {
  d <- anicore::anipoint(
    time = 1:2,
    x = c(1, 2),
    y = c(3, NA),
    confidence = c(0.9, NA)
  )
  expect_warning(
    mask_na_across(d, "confidence"),
    "1 row has no confidence score"
  )
})

test_that("the missing-score warning names the argument and its values", {
  cnd <- rlang::catch_cnd(
    mask_na_across(unscored_fixture(), "confidence"),
    classes = "warning"
  )
  msg <- cli::ansi_strip(conditionMessage(cnd))

  expect_s3_class(cnd, "aniprocess_warning_unscored_confidence")
  expect_match(msg, "missing = \"mask\"", fixed = TRUE)
  expect_match(msg, "missing = \"keep\"", fixed = TRUE)
  expect_match(msg, "to mask it,", fixed = TRUE)
})

test_that("the missing-score warning is raised once, without mutate() context", {
  # Three groups, each with an unscored row that still has a position
  d <- anicore::anipoint(
    time = rep(1:3, 3),
    keypoint = rep(c("a", "b", "c"), each = 3),
    x = 1:9,
    y = 1:9,
    confidence = rep(c(0.9, NA, 0.8), 3)
  )
  expect_equal(dplyr::n_groups(d), 3L)

  warnings <- list()
  withCallingHandlers(
    mask_na_across(d, "confidence"),
    warning = function(cnd) {
      warnings[[length(warnings) + 1L]] <<- cnd
      invokeRestart("muffleWarning")
    }
  )

  expect_length(warnings, 1L)
  expect_s3_class(warnings[[1]], "aniprocess_warning_unscored_confidence")
  msg <- conditionMessage(warnings[[1]])
  expect_match(msg, "3 rows have no confidence score and were left unmasked")
  expect_no_match(msg, "mutate|group", perl = TRUE)

  # Not rate-limited: a second call warns again
  expect_warning(
    mask_na_across(d, "confidence"),
    class = "aniprocess_warning_unscored_confidence"
  )
})

test_that("the missing-score warning is quiet when missing is supplied", {
  d <- unscored_fixture()
  coords <- data.frame(x = c(1, 2), y = c(3, 4))

  expect_no_warning(mask_na_across(d, "confidence", missing = "keep"))
  expect_no_warning(mask_na_across(d, "confidence", missing = "mask"))
  expect_no_warning(
    mask_na_confidence(coords, confidence = c(0.9, NA), missing = "keep")
  )
  expect_no_warning(
    mask_na_with(
      coords,
      "confidence",
      confidence = c(0.9, NA),
      missing = "keep"
    )
  )
})

test_that("mask_na_confidence and mask_na_with warn when missing is not given", {
  coords <- data.frame(x = c(1, 2), y = c(3, 4))

  expect_warning(
    mask_na_confidence(coords, confidence = c(0.9, NA)),
    "1 row has no confidence score and was left unmasked",
    class = "aniprocess_warning_unscored_confidence"
  )
  expect_warning(
    mask_na_with(coords, "confidence", confidence = c(0.9, NA)),
    class = "aniprocess_warning_unscored_confidence"
  )
})

test_that("missing is validated", {
  coords <- data.frame(x = c(1, 2), y = c(3, 4))

  expect_error(
    mask_na_confidence(coords, confidence = c(0.9, NA), missing = "drop"),
    "`missing` must be one of \"keep\" or \"mask\""
  )
  # Checked before mutate(), so the error comes from mask_na_across() itself
  err <- rlang::catch_cnd(
    mask_na_across(unscored_fixture(), "confidence", missing = "drop"),
    classes = "error"
  )
  expect_match(conditionMessage(err), "`missing` must be one of")
  expect_equal(rlang::call_name(err$call), "mask_na_across")
  expect_error(
    mask_na_with(coords, "confidence", confidence = c(0.9, NA), missing = NA),
    class = "rlang_error"
  )
})
