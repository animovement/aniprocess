# Tests for filter_na_across()
# - "range" is applied column by column; the rest jointly
# - time and confidence come from the aniframe
# - confidence is blanked on rows this call masked
# - Grouping is respected

na_fixture <- function(np = 20) {
  aniframe::aniframe(
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
  d <- aniframe::aniframe(
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
  d2 <- aniframe::aniframe(
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
  d <- aniframe::aniframe(
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
  d <- aniframe::aniframe(
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
