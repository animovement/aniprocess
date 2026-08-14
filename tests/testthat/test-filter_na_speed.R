# Tests for filter_na_speed
# - Flags single-frame outliers (2D and 3D)
# - Leaves legitimate step changes alone (sustained moves to a new region)
# - Does not contaminate neighbors of NA inputs
# - Automatic threshold calculation
# - Preserves existing NAs
# - Preserves other columns
# - Filters confidence when present
# - Works without confidence column
# - Validates inputs (aniframe class, required columns, numeric types, threshold)
# - Returns an aniframe
# - Handles constant position and uneven time spacing
# - Speed helpers: correct values for constant velocity (2D and 3D)
# - Speed helpers: one-sided fallback at endpoints

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
    "Missing spatial column"
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

test_that("calculate_step_speed computes correct values in 2D", {
  # Constant velocity of 1 in x direction
  coords <- data.frame(x = c(0, 1, 2, 3, 4), y = c(0, 0, 0, 0, 0))
  time <- c(0, 1, 2, 3, 4)

  speed <- calculate_step_speed(coords, time)

  expect_true(all(abs(speed - 1) < 1e-9))
})

test_that("calculate_step_speed computes correct values in 3D", {
  coords <- data.frame(
    x = c(0, 1, 2, 3, 4),
    y = c(0, 0, 0, 0, 0),
    z = c(0, 0, 0, 0, 0)
  )
  time <- c(0, 1, 2, 3, 4)

  speed <- calculate_step_speed(coords, time)

  expect_true(all(abs(speed - 1) < 1e-9))
})

test_that("calculate_step_speed is dimension-agnostic", {
  # A 3-4-5 triangle per step: distance 5 per unit time
  coords <- data.frame(x = c(0, 3, 6), y = c(0, 4, 8))
  expect_equal(calculate_step_speed(coords, c(0, 1, 2)), c(5, 5, 5))

  # 1D falls out of the same code path
  expect_equal(
    calculate_step_speed(data.frame(x = c(0, 2, 4)), c(0, 1, 2)),
    c(2, 2, 2)
  )
})

test_that("calculate_step_speed uses one-sided fallback at endpoints", {
  coords <- data.frame(x = c(0, 1, 2, 3, 4), y = c(0, 0, 0, 0, 0))
  time <- c(0, 1, 2, 3, 4)

  speed <- calculate_step_speed(coords, time)

  # Endpoints should fall back to the one-sided step (no NA)
  expect_false(is.na(speed[1]))
  expect_false(is.na(speed[length(speed)]))
})

test_that("calculate_step_speed returns NA for groups too short to step", {
  expect_equal(calculate_step_speed(data.frame(x = 1), 1), NA_real_)
  expect_equal(
    calculate_step_speed(data.frame(x = numeric(0)), numeric(0)),
    numeric(0)
  )
})

test_that("filter_na_speed errors when time column is missing", {
  data <- aniframe::aniframe(
    time = 1:5,
    x = 1:5,
    y = 1:5,
    variables_what = character(0)
  )
  data$time <- NULL
  expect_error(filter_na_speed(data), "Missing required column.*time")
})

# --- grouping (issue #37) ---------------------------------------------------

# Two individuals stacked in one aniframe, `sep` units apart, time restarting
# per individual. Individual "a" has one genuine single-frame outlier.
speed_fixture <- function(sep) {
  aniframe::aniframe(
    time = rep(1:10, 2),
    individual = rep(c("a", "b"), each = 10),
    x = c(c(0:3, 500, 5:9), (0:9) + sep),
    y = rep(0, 20),
    variables_what = "individual"
  ) |>
    dplyr::group_by(individual)
}

test_that("filter_na_speed does not form steps across group boundaries", {
  d <- speed_fixture(1e4)
  speed <- dplyr::mutate(
    d,
    sp = calculate_step_speed(dplyr::pick(dplyr::all_of(c("x", "y"))), time)
  )$sp

  # No negative speed: a cross-boundary step would have dt = 1 - 10 = -9
  expect_true(all(speed >= 0, na.rm = TRUE))
  # The boundary rows see only their own track
  expect_equal(speed[10], 1)
  expect_equal(speed[11], 1)
})

test_that("filter_na_speed detection is independent of other tracks", {
  # The outlier in "a" is identical throughout; only "b" moves further away.
  # Before the fix, the contaminated auto threshold missed it from 1e4 up.
  for (sep in c(1e3, 1e4, 1e5, 1e7)) {
    expect_equal(
      which(is.na(filter_na_speed(speed_fixture(sep))$x)),
      5L,
      info = paste("separation", sep)
    )
  }
})

test_that("filter_na_speed auto threshold ignores cross-track steps", {
  # Two stationary individuals: every within-track speed is 0, so the
  # threshold must be 0 no matter how far apart they are.
  fixture <- function(sep) {
    aniframe::aniframe(
      time = rep(1:10, 2),
      individual = rep(c("a", "b"), each = 10),
      x = c(rep(0, 10), rep(sep, 10)),
      y = rep(0, 20),
      variables_what = "individual"
    ) |>
      dplyr::group_by(individual)
  }
  for (sep in c(1e3, 1e6)) {
    d <- fixture(sep)
    speed <- dplyr::mutate(
      d,
      sp = calculate_step_speed(dplyr::pick(dplyr::all_of(c("x", "y"))), time)
    )$sp
    expect_equal(mean(speed, na.rm = TRUE), 0)
    expect_true(!any(is.na(filter_na_speed(d)$x)))
  }
})

test_that("filter_na_speed leaves one-row groups untouched", {
  # A group with fewer than two rows has no step, so speed is NA. if_else()
  # propagates a missing condition, which would blank an otherwise fine row.
  d <- aniframe::aniframe(
    time = c(1, 2, 3, 1),
    individual = c("a", "a", "a", "solo"),
    x = c(0, 1, 2, 42),
    y = rep(0, 4),
    confidence = rep(0.9, 4),
    variables_what = "individual"
  ) |>
    dplyr::group_by(individual)

  res <- filter_na_speed(d, threshold = 0.5)
  expect_false(is.na(res$x[4]))
  expect_equal(res$x[4], 42)
  expect_false(is.na(res$confidence[4]))
})

test_that("filter_na_speed is unchanged on ungrouped data", {
  d <- aniframe::aniframe(
    time = 1:10,
    x = c(0:3, 500, 5:9),
    y = rep(0, 10),
    variables_what = character(0)
  )
  expect_equal(which(is.na(filter_na_speed(d, threshold = 100)$x)), 5L)

  # A frame with a single group must behave exactly like an ungrouped one
  d_one_group <- d |>
    dplyr::mutate(individual = "a") |>
    dplyr::group_by(individual)
  expect_equal(
    filter_na_speed(d_one_group, threshold = 100)$x,
    filter_na_speed(d, threshold = 100)$x
  )
})

# --- coordinate-frame form (#30 step 2) -------------------------------------

test_that("filter_na_speed requires time for a coordinate frame", {
  expect_error(
    filter_na_speed(data.frame(x = 1:5, y = 1:5)),
    "`time` is required"
  )
})

test_that("filter_na_speed coordinate-frame form matches the aniframe form", {
  x <- c(0:3, 500, 5:9)
  y <- rep(0, 10)
  tm <- 1:10
  d <- aniframe::aniframe(
    time = tm, x = x, y = y, variables_what = character(0)
  )
  expect_equal(
    filter_na_speed(data.frame(x = x, y = y), threshold = 100, time = tm),
    as.data.frame(filter_na_speed(d, threshold = 100))[, c("x", "y")],
    ignore_attr = TRUE
  )
})

test_that("filter_na_speed works inside mutate via pick()", {
  set.seed(9)
  np <- 20
  d <- aniframe::aniframe(
    time = rep(seq_len(np), 2),
    individual = rep(c("a", "b"), each = np),
    x = c(c(0:8, 500, 10:19), (0:19) + 1000),
    y = rep(0, 2 * np),
    variables_what = "individual"
  ) |>
    dplyr::group_by(individual)

  via_pick <- dplyr::mutate(
    d,
    filter_na_speed(
      dplyr::pick(dplyr::all_of(c("x", "y"))),
      threshold = 100,
      time = time
    )
  )
  expect_equal(
    as.data.frame(via_pick)[, c("x", "y")],
    as.data.frame(filter_na_speed(d, threshold = 100))[, c("x", "y")]
  )
})

test_that("filter_na_speed rejects a mismatched time length", {
  expect_error(
    filter_na_speed(data.frame(x = 1:5, y = 1:5), time = 1:3),
    "one value per row"
  )
})
