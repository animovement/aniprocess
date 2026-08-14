# Tests for filter_lowpass_fft and filter_highpass_fft
# - Passband preservation: a sinusoid below the cutoff is preserved at
#   close to its full amplitude (regression test for the Hermitian-mask
#   bug that previously halved passband amplitude).
# - Stopband attenuation: a sinusoid above the cutoff is killed.
# - Complementary pair: lowpass + highpass at the same cutoff
#   reconstructs the original signal.
# - NA handling via na_action and keep_na (mirroring the Butterworth tests).
# - Input validation.

helper_signal <- function(freqs, fs = 1000, dur = 1) {
  t <- seq(0, dur, by = 1 / fs)
  rowSums(sapply(freqs, function(f) sin(2 * pi * f * t)))
}

test_that("filter_lowpass_fft preserves passband amplitude (regression)", {
  fs <- 1000
  x <- helper_signal(2, fs = fs) # 2 Hz only
  out <- filter_lowpass_fft(x, cutoff_freq = 5, sampling_rate = fs)
  # Before the Hermitian-mask fix, output RMS was half of input.
  expect_equal(sqrt(mean(out^2)), sqrt(mean(x^2)), tolerance = 0.02)
})

test_that("filter_lowpass_fft attenuates stopband", {
  fs <- 1000
  x <- helper_signal(50, fs = fs)
  out <- filter_lowpass_fft(x, cutoff_freq = 5, sampling_rate = fs)
  expect_lt(sqrt(mean(out^2)), 0.05 * sqrt(mean(x^2)))
})

test_that("filter_highpass_fft preserves passband amplitude (regression)", {
  fs <- 1000
  x <- helper_signal(50, fs = fs) # 50 Hz only
  out <- filter_highpass_fft(x, cutoff_freq = 20, sampling_rate = fs)
  expect_equal(sqrt(mean(out^2)), sqrt(mean(x^2)), tolerance = 0.02)
})

test_that("filter_highpass_fft attenuates stopband", {
  fs <- 1000
  x <- helper_signal(2, fs = fs)
  out <- filter_highpass_fft(x, cutoff_freq = 20, sampling_rate = fs)
  expect_lt(sqrt(mean(out^2)), 0.05 * sqrt(mean(x^2)))
})

test_that("lowpass + highpass at the same cutoff reconstructs the input", {
  # Strongest correctness check: the two filters together are an
  # identity. Possible only if their masks are complementary AND
  # Hermitian-symmetric.
  fs <- 1000
  x <- helper_signal(c(2, 50), fs = fs) + 0.3 * rnorm(1001)
  low <- filter_lowpass_fft(x, cutoff_freq = 10, sampling_rate = fs)
  high <- filter_highpass_fft(x, cutoff_freq = 10, sampling_rate = fs)
  expect_equal(low + high, x, tolerance = 1e-9)
})

test_that("filter_*_fft reject non-numeric input", {
  expect_error(filter_lowpass_fft("a", 5, 1000), "must be numeric")
  expect_error(filter_highpass_fft("a", 5, 1000), "must be numeric")
})

test_that("filter_*_fft reject out-of-range cutoff", {
  x <- rnorm(100)
  expect_error(filter_lowpass_fft(x, 0, 1000), "between 0 and")
  expect_error(filter_lowpass_fft(x, 600, 1000), "between 0 and")
  expect_error(filter_highpass_fft(x, -1, 1000), "between 0 and")
  expect_error(filter_highpass_fft(x, 600, 1000), "between 0 and")
})

test_that("filter_*_fft handle NA values via na_action", {
  fs <- 1000
  x <- helper_signal(2, fs = fs)
  x_with_na <- x
  x_with_na[c(50, 200, 500:505)] <- NA

  for (method in c("linear", "spline", "locf")) {
    out_low <- filter_lowpass_fft(
      x_with_na,
      cutoff_freq = 5,
      sampling_rate = fs,
      na_action = method,
      keep_na = FALSE
    )
    expect_false(any(is.na(out_low)))

    out_high <- filter_highpass_fft(
      x_with_na,
      cutoff_freq = 20,
      sampling_rate = fs,
      na_action = method,
      keep_na = FALSE
    )
    expect_false(any(is.na(out_high)))
  }

  # Value method needs an explicit value
  expect_no_error(
    filter_lowpass_fft(
      x_with_na,
      cutoff_freq = 5,
      sampling_rate = fs,
      na_action = "value",
      value = 0
    )
  )

  expect_error(
    filter_lowpass_fft(
      x_with_na,
      cutoff_freq = 5,
      sampling_rate = fs,
      na_action = "error"
    ),
    "Input contains .*NA.* values"
  )
  expect_error(
    filter_highpass_fft(
      x_with_na,
      cutoff_freq = 20,
      sampling_rate = fs,
      na_action = "error"
    ),
    "Input contains .*NA.* values"
  )
})

test_that("filter_*_fft keep_na restores NAs at original positions", {
  fs <- 1000
  x <- helper_signal(c(2, 50), fs = fs)
  na_pos <- c(20, 100, 500)
  x[na_pos] <- NA

  out_low <- filter_lowpass_fft(
    x,
    cutoff_freq = 5,
    sampling_rate = fs,
    keep_na = TRUE
  )
  expect_true(all(is.na(out_low[na_pos])))

  out_high <- filter_highpass_fft(
    x,
    cutoff_freq = 20,
    sampling_rate = fs,
    keep_na = TRUE
  )
  expect_true(all(is.na(out_high[na_pos])))
})
