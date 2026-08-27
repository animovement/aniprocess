# Tests for filter_one_euro
# - Matches an independent transcription of the authors' reference code
# - The defining property: beta trades lag against jitter
# - Steady state, first sample, length
# - beta = 0 is a plain exponential low-pass
# - Parameter validation
# - NA handling via na_action / keep_na
# - Reachable through filter_with() and filter_across()

# An independent transcription of the reference implementation from
# https://gery.casiez.net/1euro/ -- deliberately written in the paper's
# terms (per-sample timestamps, explicit state) rather than reusing any of
# the package's own code, so it is a real cross-check.
reference_one_euro <- function(x, t, min_cutoff = 1, beta = 0, d_cutoff = 1) {
  smoothing_factor <- function(t_e, cutoff) {
    r <- 2 * pi * cutoff * t_e
    r / (r + 1)
  }
  exponential_smoothing <- function(a, x, x_prev) a * x + (1 - a) * x_prev

  x_prev <- x[1]
  dx_prev <- 0
  t_prev <- t[1]
  out <- numeric(length(x))
  out[1] <- x[1]

  for (i in seq_along(x)[-1]) {
    t_e <- t[i] - t_prev
    a_d <- smoothing_factor(t_e, d_cutoff)
    dx <- (x[i] - x_prev) / t_e
    dx_hat <- exponential_smoothing(a_d, dx, dx_prev)

    cutoff <- min_cutoff + beta * abs(dx_hat)
    a <- smoothing_factor(t_e, cutoff)
    x_hat <- exponential_smoothing(a, x[i], x_prev)

    x_prev <- x_hat
    dx_prev <- dx_hat
    t_prev <- t[i]
    out[i] <- x_hat
  }
  out
}

step_signal <- function(fs = 60, seed = 4) {
  set.seed(seed)
  t <- seq(0, 3, by = 1 / fs)
  list(t = t, x = ifelse(t < 1.5, 0, 10) + rnorm(length(t), 0, 0.05))
}

test_that("filter_one_euro matches the reference implementation", {
  sig <- step_signal()

  for (b in c(0, 0.5, 5)) {
    expect_equal(
      filter_one_euro(sig$x, sampling_rate = 60, min_cutoff = 0.5, beta = b),
      reference_one_euro(sig$x, sig$t, min_cutoff = 0.5, beta = b),
      tolerance = 1e-12,
      info = paste("beta =", b)
    )
  }
})

test_that("filter_one_euro matches the reference across parameter settings", {
  sig <- step_signal(seed = 11)

  for (mc in c(0.1, 1, 5)) {
    for (dc in c(0.5, 1, 2)) {
      expect_equal(
        filter_one_euro(
          sig$x,
          sampling_rate = 60,
          min_cutoff = mc,
          beta = 1,
          d_cutoff = dc
        ),
        reference_one_euro(
          sig$x,
          sig$t,
          min_cutoff = mc,
          beta = 1,
          d_cutoff = dc
        ),
        tolerance = 1e-12,
        info = paste("min_cutoff", mc, "d_cutoff", dc)
      )
    }
  }
})

test_that("beta trades lag against jitter", {
  # The point of the filter: raising beta should cut lag sharply while
  # costing only a little jitter when the signal is still.
  sig <- step_signal()
  still <- which(sig$t < 1.4)
  after <- which(sig$t > 1.5)[1:30]

  measure <- function(b) {
    y <- filter_one_euro(sig$x, sampling_rate = 60, min_cutoff = 0.5, beta = b)
    list(jitter = stats::sd(diff(y[still])), lag = mean(abs(y[after] - 10)))
  }
  slow <- measure(0)
  fast <- measure(0.5)

  # Lag falls by orders of magnitude
  expect_lt(fast$lag, slow$lag / 10)
  # while jitter rises only slightly
  expect_lt(fast$jitter, slow$jitter * 3)
})

test_that("min_cutoff controls smoothing when the signal is still", {
  set.seed(7)
  x <- rnorm(200, 0, 1)

  smooth <- filter_one_euro(x, sampling_rate = 60, min_cutoff = 0.1)
  rough <- filter_one_euro(x, sampling_rate = 60, min_cutoff = 10)

  expect_lt(stats::sd(diff(smooth)), stats::sd(diff(rough)))
})

test_that("filter_one_euro leaves a constant signal unchanged", {
  x <- rep(5, 50)
  expect_equal(filter_one_euro(x, sampling_rate = 60), x)
})

test_that("filter_one_euro preserves the first sample and the length", {
  set.seed(3)
  x <- rnorm(40)
  out <- filter_one_euro(x, sampling_rate = 60)

  expect_equal(out[1], x[1])
  expect_length(out, length(x))
})

test_that("filter_one_euro handles inputs too short to filter", {
  expect_equal(filter_one_euro(numeric(0), sampling_rate = 60), numeric(0))
  expect_equal(filter_one_euro(3, sampling_rate = 60), 3)
})

test_that("beta = 0 is a plain exponential low-pass", {
  # With beta = 0 the cutoff never moves, so the recursion collapses to a
  # first-order exponential filter with a constant smoothing factor.
  set.seed(5)
  x <- rnorm(50)
  fs <- 60
  cutoff <- 2
  a <- (2 * pi * cutoff / fs) / (2 * pi * cutoff / fs + 1)

  expected <- numeric(length(x))
  expected[1] <- x[1]
  for (i in 2:length(x)) {
    expected[i] <- a * x[i] + (1 - a) * expected[i - 1]
  }

  expect_equal(
    filter_one_euro(x, sampling_rate = fs, min_cutoff = cutoff, beta = 0),
    expected
  )
})

test_that("filter_one_euro validates its parameters", {
  x <- rnorm(20)

  expect_error(filter_one_euro("a", sampling_rate = 60), "must be numeric")
  for (bad in list(0, -1, NA, c(1, 2), Inf, "a")) {
    expect_error(filter_one_euro(x, sampling_rate = bad), "positive number")
  }
  expect_error(
    filter_one_euro(x, sampling_rate = 60, min_cutoff = 0),
    "positive number"
  )
  expect_error(
    filter_one_euro(x, sampling_rate = 60, d_cutoff = -1),
    "positive number"
  )
  expect_error(
    filter_one_euro(x, sampling_rate = 60, beta = -1),
    "non-negative"
  )
  expect_error(
    filter_one_euro(x, sampling_rate = 60, keep_na = "yes"),
    "must be a single"
  )
})

test_that("filter_one_euro preserves gaps by default", {
  x <- c(1, 2, 3, NA, 5, 6, 7, 8)
  out <- filter_one_euro(x, sampling_rate = 60)

  expect_equal(which(is.na(out)), 4L)
  # The filled value is available on request
  expect_false(any(is.na(filter_one_euro(
    x,
    sampling_rate = 60,
    keep_na = FALSE
  ))))
})

test_that("filter_one_euro honours na_action", {
  x <- c(1, 2, 3, NA, 5, 6, 7, 8)

  expect_error(
    filter_one_euro(x, sampling_rate = 60, na_action = "error"),
    "Input contains"
  )
  expect_equal(
    filter_one_euro(x, sampling_rate = 60, na_action = "value", value = 0),
    filter_one_euro(
      replace_na_with(x, "value", value = 0),
      sampling_rate = 60,
      keep_na = FALSE
    ) |>
      (\(y) {
        y[4] <- NA
        y
      })()
  )
})

test_that("filter_one_euro is reachable through the generics", {
  set.seed(9)
  x <- rnorm(60)

  expect_equal(
    filter_with(x, "one_euro", sampling_rate = 60, beta = 0.5),
    filter_one_euro(x, sampling_rate = 60, beta = 0.5)
  )

  d <- anicore::aniframe(
    time = seq_len(60),
    x = x,
    y = rev(x),
    variables_what = character(0)
  )
  d <- anicore::set_metadata(d, sampling_rate = 60)

  # sampling_rate comes from the aniframe's metadata
  expect_equal(
    filter_across(d, "one_euro", beta = 0.5)$x,
    filter_one_euro(x, sampling_rate = 60, beta = 0.5)
  )
})
