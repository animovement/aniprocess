# Tests for filter_na_excursion
# - Flags a multi-frame excursion that returns
# - Leaves persistent shifts alone (the algorithm's distinguishing feature)
# - Per-axis behaviour: a jump in one axis flags the whole row
# - by_axis = FALSE uses joint Euclidean displacement
# - Blanks confidence at flagged rows
# - Per-group: each group has its own σ / median / state machine
# - Returns an aniframe of the same shape
# - Validation: aniframe class, missing column, non-numeric column,
#   threshold parameters

test_that("filter_na_excursion flags a multi-frame excursion that returns", {
  set.seed(1)
  n <- 200
  x <- rnorm(n, 0, 1)
  y <- rnorm(n, 0, 1)
  # Insert a 3-frame excursion at indices 100:102; index 103 returns.
  x[100:102] <- 50
  y[100:102] <- 50

  d <- aniframe::aniframe(
    time = seq_len(n),
    x = x,
    y = y,
    variables_what = character(0)
  )
  out <- filter_na_excursion(d)

  expect_true(all(is.na(out$x[100:102])))
  expect_true(all(is.na(out$y[100:102])))
  expect_false(is.na(out$x[99]))
  expect_false(is.na(out$x[103]))
})

test_that("filter_na_excursion leaves persistent shifts untouched", {
  # When the trajectory genuinely shifts to a new region, σ is inflated
  # by the shift itself, so the trigger threshold exceeds the jump size.
  # The algorithm correctly keeps this case alone.
  set.seed(2)
  n <- 200
  x <- c(rnorm(n / 2, 0, 1), rnorm(n / 2, 100, 1))
  y <- c(rnorm(n / 2, 0, 1), rnorm(n / 2, 100, 1))

  d <- aniframe::aniframe(
    time = seq_len(n),
    x = x,
    y = y,
    variables_what = character(0)
  )
  out <- filter_na_excursion(d)

  expect_false(any(is.na(out$x)))
  expect_false(any(is.na(out$y)))
})

test_that("filter_na_excursion (per-axis) flags a row when only one axis jumps", {
  set.seed(3)
  n <- 200
  x <- rnorm(n, 0, 1)
  y <- rnorm(n, 0, 1)
  # Only x jumps; y stays normal.
  x[100:102] <- 50

  d <- aniframe::aniframe(
    time = seq_len(n),
    x = x,
    y = y,
    variables_what = character(0)
  )
  out <- filter_na_excursion(d, by_axis = TRUE)

  expect_true(all(is.na(out$x[100:102])))
  # Per-axis OR: the whole row is blanked even though y was fine.
  expect_true(all(is.na(out$y[100:102])))
})

test_that("filter_na_excursion (joint Euclidean) flags only when magnitude is large", {
  # If only x jumps modestly but y is normal, the joint magnitude may
  # not cross the joint threshold. Test the joint codepath runs.
  set.seed(4)
  n <- 200
  x <- rnorm(n, 0, 1)
  y <- rnorm(n, 0, 1)
  x[100:102] <- 50
  y[100:102] <- 50

  d <- aniframe::aniframe(
    time = seq_len(n),
    x = x,
    y = y,
    variables_what = character(0)
  )
  out <- filter_na_excursion(d, by_axis = FALSE)

  expect_true(all(is.na(out$x[100:102])))
  expect_true(all(is.na(out$y[100:102])))
})

test_that("filter_na_excursion blanks confidence at flagged rows", {
  set.seed(5)
  n <- 200
  x <- rnorm(n, 0, 1)
  y <- rnorm(n, 0, 1)
  x[100:102] <- 50
  y[100:102] <- 50
  conf <- rep(0.9, n)

  d <- aniframe::aniframe(
    time = seq_len(n),
    x = x,
    y = y,
    confidence = conf,
    variables_what = character(0)
  )
  out <- filter_na_excursion(d)

  expect_true(all(is.na(out$confidence[100:102])))
  expect_false(is.na(out$confidence[1]))
})

test_that("filter_na_excursion runs per group", {
  # Two tracks. Track a has an excursion at frame 100; track b doesn't.
  # Each track's σ / median is independent.
  set.seed(6)
  n <- 200
  x_a <- rnorm(n, 0, 1)
  x_a[100:102] <- 50
  x_b <- rnorm(n, 0, 1)
  y_a <- rnorm(n, 0, 1)
  y_a[100:102] <- 50
  y_b <- rnorm(n, 0, 1)

  d <- aniframe::aniframe(
    track = rep(c("a", "b"), each = n),
    time = rep(seq_len(n), 2),
    x = c(x_a, x_b),
    y = c(y_a, y_b),
    variables_what = "track"
  )
  out <- filter_na_excursion(d)

  out_a <- out[out$track == "a", ]
  out_b <- out[out$track == "b", ]

  expect_true(all(is.na(out_a$x[100:102])))
  expect_false(any(is.na(out_b$x)))
})

test_that("filter_na_excursion returns an aniframe of the same shape", {
  d <- aniframe::aniframe(
    time = 1:50,
    x = rnorm(50),
    y = rnorm(50),
    variables_what = character(0)
  )
  out <- filter_na_excursion(d)
  expect_s3_class(out, "aniframe")
  expect_equal(nrow(out), 50)
  expect_equal(names(out), names(d))
})

test_that("filter_na_excursion handles trajectories with no σ (constant data)", {
  # σ = 0 means we cannot define the threshold; the algorithm should
  # bail out gracefully and leave data untouched.
  d <- aniframe::aniframe(
    time = 1:20,
    x = rep(5, 20),
    y = rep(5, 20),
    variables_what = character(0)
  )
  out <- filter_na_excursion(d)
  expect_false(any(is.na(out$x)))
  expect_false(any(is.na(out$y)))
})

test_that("filter_na_excursion rejects non-aniframe input", {
  d <- data.frame(time = 1:5, x = 1:5, y = 1:5)
  expect_error(filter_na_excursion(d), class = "rlang_error")
})

test_that("filter_na_excursion errors when a variables_where column is missing", {
  d <- aniframe::aniframe(
    time = 1:10,
    x = rnorm(10),
    y = rnorm(10),
    variables_what = character(0)
  )
  d <- aniframe::set_metadata(d, variables_where = c("x", "y", "z"))
  expect_error(filter_na_excursion(d), "Missing spatial column")
})

test_that("filter_na_excursion errors on non-numeric spatial columns", {
  d <- aniframe::aniframe(
    time = 1:10,
    x = rnorm(10),
    y = rnorm(10),
    variables_what = character(0)
  )
  d$x <- as.character(d$x)
  expect_error(filter_na_excursion(d), "must be numeric")
})

test_that("filter_na_excursion validates threshold arguments", {
  d <- aniframe::aniframe(
    time = 1:50,
    x = rnorm(50),
    y = rnorm(50),
    variables_what = character(0)
  )
  expect_error(filter_na_excursion(d, outlier_sd = 0))
  expect_error(filter_na_excursion(d, outlier_sd = -1))
  expect_error(filter_na_excursion(d, outlier_sd = c(1, 2)))
  expect_error(filter_na_excursion(d, return_sd = 0))
})

test_that("filter_na_excursion handles short trajectories", {
  d <- aniframe::aniframe(
    time = 1:1,
    x = 1,
    y = 1,
    variables_what = character(0)
  )
  expect_no_error(filter_na_excursion(d))
})

test_that("filter_na_excursion (joint) bails out on constant data", {
  d <- aniframe::aniframe(
    time = 1:20,
    x = rep(5, 20),
    y = rep(5, 20),
    variables_what = character(0)
  )
  out <- filter_na_excursion(d, by_axis = FALSE)
  expect_false(any(is.na(out$x)))
  expect_false(any(is.na(out$y)))
})

test_that("filter_na_excursion preserves existing NAs", {
  set.seed(7)
  n <- 100
  x <- rnorm(n, 0, 1)
  y <- rnorm(n, 0, 1)
  x[c(10, 50)] <- NA
  y[c(20, 60)] <- NA
  d <- aniframe::aniframe(
    time = seq_len(n),
    x = x,
    y = y,
    variables_what = character(0)
  )
  for (mode in c(TRUE, FALSE)) {
    out <- filter_na_excursion(d, by_axis = mode)
    expect_true(is.na(out$x[10]))
    expect_true(is.na(out$x[50]))
  }
})
