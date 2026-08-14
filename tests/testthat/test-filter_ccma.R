# Tests for filter_ccma
# - Recovers a noiseless circle's radius better than plain MA (corner-cutting)
# - cc_mode = FALSE returns the moving-average path only
# - Output preserves input length and aniframe class
# - Works in 2D and 3D
# - Handles NA via na_action; restores NAs with keep_na
# - Errors on NA when na_action = "error"
# - Per-group: each track is filtered independently
# - Validates window widths, kernel, and dimension count

test_that("filter_ccma reduces radius shrinkage on a noiseless circle", {
  n <- 100
  t <- seq(0, 2 * pi, length.out = n)
  d <- aniframe::aniframe(
    time = seq_len(n),
    x = cos(t),
    y = sin(t),
    variables_what = character(0)
  )

  res_ma <- filter_across(
    d,
    "ccma",
    window_width_ma = 21,
    window_width_cc = 15,
    cc_mode = FALSE
  )
  res_cc <- filter_across(d, "ccma", window_width_ma = 21, window_width_cc = 15)

  ma_r <- mean(sqrt(res_ma$x^2 + res_ma$y^2))
  cc_r <- mean(sqrt(res_cc$x^2 + res_cc$y^2))

  # Plain MA shrinks the radius noticeably
  expect_lt(ma_r, 0.99)
  # CCMA recovers it to within 1%
  expect_gt(cc_r, 0.99)
  expect_lt(cc_r, 1.01)
})

test_that("filter_ccma cc_mode = FALSE returns only the moving-average result", {
  n <- 50
  t <- seq(0, 2 * pi, length.out = n)
  d <- aniframe::aniframe(
    time = seq_len(n),
    x = cos(t),
    y = sin(t),
    variables_what = character(0)
  )
  res_ma <- filter_across(d, "ccma", cc_mode = FALSE)
  # MA-only path on a circle should have radius < 1 (corner cutting present)
  expect_lt(mean(sqrt(res_ma$x^2 + res_ma$y^2)), 1)
})

test_that("filter_ccma preserves input length and aniframe class", {
  n <- 60
  d <- aniframe::aniframe(
    time = seq_len(n),
    x = rnorm(n),
    y = rnorm(n),
    variables_what = character(0)
  )
  res <- filter_across(d, "ccma")
  expect_equal(nrow(res), n)
  expect_s3_class(res, "aniframe")
})

test_that("filter_ccma works in 3D", {
  n <- 60
  t <- seq(0, 4 * pi, length.out = n)
  d <- aniframe::aniframe(
    time = seq_len(n),
    x = cos(t),
    y = sin(t),
    z = t / (4 * pi), # helix
    variables_where = c("x", "y", "z"),
    variables_what = character(0)
  )
  res <- filter_across(d, "ccma", window_width_ma = 7, window_width_cc = 5)
  expect_equal(nrow(res), n)
  expect_false(any(is.na(res$x)))
  expect_false(any(is.na(res$z)))
})

test_that("filter_ccma preserves NAs by default and fills with keep_na = FALSE", {
  n <- 60
  t <- seq(0, 2 * pi, length.out = n)
  x <- cos(t)
  y <- sin(t)
  x[c(10, 30)] <- NA
  d <- aniframe::aniframe(
    time = seq_len(n),
    x = x,
    y = y,
    variables_what = character(0)
  )

  res_filled <- filter_across(d, "ccma", keep_na = FALSE)
  expect_false(any(is.na(res_filled$x)))

  res_kept <- filter_across(d, "ccma")
  expect_true(is.na(res_kept$x[10]))
  expect_true(is.na(res_kept$x[30]))
  # y was clean — should still be clean
  expect_false(any(is.na(res_kept$y)))
})

test_that("filter_ccma errors when na_action = 'error' and NAs are present", {
  d <- aniframe::aniframe(
    time = 1:10,
    x = c(rnorm(9), NA),
    y = rnorm(10),
    variables_what = character(0)
  )
  expect_error(filter_across(d, "ccma", na_action = "error"), "NA")
})

test_that("filter_ccma operates per group", {
  # Two tracks, second one has different curvature
  n <- 60
  t <- seq(0, 2 * pi, length.out = n)
  d <- aniframe::aniframe(
    track = rep(c("a", "b"), each = n),
    time = rep(seq_len(n), 2),
    x = c(cos(t), 2 * cos(t)),
    y = c(sin(t), 2 * sin(t)),
    variables_what = "track"
  )

  res <- filter_across(d, "ccma", window_width_ma = 11, window_width_cc = 7)

  res_a <- res[res$track == "a", ]
  res_b <- res[res$track == "b", ]

  # Each track recovers its own radius
  expect_equal(mean(sqrt(res_a$x^2 + res_a$y^2)), 1, tolerance = 0.05)
  expect_equal(mean(sqrt(res_b$x^2 + res_b$y^2)), 2, tolerance = 0.05)
})

test_that("filter_ccma rejects 1-D variables_where", {
  d <- aniframe::aniframe(
    time = 1:10,
    x = rnorm(10),
    variables_where = "x",
    variables_what = character(0)
  )
  expect_error(filter_across(d, "ccma"), "2 or 3 coordinate columns")
})

test_that("filter_ccma validates window widths", {
  d <- aniframe::aniframe(
    time = 1:20,
    x = rnorm(20),
    y = rnorm(20),
    variables_what = character(0)
  )
  expect_error(filter_across(d, "ccma", window_width_ma = 0))
  expect_error(filter_across(d, "ccma", window_width_cc = -1))
  expect_error(filter_across(d, "ccma", window_width_ma = c(11, 13)))
})

test_that("filter_ccma rounds even window widths up to odd", {
  # Run with even width and confirm it produces the same result as the
  # next odd width up (i.e. the rounding actually happens).
  n <- 60
  t <- seq(0, 2 * pi, length.out = n)
  d <- aniframe::aniframe(
    time = seq_len(n),
    x = cos(t),
    y = sin(t),
    variables_what = character(0)
  )
  res_even <- filter_across(
    d,
    "ccma",
    window_width_ma = 10,
    window_width_cc = 6
  )
  res_odd <- filter_across(d, "ccma", window_width_ma = 11, window_width_cc = 7)
  expect_equal(res_even$x, res_odd$x)
})

test_that("filter_ccma uniform kernel runs and returns expected length", {
  n <- 60
  t <- seq(0, 2 * pi, length.out = n)
  d <- aniframe::aniframe(
    time = seq_len(n),
    x = cos(t),
    y = sin(t),
    variables_what = character(0)
  )
  res <- filter_across(d, "ccma", kernel = "uniform")
  expect_equal(nrow(res), n)
  expect_false(any(is.na(res$x)))
})

test_that("filter_ccma rejects input that is neither aniframe nor data frame", {
  expect_error(filter_ccma(1:5), "aniframe or a data frame")
  expect_error(filter_ccma("a"), "aniframe or a data frame")
})

test_that("filter_ccma accepts a coordinate frame and returns one", {
  t <- seq(0, 2 * pi, length.out = 60)
  coords <- data.frame(x = cos(t), y = sin(t))
  res <- filter_ccma(coords)

  expect_s3_class(res, "data.frame")
  expect_false(inherits(res, "aniframe"))
  expect_equal(names(res), c("x", "y"))
  expect_equal(nrow(res), 60)
})

test_that("filter_ccma coordinate-frame form matches the aniframe form", {
  t <- seq(0, 2 * pi, length.out = 60)
  d <- aniframe::aniframe(
    time = seq_len(60),
    x = cos(t),
    y = sin(t),
    variables_what = character(0)
  )
  expect_equal(
    filter_ccma(data.frame(x = cos(t), y = sin(t))),
    as.data.frame(filter_across(d, "ccma"))[, c("x", "y")],
    ignore_attr = TRUE
  )
})

test_that("filter_ccma rejects a coordinate frame with a non-numeric column", {
  expect_error(
    filter_ccma(data.frame(x = 1:5, y = letters[1:5])),
    "must be numeric"
  )
})

test_that("filter_ccma errors when a variables_where column is missing", {
  d <- aniframe::aniframe(
    time = 1:10,
    x = rnorm(10),
    y = rnorm(10),
    variables_what = character(0)
  )
  d <- aniframe::set_metadata(d, variables_where = c("x", "y", "z"))
  expect_error(filter_across(d, "ccma"), "Missing spatial column")
})

test_that("filter_ccma errors when a spatial column is non-numeric", {
  d <- aniframe::aniframe(
    time = 1:10,
    x = rnorm(10),
    y = rnorm(10),
    variables_what = character(0)
  )
  d$x <- as.character(d$x)
  expect_error(filter_across(d, "ccma"), "must be numeric")
})

test_that("filter_ccma returns the input when NAs cannot be filled", {
  # An all-NA column triggers the can't-interpolate fallback.
  n <- 30
  t <- seq(0, 2 * pi, length.out = n)
  d <- aniframe::aniframe(
    time = seq_len(n),
    x = rep(NA_real_, n),
    y = sin(t),
    variables_what = character(0)
  )
  suppressWarnings(out <- filter_across(d, "ccma"))
  expect_true(all(is.na(out$x)))
})

test_that("filter_ccma passes through trajectories shorter than 3 points", {
  d <- aniframe::aniframe(
    time = 1:2,
    x = c(0, 1),
    y = c(0, 1),
    variables_what = character(0)
  )
  out <- filter_across(d, "ccma")
  expect_equal(out$x, c(0, 1))
  expect_equal(out$y, c(0, 1))
})

test_that("filter_ccma handles straight-line trajectories (zero curvature)", {
  # Curvature is zero everywhere, so the curvature-correction loop hits
  # the `next` branch for every position. A constant column is preserved
  # under both MA and the (zero) curvature shift, and the interior of a
  # linear column is reproduced exactly.
  n <- 30
  d <- aniframe::aniframe(
    time = seq_len(n),
    x = seq_len(n) * 1.0,
    y = rep(0, n),
    variables_what = character(0)
  )
  out <- filter_across(d, "ccma", window_width_ma = 5, window_width_cc = 3)
  expect_equal(out$y, rep(0, n), tolerance = 1e-9)
  # Interior of x is fully supported by the MA window (no padding bleed).
  interior <- 6:25
  expect_equal(out$x[interior], as.numeric(interior), tolerance = 1e-9)
})

test_that("ccma_kernel rejects unknown kernel types", {
  expect_error(ccma_kernel(5, "made_up_kernel"), "Unknown kernel type")
})

test_that("filter_ccma rejects non-Cartesian coordinate systems", {
  d <- aniframe::aniframe(
    time = 1:10,
    x = rnorm(10),
    y = rnorm(10),
    variables_what = character(0)
  )
  cs_levels <- levels(aniframe::get_metadata(d, "coordinate_system"))
  for (cs in c("polar", "cylindrical", "spherical", "unknown")) {
    bad <- aniframe::set_metadata(
      d,
      coordinate_system = factor(cs, levels = cs_levels)
    )
    expect_error(filter_across(bad, "ccma"), "Cartesian coordinate system")
  }
})

# --- grouping ---------------------------------------------------------------

test_that("filter_ccma smooths each group independently", {
  # Filtering a grouped frame must equal filtering each group on its own.
  np <- 60
  t <- seq(0, 2 * pi, length.out = np)
  a <- data.frame(time = seq_len(np), x = cos(t), y = sin(t))
  b <- data.frame(time = seq_len(np), x = cos(t) + 5000, y = sin(t) + 5000)

  grouped <- aniframe::aniframe(
    time = c(a$time, b$time),
    individual = rep(c("a", "b"), each = np),
    x = c(a$x, b$x),
    y = c(a$y, b$y),
    variables_what = "individual"
  ) |>
    dplyr::group_by(individual)

  alone <- function(d) filter_ccma(data.frame(x = d$x, y = d$y))

  expect_equal(
    as.data.frame(filter_across(grouped, "ccma"))[, c("x", "y")],
    rbind(alone(a), alone(b)),
    ignore_attr = TRUE
  )
})

test_that("filter_ccma reports the coordinate count it was given", {
  expect_error(
    filter_ccma(data.frame(x = as.numeric(1:6))),
    "2 or 3 coordinate columns"
  )
  expect_error(
    filter_ccma(data.frame(a = 1:6, b = 1:6, c = 1:6, d = 1:6)),
    "2 or 3 coordinate columns"
  )
})
