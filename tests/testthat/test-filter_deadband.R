# Tests for filter_deadband
# - A still point with noise below the threshold comes out exactly still
# - "hold" jumps to the point; "drag" trails it by exactly the threshold
# - The dead zone is Euclidean, not per axis
# - threshold = 0 is the identity
# - Missing values: left as they are, anchor kept across gaps up to max_gap
# - Shape, names, one and three columns
# - Parameter validation
# - Reachable through filter_with() and filter_across()

path_length <- function(d) {
  m <- as.matrix(d)
  sum(sqrt(rowSums(diff(m)^2)), na.rm = TRUE)
}

# --- the defining property ---------------------------------------------------

test_that("noise below the threshold is removed entirely", {
  set.seed(1)
  coords <- data.frame(x = 5 + rnorm(200, sd = 0.01), y = rnorm(200, sd = 0.01))

  for (mode in c("hold", "drag")) {
    out <- filter_deadband(coords, threshold = 0.2, mode = mode)
    expect_equal(out$x, rep(coords$x[1], 200), info = mode)
    expect_equal(out$y, rep(coords$y[1], 200), info = mode)
    expect_equal(path_length(out), 0, info = mode)
  }
})

test_that("hold jumps to the point once it is more than threshold away", {
  coords <- data.frame(x = c(0, 0.5, 1, 1.5, 3, 3.2, 3.1))
  out <- filter_deadband(coords, threshold = 1)

  # 0.5 and 1 are within 1 of the anchor at 0; 1.5 is not, and becomes the
  # anchor; 3 is more than 1 from 1.5; 3.2 and 3.1 are within 1 of 3.
  expect_equal(out$x, c(0, 0, 0, 1.5, 3, 3, 3))
})

test_that("a point exactly threshold away does not move the anchor", {
  coords <- data.frame(x = c(0, 1, 2.5))
  expect_equal(filter_deadband(coords, threshold = 1)$x, c(0, 0, 2.5))
})

test_that("drag trails a steady movement by exactly the threshold", {
  coords <- data.frame(x = seq(0, 10, by = 0.25), y = 0)
  out <- filter_deadband(coords, threshold = 1, mode = "drag")

  moving <- coords$x > 1
  expect_equal(out$x[moving], coords$x[moving] - 1)
  expect_equal(out$x[!moving], rep(0, sum(!moving)))
  expect_equal(out$y, coords$y)
})

test_that("drag never steps further than the point did", {
  set.seed(2)
  coords <- data.frame(x = cumsum(rnorm(300)), y = cumsum(rnorm(300)))
  out <- filter_deadband(coords, threshold = 0.5, mode = "drag")

  raw_steps <- sqrt(rowSums(diff(as.matrix(coords))^2))
  out_steps <- sqrt(rowSums(diff(as.matrix(out))^2))
  expect_true(all(out_steps <= raw_steps + 1e-12))

  # ...and stays within the threshold of it
  lag <- sqrt(rowSums((as.matrix(coords) - as.matrix(out))^2))
  expect_true(all(lag <= 0.5 + 1e-12))
})

test_that("the dead zone is Euclidean, not per axis", {
  # Each axis moves 0.8, less than the threshold; together they move 1.13.
  coords <- data.frame(x = c(0, 0.8), y = c(0, 0.8))
  out <- filter_deadband(coords, threshold = 1)
  expect_equal(out$x, c(0, 0.8))
  expect_equal(out$y, c(0, 0.8))

  # Each axis on its own stays put.
  expect_equal(filter_deadband(coords["x"], threshold = 1)$x, c(0, 0))
})

test_that("threshold = 0 returns the data unchanged", {
  set.seed(3)
  coords <- data.frame(x = rnorm(50), y = rnorm(50))
  expect_equal(filter_deadband(coords, threshold = 0), coords)
  expect_equal(filter_deadband(coords, threshold = 0, mode = "drag"), coords)
})

test_that("it works in three dimensions", {
  coords <- data.frame(x = c(0, 0.6, 0.6), y = c(0, 0.6, 0.6), z = c(0, 0, 0.6))
  out <- filter_deadband(coords, threshold = 1)

  # (0.6, 0.6, 0) is 0.85 away; (0.6, 0.6, 0.6) is 1.04 away.
  expect_equal(out$x, c(0, 0, 0.6))
  expect_equal(out$z, c(0, 0, 0.6))
})

# --- missing values -----------------------------------------------------------

test_that("incomplete rows are left as they are and do not move the anchor", {
  coords <- data.frame(
    x = c(0, NA, 5, 0.1, 0.2),
    y = c(0, NA, NA, 0.1, 0)
  )
  out <- filter_deadband(coords, threshold = 1)

  expect_equal(out$x, c(0, NA, 5, 0, 0))
  expect_equal(out$y, c(0, NA, NA, 0, 0))
})

test_that("the anchor is kept across a gap up to max_gap rows", {
  coords <- data.frame(x = c(0, NA, NA, 0.5))

  expect_equal(filter_deadband(coords, threshold = 1)$x, c(0, NA, NA, 0))
  expect_equal(
    filter_deadband(coords, threshold = 1, max_gap = 2)$x,
    c(0, NA, NA, 0)
  )
  # A longer gap starts afresh from the next complete row.
  expect_equal(
    filter_deadband(coords, threshold = 1, max_gap = 1)$x,
    c(0, NA, NA, 0.5)
  )
})

test_that("leading missing rows are skipped", {
  coords <- data.frame(x = c(NA, NA, 3, 3.5, 5))
  expect_equal(filter_deadband(coords, threshold = 1)$x, c(NA, NA, 3, 3, 5))
})

test_that("an all-missing frame is returned as it is", {
  coords <- data.frame(x = c(NA_real_, NA_real_), y = c(NA_real_, NA_real_))
  expect_equal(filter_deadband(coords, threshold = 1), coords)
})

test_that("an empty frame is returned as it is", {
  coords <- data.frame(x = numeric(0), y = numeric(0))
  expect_equal(filter_deadband(coords, threshold = 1), coords)
})

# --- shape --------------------------------------------------------------------

test_that("names, row count and class are kept", {
  coords <- dplyr::tibble(a = c(0, 0.1, 2), b = c(0, 0, 0))
  out <- filter_deadband(coords, threshold = 1)

  expect_s3_class(out, "tbl_df")
  expect_named(out, c("a", "b"))
  expect_equal(nrow(out), 3)
})

test_that("integer columns are accepted", {
  coords <- data.frame(x = c(0L, 1L, 3L))
  expect_equal(filter_deadband(coords, threshold = 1.5)$x, c(0, 0, 3))
})

# --- validation ---------------------------------------------------------------

test_that("filter_deadband validates its arguments", {
  coords <- data.frame(x = 1:5, y = 1:5)

  expect_error(filter_deadband(1:5, threshold = 1), "data frame of coordinates")
  expect_error(filter_deadband(coords), "threshold")
  expect_error(filter_deadband(coords, threshold = -1), "non-negative")
  expect_error(filter_deadband(coords, threshold = NA), "non-negative")
  expect_error(filter_deadband(coords, threshold = c(1, 2)), "non-negative")
  expect_error(filter_deadband(coords, threshold = 1, mode = "jump"))
  expect_error(filter_deadband(coords, threshold = 1, max_gap = -1), "max_gap")
  expect_error(filter_deadband(coords, threshold = 1, max_gap = 1.5), "max_gap")
  expect_error(filter_deadband(coords, threshold = 1, max_gap = NA), "max_gap")
  expect_error(
    filter_deadband(data.frame(x = "a"), threshold = 1),
    "must be numeric"
  )
})

# --- dispatch -----------------------------------------------------------------

test_that("filter_with dispatches deadband on a frame", {
  coords <- data.frame(x = c(0, 0.5, 2), y = c(0, 0, 0))
  expect_equal(
    filter_with(coords, "deadband", threshold = 1),
    filter_deadband(coords, threshold = 1)
  )
  expect_error(
    filter_with(c(0, 0.5, 2), "deadband", threshold = 1),
    "needs a frame of coordinate columns"
  )
})

test_that("filter_across applies deadband jointly, within groups", {
  set.seed(4)
  np <- 40
  d <- anicore::anipoint(
    time = rep(seq_len(np), 2),
    individual = rep(c("a", "b"), each = np),
    x = c(rnorm(np, sd = 0.05), rnorm(np, sd = 0.05) + 100),
    y = c(rnorm(np, sd = 0.05), rnorm(np, sd = 0.05) + 100),
    variables_what = "individual"
  ) |>
    dplyr::group_by(individual)

  out <- filter_across(d, "deadband", threshold = 0.5)
  expect_s3_class(out, "aniframe")

  for (id in c("a", "b")) {
    rows <- d$individual == id
    expected <- filter_deadband(
      data.frame(x = d$x[rows], y = d$y[rows]),
      threshold = 0.5
    )
    expect_equal(out$x[rows], expected$x, info = id)
    expect_equal(out$y[rows], expected$y, info = id)
  }
  # Each individual starts from its own first point, not the other's.
  expect_equal(unique(out$x[d$individual == "b"]), d$x[np + 1])
})

test_that("filter_across rejects deadband on a non-Cartesian frame", {
  d <- anicore::anipoint(
    time = 1:10,
    x = rnorm(10),
    y = rnorm(10),
    variables_what = character(0)
  )
  cs_levels <- levels(anicore::get_metadata(d, "coordinate_system"))
  bad <- anicore::set_metadata(
    d,
    coordinate_system = factor("polar", levels = cs_levels)
  )
  expect_error(
    filter_across(bad, "deadband", threshold = 1),
    "Cartesian coordinate system"
  )
})

test_that("filter_across refuses on_deltas for deadband", {
  d <- anicore::anipoint(
    time = 1:10,
    x = rnorm(10),
    y = rnorm(10),
    variables_what = character(0)
  )
  expect_error(
    filter_across(d, "deadband", threshold = 1, on_deltas = TRUE),
    "on_deltas"
  )
})
