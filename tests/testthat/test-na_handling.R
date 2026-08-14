# Tests for the shared NA-handling machinery used across the filter family.
#
# - ensure_keep_na() rejects anything that is not a single TRUE/FALSE
# - prepare_na() records positions and fills, for vectors and matrices
# - restore_na() puts gaps back, and is a no-op when keep_na is FALSE
# - the whole filter family honours the same keep_na contract

test_that("ensure_keep_na accepts single logicals", {
  expect_null(ensure_keep_na(TRUE))
  expect_null(ensure_keep_na(FALSE))
})

test_that("ensure_keep_na rejects non-logical, NA and non-scalar input", {
  for (bad in list("yes", 1, NA, c(TRUE, FALSE), logical(0), NULL)) {
    expect_error(ensure_keep_na(bad), "must be a single")
  }
})

test_that("prepare_na records positions and fills a vector", {
  x <- c(1, 2, NA, 4, 5)
  out <- prepare_na(x, "linear")
  expect_equal(out$na_positions, c(FALSE, FALSE, TRUE, FALSE, FALSE))
  expect_false(anyNA(out$x))
  expect_equal(out$x[3], 3)
})

test_that("prepare_na leaves a complete vector untouched", {
  x <- c(1, 2, 3)
  out <- prepare_na(x, "linear")
  expect_equal(out$x, x)
  expect_false(any(out$na_positions))
})

test_that("prepare_na aborts on na_action = 'error' only when NAs present", {
  expect_error(prepare_na(c(1, NA, 3), "error"), "Input contains")
  expect_no_error(prepare_na(c(1, 2, 3), "error"))
})

test_that("prepare_na fills a matrix column-wise", {
  m <- cbind(a = c(1, NA, 3), b = c(NA, 2, 3))
  out <- prepare_na(m, "linear")
  expect_true(is.matrix(out$na_positions))
  expect_equal(dim(out$na_positions), dim(m))
  expect_equal(which(out$na_positions), c(2L, 4L))
  # Filled down each column independently, not across them
  expect_false(anyNA(out$x))
  expect_equal(unname(out$x[, "a"]), c(1, 2, 3))
  expect_equal(unname(out$x[, "b"]), c(2, 2, 3))
  # Structure is preserved -- no dimnames invented or dropped
  expect_equal(dimnames(out$x), dimnames(m))
})

test_that("prepare_na passes extra arguments through to replace_na", {
  x <- c(1, NA, 3)
  out <- prepare_na(x, "value", list(value = -99))
  expect_equal(out$x[2], -99)
})

test_that("restore_na writes NAs back only when keep_na is TRUE", {
  result <- c(1, 2, 3, 4)
  pos <- c(FALSE, TRUE, FALSE, TRUE)
  expect_equal(restore_na(result, pos, TRUE), c(1, NA, 3, NA))
  expect_equal(restore_na(result, pos, FALSE), result)
})

test_that("restore_na handles matrices elementwise", {
  m <- matrix(1:6, nrow = 3)
  pos <- matrix(c(FALSE, TRUE, FALSE, FALSE, FALSE, TRUE), nrow = 3)
  out <- restore_na(m, pos, TRUE)
  expect_equal(which(is.na(out)), c(2L, 6L))
})

test_that("restore_na is a no-op when there is nothing to restore", {
  result <- c(1, 2, 3)
  expect_equal(restore_na(result, rep(FALSE, 3), TRUE), result)
})

# --- family-level contract (issue #38) --------------------------------------

test_that("every smoothing filter preserves input NAs by default", {
  set.seed(42)
  n <- 120
  x <- sin(2 * pi * seq(0, 2, length.out = n)) + rnorm(n, 0, 0.05)
  gaps <- c(40:49, 80)
  x[gaps] <- NA

  preserved <- function(result) all(is.na(result[gaps]))

  expect_true(preserved(filter_sgolay(x, sampling_rate = 60)))
  expect_true(preserved(filter_lowpass(x, sampling_rate = 60, cutoff_freq = 5)))
  expect_true(preserved(filter_highpass(
    x,
    sampling_rate = 60,
    cutoff_freq = 5
  )))
  expect_true(preserved(
    filter_lowpass_fft(x, sampling_rate = 60, cutoff_freq = 5)
  ))
  expect_true(preserved(
    filter_highpass_fft(x, sampling_rate = 60, cutoff_freq = 5)
  ))
  expect_true(preserved(filter_gaussian(x, sigma = 2)))
  expect_true(preserved(filter_rollmean(x, window_width = 5)))
  expect_true(preserved(filter_rollmedian(x, window_width = 5)))
  expect_true(preserved(filter_triangular(x, window_width = 5)))
})

test_that("filter_kalman fills by default but honours keep_na = TRUE", {
  set.seed(42)
  n <- 60
  x <- sin(2 * pi * seq(0, 2, length.out = n))
  gaps <- 20:25
  x[gaps] <- NA

  # Gap-filling is the intended behaviour for a state estimator
  expect_false(any(is.na(filter_kalman(x, sampling_rate = 60))))
  expect_true(all(is.na(
    filter_kalman(x, sampling_rate = 60, keep_na = TRUE)[gaps]
  )))
})

test_that("every filter rejects an invalid keep_na", {
  # Long enough that sgolay's derived window_width stays valid, so the
  # keep_na check is what aborts rather than a geometry check.
  x <- as.numeric(seq_len(60))
  x[10] <- NA

  expect_error(filter_rollmean(x, keep_na = "yes"), "must be a single")
  expect_error(filter_rollmedian(x, keep_na = "yes"), "must be a single")
  expect_error(filter_triangular(x, keep_na = "yes"), "must be a single")
  expect_error(filter_gaussian(x, keep_na = "yes"), "must be a single")
  expect_error(
    filter_sgolay(x, sampling_rate = 60, keep_na = "yes"),
    "must be a single"
  )
  expect_error(
    filter_kalman(x, sampling_rate = 60, keep_na = "yes"),
    "must be a single"
  )
  expect_error(
    filter_lowpass(x, sampling_rate = 60, cutoff_freq = 5, keep_na = "yes"),
    "must be a single"
  )
  expect_error(
    filter_lowpass_fft(x, sampling_rate = 60, cutoff_freq = 5, keep_na = "yes"),
    "must be a single"
  )
})

# --- ensure_coords ----------------------------------------------------------

test_that("ensure_coords accepts a numeric data frame", {
  expect_null(ensure_coords(data.frame(x = 1:3, y = 4:6)))
})

test_that("ensure_coords rejects non-data-frame input", {
  expect_error(ensure_coords(1:5), "aniframe or a data frame")
  expect_error(ensure_coords("a"), "aniframe or a data frame")
  expect_error(ensure_coords(NULL), "aniframe or a data frame")
})

test_that("ensure_coords rejects a frame with no columns", {
  expect_error(ensure_coords(data.frame()), "has no columns")
  # and through a public entry point
  expect_error(filter_na_excursion(data.frame()), "has no columns")
})

test_that("ensure_coords names the non-numeric columns", {
  expect_error(
    ensure_coords(data.frame(x = 1:3, y = letters[1:3])),
    "must be numeric"
  )
  expect_error(
    ensure_coords(data.frame(x = letters[1:3], y = letters[1:3])),
    "must be numeric"
  )
})

test_that("ensure_coords uses the supplied argument name", {
  expect_error(ensure_coords(1:5, arg = "coords"), "`coords` must be")
})
