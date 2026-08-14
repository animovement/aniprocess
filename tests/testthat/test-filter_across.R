# Tests for filter_across()
# - Parity with filter_aniframe() for the methods both support
# - sampling_rate and the time column come from metadata
# - `variables` restricts which columns are touched
# - ccma is applied jointly, not column by column
# - Grouping is respected
# - use_derivatives round trip

grouped_fixture <- function(np = 30, sampling_rate = 30) {
  d <- aniframe::aniframe(
    time = rep(seq_len(np), 2),
    individual = rep(c("a", "b"), each = np),
    x = c(seq_len(np), seq_len(np) + 1000),
    y = c(rev(seq_len(np)), rev(seq_len(np)) + 500),
    variables_what = "individual"
  ) |>
    dplyr::group_by(individual)
  aniframe::set_metadata(d, sampling_rate = sampling_rate)
}

test_that("filter_across matches filter_aniframe for the shared methods", {
  d <- grouped_fixture()

  for (m in c("gaussian", "rollmean", "rollmedian", "triangular")) {
    expect_equal(filter_across(d, m)$x, filter_aniframe(d, m)$x, info = m)
    expect_equal(filter_across(d, m)$y, filter_aniframe(d, m)$y, info = m)
  }
})

test_that("filter_across takes sampling_rate from metadata", {
  d <- grouped_fixture(sampling_rate = 30)

  expect_equal(
    filter_across(d, "lowpass", cutoff_freq = 5)$x,
    filter_across(d, "lowpass", cutoff_freq = 5, sampling_rate = 30)$x
  )
  expect_equal(
    filter_across(d, "sgolay", window_width = 5)$x,
    filter_across(d, "sgolay", window_width = 5, sampling_rate = 30)$x
  )
})

test_that("filter_across errors when sampling_rate is unavailable", {
  d <- aniframe::aniframe(
    time = 1:20,
    x = as.numeric(1:20),
    y = as.numeric(1:20),
    variables_what = character(0)
  )
  d <- aniframe::set_metadata(d, sampling_rate = NA)

  expect_error(
    filter_across(d, "lowpass", cutoff_freq = 5),
    "Cannot determine the sampling rate"
  )
})

test_that("filter_across takes the time column from variables_when", {
  d <- aniframe::aniframe(
    time = c(0, 0.1, 0.3, 0.35, 0.5, 0.8),
    x = c(1, 1.1, 2, 0.9, 1.2, 0.8),
    y = c(1, 1.1, 2, 0.9, 1.2, 0.8),
    variables_what = character(0)
  )

  expect_equal(
    filter_across(d, "kalman_irregular")$x,
    filter_kalman_irregular(d$x, times = d$time)
  )
})

test_that("filter_across restricts to the selected variables", {
  d <- grouped_fixture()

  out <- filter_across(d, "gaussian", variables = x, sigma = 2)
  expect_false(identical(out$x, d$x))
  expect_identical(out$y, d$y)

  out_both <- filter_across(d, "gaussian", variables = c(x, y), sigma = 2)
  expect_false(identical(out_both$y, d$y))
})

test_that("filter_across rejects a selection with no columns or non-numeric ones", {
  d <- grouped_fixture()

  expect_error(
    filter_across(d, "gaussian", variables = dplyr::starts_with("zzz")),
    "selected no columns"
  )
  expect_error(
    filter_across(d, "gaussian", variables = individual),
    "not numeric"
  )
})

test_that("filter_across applies ccma jointly", {
  np <- 60
  t <- seq(0, 2 * pi, length.out = np)
  d <- aniframe::aniframe(
    time = seq_len(np),
    x = cos(t),
    y = sin(t),
    variables_what = character(0)
  )

  expect_equal(
    as.data.frame(filter_across(d, "ccma"))[, c("x", "y")],
    as.data.frame(dplyr::mutate(
      d,
      filter_ccma(dplyr::pick(dplyr::all_of(c("x", "y"))))
    ))[, c("x", "y")]
  )
})

test_that("filter_across respects grouping", {
  d <- grouped_fixture(np = 20)

  grouped <- filter_across(d, "rollmean", window_width = 5)
  # Each track filtered on its own, without ungrouping the aniframe
  rows <- split(seq_len(nrow(d)), d$individual)
  alone <- unlist(
    lapply(rows, function(i) {
      filter_rollmean(d$x[i], window_width = 5)
    }),
    use.names = FALSE
  )

  expect_equal(grouped$x, alone)
})

test_that("filter_across returns an aniframe and preserves grouping", {
  d <- grouped_fixture()
  out <- filter_across(d, "gaussian")

  expect_s3_class(out, "aniframe")
  expect_true(inherits(out, "grouped_df"))
  expect_equal(dplyr::group_vars(out), "individual")
})

test_that("filter_across on_deltas matches filter_aniframe use_derivatives", {
  d <- grouped_fixture(np = 20)

  expect_equal(
    filter_across(d, "rollmean", window_width = 3, on_deltas = TRUE)$x,
    filter_aniframe(d, "rollmean", window_width = 3, use_derivatives = TRUE)$x
  )
})

test_that("on_deltas round trips when the filter does nothing", {
  # window_width = 1 makes rollmean the identity, so differencing and
  # re-integrating must return the input unchanged.
  d <- aniframe::aniframe(
    time = 1:5,
    x = c(10, 11, 13, 16, 20),
    y = c(-3, -3, -1, 2, 6),
    variables_what = character(0)
  )
  out <- filter_across(d, "rollmean", window_width = 1, on_deltas = TRUE)

  expect_equal(out$x, d$x)
  expect_equal(out$y, d$y)
})

test_that("on_deltas keeps the original starting value", {
  d <- aniframe::aniframe(
    time = 1:20,
    x = 100 + cumsum(c(0, rnorm(19))),
    y = rep(0, 20),
    variables_what = character(0)
  )
  out <- filter_across(d, "rollmean", window_width = 3, on_deltas = TRUE)

  expect_equal(out$x[1], d$x[1])
  expect_false(is.na(out$x[1]))
})

test_that("on_deltas restores NA at a missing step without blanking the rest", {
  d <- aniframe::aniframe(
    time = 1:6,
    x = c(10, 11, NA, 16, 20, 25),
    y = rep(0, 6),
    variables_what = character(0)
  )
  out <- filter_across(d, "rollmean", window_width = 1, on_deltas = TRUE)

  # The steps into and out of the gap are unknown, so those positions are NA
  expect_true(any(is.na(out$x)))
  # but the series continues afterwards
  expect_false(is.na(out$x[6]))
})

test_that("on_deltas respects grouping", {
  d <- grouped_fixture(np = 10)
  out <- filter_across(d, "rollmean", window_width = 1, on_deltas = TRUE)

  # Each track re-integrates from its own starting value
  expect_equal(out$x[1], d$x[1])
  expect_equal(out$x[11], d$x[11])
})

test_that("filter_across errors on a missing selected column", {
  d <- aniframe::aniframe(
    time = 1:5,
    x = as.numeric(1:5),
    y = as.numeric(1:5),
    variables_what = character(0)
  )
  d <- aniframe::set_metadata(d, variables_where = c("x", "y", "z"))

  expect_error(filter_across(d, "gaussian"), "Missing spatial column")
})

test_that("filter_across dispatches every method", {
  np <- 40
  d <- aniframe::aniframe(
    time = seq_len(np),
    x = sin(2 * pi * 2 * seq(0, 1, length.out = np)),
    y = cos(2 * pi * 2 * seq(0, 1, length.out = np)),
    variables_what = character(0)
  )
  d <- aniframe::set_metadata(d, sampling_rate = 40)

  simple <- c("gaussian", "rollmean", "rollmedian", "triangular", "kalman")
  freq <- c("lowpass", "highpass", "lowpass_fft", "highpass_fft")

  for (m in simple) {
    expect_s3_class(filter_across(d, m), "aniframe")
  }
  for (m in freq) {
    expect_s3_class(filter_across(d, m, cutoff_freq = 5), "aniframe")
  }
  expect_s3_class(filter_across(d, "sgolay", window_width = 5), "aniframe")
  expect_s3_class(filter_across(d, "kalman_irregular"), "aniframe")
  expect_s3_class(filter_across(d, "ccma"), "aniframe")
})

test_that("filter_across errors when variables_when names a missing column", {
  d <- aniframe::aniframe(
    time = 1:6,
    x = as.numeric(1:6),
    y = as.numeric(1:6),
    variables_what = character(0)
  )
  d <- aniframe::set_metadata(d, variables_when = "frame")

  expect_error(filter_across(d, "kalman_irregular"), "Missing time column")
})
