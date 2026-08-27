# Tests for filter_na_across()
# - "range" is applied column by column; the rest jointly
# - time and confidence come from the aniframe
# - confidence is blanked on rows this call masked
# - Grouping is respected

na_fixture <- function(np = 20) {
  anicore::aniframe(
    time = rep(seq_len(np), 2),
    individual = rep(c("a", "b"), each = np),
    x = c(c(0:8, 500, 10:(np - 1)), (0:(np - 1)) + 1000),
    y = rep(0, 2 * np),
    confidence = rep(0.9, 2 * np),
    variables_what = "individual"
  ) |>
    dplyr::group_by(individual)
}

test_that("filter_na_across applies range column by column", {
  d <- na_fixture()
  out <- filter_na_across(d, "range", min_value = 0, max_value = 100)

  expect_equal(out$x, filter_na_range(d$x, min_value = 0, max_value = 100))
  expect_equal(out$y, filter_na_range(d$y, min_value = 0, max_value = 100))
})

test_that("filter_na_across takes the time column from metadata", {
  d <- na_fixture()

  # naming the column explicitly gives the same answer as the metadata default
  expect_equal(
    filter_na_across(d, "speed", threshold = 100)$x,
    filter_na_across(d, "speed", threshold = 100, time = "time")$x
  )
})

test_that("filter_na_across rejects a vector for a per-row argument", {
  d <- na_fixture()

  expect_error(
    filter_na_across(d, "speed", threshold = 100, time = d$time),
    "must be the name of a column"
  )
})

test_that("filter_na_across masks the outlier and blanks its confidence", {
  d <- na_fixture()
  out <- filter_na_across(d, "speed", threshold = 100)

  expect_equal(which(is.na(out$x)), 10L)
  expect_true(is.na(out$confidence[10]))
  # Untouched rows keep their confidence
  expect_false(any(is.na(out$confidence[-10])))
})

test_that("filter_na_across leaves confidence alone where nothing was masked", {
  d <- na_fixture()
  out <- filter_na_across(d, "speed", threshold = 1e6)

  expect_false(any(is.na(out$x)))
  expect_false(any(is.na(out$confidence)))
})

test_that("filter_na_across dispatches excursion and roi", {
  set.seed(31)
  np <- 40
  x <- rnorm(np, sd = 2)
  x[10:12] <- x[10:12] + 40
  d <- anicore::aniframe(
    time = seq_len(np),
    x = x,
    y = rnorm(np, sd = 2),
    variables_what = character(0)
  )

  expect_equal(
    as.data.frame(filter_na_across(d, "excursion"))[, c("x", "y")],
    as.data.frame(filter_na_excursion(d))[, c("x", "y")]
  )

  coords <- data.frame(x = c(0, 10, 20), y = c(0, 10, 20))
  d2 <- anicore::aniframe(
    time = 1:3,
    x = coords$x,
    y = coords$y,
    variables_what = character(0)
  )
  expect_equal(
    as.data.frame(filter_na_across(d2, "roi", x_min = 5, x_max = 15))[,
      c("x", "y")
    ],
    as.data.frame(filter_na_roi(d2, x_min = 5, x_max = 15))[, c("x", "y")]
  )
})

test_that("filter_na_across dispatches confidence and filters the column", {
  d <- anicore::aniframe(
    time = 1:4,
    x = c(1, 2, 3, 4),
    y = c(5, 6, 7, 8),
    confidence = c(0.9, 0.2, 0.8, 0.7)
  )
  out <- filter_na_across(d, "confidence", threshold = 0.6)

  expect_equal(which(is.na(out$x)), 2L)
  expect_true(is.na(out$confidence[2]))
  expect_equal(out$confidence[c(1, 3, 4)], c(0.9, 0.8, 0.7))
})

test_that("filter_na_across errors when a required column is absent", {
  d <- anicore::aniframe(
    time = 1:4,
    x = c(1, 2, 3, 4),
    y = c(5, 6, 7, 8),
    variables_what = character(0)
  )
  expect_error(
    filter_na_across(d, "confidence", threshold = 0.6),
    "Missing required column"
  )
})

test_that("filter_na_across respects grouping", {
  d <- na_fixture()
  grouped <- filter_na_across(d, "speed", threshold = 100)

  rows <- split(seq_len(nrow(d)), d$individual)
  alone <- unlist(
    lapply(rows, function(i) {
      filter_na_speed(
        data.frame(x = d$x[i], y = d$y[i]),
        threshold = 100,
        time = d$time[i]
      )$x
    }),
    use.names = FALSE
  )
  expect_equal(grouped$x, alone)
})

test_that("filter_na_across returns an aniframe and preserves grouping", {
  d <- na_fixture()
  out <- filter_na_across(d, "speed", threshold = 100)

  expect_s3_class(out, "aniframe")
  expect_equal(dplyr::group_vars(out), "individual")
})

test_that("auto estimates a threshold per group, pooled estimates one overall", {
  # Ten rows per track is too few for mean + 3 sd to catch this outlier
  # within its own track, but enough when both tracks are pooled. The two
  # settings therefore disagree, which is what makes them distinguishable.
  d <- anicore::aniframe(
    time = rep(1:10, 2),
    individual = rep(c("a", "b"), each = 10),
    x = c(c(0:3, 500, 5:9), (0:9) + 1e4),
    y = rep(0, 20),
    variables_what = "individual"
  ) |>
    dplyr::group_by(individual)

  expect_length(which(is.na(filter_na_across(d, "speed")$x)), 0)
  expect_equal(
    which(is.na(filter_na_across(d, "speed", threshold = "pooled")$x)),
    5L
  )

  # An explicit threshold is passed through untouched
  expect_equal(
    which(is.na(filter_na_across(d, "speed", threshold = 100)$x)),
    5L
  )
})

test_that("a per-group auto threshold judges each track on its own noise", {
  # Track a is noisy, track b is smooth; each has one outlier of the same
  # size. A pooled threshold is dominated by a's noise and misses b's.
  set.seed(17)
  np <- 40
  xa <- cumsum(rnorm(np, sd = 20))
  xa[10] <- xa[10] + 3000
  xb <- cumsum(rnorm(np, sd = 0.1)) + 1e5
  xb[10] <- xb[10] + 3000

  d <- anicore::aniframe(
    time = rep(seq_len(np), 2),
    individual = rep(c("a", "b"), each = np),
    x = c(xa, xb),
    y = rep(0, 2 * np),
    variables_what = "individual"
  ) |>
    dplyr::group_by(individual)

  per_group <- which(is.na(filter_na_across(d, "speed")$x))
  expect_true(10L %in% per_group)
  expect_true((np + 10L) %in% per_group)
})


# on_deltas ------------------------------------------------------------

# Trackball-style data: the raw readings are per-window displacements and
# the coordinates are their running sum, so one spurious step offsets every
# position after it.
delta_fixture <- function(individuals = "a") {
  steps <- c(0, 1, 1, 1, 50, 1, 1, 1)
  np <- length(steps)
  ni <- length(individuals)
  # each track starts somewhere different
  offset <- rep(100 * seq_len(ni), each = np)

  anicore::aniframe(
    time = rep(seq_len(np), ni),
    individual = rep(individuals, each = np),
    x = offset + rep(cumsum(steps), ni),
    y = offset + rep(cumsum(rev(steps)), ni),
    variables_what = "individual"
  ) |>
    dplyr::group_by(individual)
}

test_that("on_deltas removes a spurious jump from every later position", {
  d <- delta_fixture()
  out <- filter_na_across(
    d,
    "range",
    min_value = -10,
    max_value = 10,
    on_deltas = TRUE
  )

  # The bad step is gone, so positions after it sit where they would have
  # without it: the earlier run of +1 steps simply continues.
  expect_equal(out$x, c(100, 101, 102, 103, NA, 104, 105, 106))

  # Masking the position instead leaves the jump baked in downstream.
  positions <- filter_na_across(d, "range", min_value = -10, max_value = 110)
  expect_equal(positions$x, c(100, 101, 102, 103, NA, NA, NA, NA))
})

test_that("on_deltas blanks only the sample whose step was masked", {
  d <- delta_fixture()
  out <- filter_na_across(
    d,
    "range",
    min_value = -10,
    max_value = 10,
    on_deltas = TRUE
  )

  expect_equal(which(is.na(out$x)), 5L)
  # y carries the same steps reversed, so its bad step lands elsewhere
  expect_equal(which(is.na(out$y)), 4L)
})

test_that("on_deltas never masks the first sample", {
  d <- delta_fixture()
  # Inverted range: every real step of 1 is rejected, only the jump of 50
  # survives. The first sample has no step into it, so it is the starting
  # point rather than something to reject.
  out <- filter_na_across(
    d,
    "range",
    min_value = 2,
    max_value = 60,
    on_deltas = TRUE
  )

  expect_equal(out$x[1], d$x[1])
  expect_equal(which(is.na(out$x)), c(2L, 3L, 4L, 6L, 7L, 8L))
})

test_that("on_deltas respects grouping", {
  d <- delta_fixture(c("a", "b"))
  out <- filter_na_across(
    d,
    "range",
    min_value = -10,
    max_value = 10,
    on_deltas = TRUE
  )

  # No step is formed across the boundary, and each track re-integrates
  # from its own starting value.
  expect_equal(which(is.na(out$x)), c(5L, 13L))
  expect_equal(out$x[1], d$x[1])
  expect_equal(out$x[9], d$x[9])
})

test_that("on_deltas = FALSE leaves the position-level behaviour alone", {
  d <- na_fixture()

  expect_equal(
    filter_na_across(d, "range", min_value = 0, max_value = 100),
    filter_na_across(
      d,
      "range",
      min_value = 0,
      max_value = 100,
      on_deltas = FALSE
    )
  )
})

test_that("on_deltas is refused by the criteria it does not suit", {
  d <- na_fixture()

  expect_error(
    filter_na_across(d, "speed", threshold = 100, on_deltas = TRUE),
    "second-order"
  )
  expect_error(
    filter_na_across(d, "excursion", on_deltas = TRUE),
    "second-order"
  )
  expect_error(
    filter_na_across(d, "roi", on_deltas = TRUE),
    "not a region of displacement"
  )
  expect_error(
    filter_na_across(d, "confidence", on_deltas = TRUE),
    "not spatial"
  )
})
