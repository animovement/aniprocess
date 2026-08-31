# Tests for reflection padding and the filters that use it (#79)
# --------------------------------------------------------------
# The pad can only be as long as the signal it mirrors, so the width asked for
# is not always the width applied -- and the trim has to use the width applied.

test_that("pad_reflect() mirrors both ends and records the width applied", {
  padded <- pad_reflect(c(1, 2, 3, 4), 2)

  expect_identical(as.numeric(padded), c(2, 1, 1, 2, 3, 4, 4, 3))
  expect_identical(attr(padded, "pad"), 2L)
})

test_that("pad_reflect() clamps the pad to the signal it mirrors", {
  padded <- pad_reflect(c(1, 2, 3), 10)

  expect_identical(attr(padded, "pad"), 3L)
  expect_identical(as.numeric(padded), c(3, 2, 1, 1, 2, 3, 3, 2, 1))
})

test_that("pad_reflect() pads nothing onto an empty signal", {
  # 1:0 counts backwards, so the old code padded an empty vector with two NAs
  padded <- pad_reflect(numeric(0), 10)

  expect_length(padded, 0L)
  expect_identical(attr(padded, "pad"), 0L)
})

test_that("trim_reflect() undoes pad_reflect()", {
  for (n_pad in c(0L, 1L, 2L, 50L)) {
    x <- c(4, 8, 15, 16, 23, 42)
    padded <- pad_reflect(x, n_pad)

    expect_identical(
      trim_reflect(padded, attr(padded, "pad"), length(x)),
      x
    )
  }
})

test_that("the bandwidth filters return one value per input value", {
  set.seed(1)

  for (n in c(1, 3, 5, 13, 20, 39, 40, 60)) {
    x <- sin(seq_len(n) / 3)

    for (f in list(filter_lowpass, filter_highpass)) {
      out <- suppressWarnings(f(x, cutoff_freq = 2, sampling_rate = 30))
      expect_length(out, n)
      expect_false(anyNA(out))
    }

    for (f in list(filter_lowpass_fft, filter_highpass_fft)) {
      out <- suppressWarnings(f(x, cutoff_freq = 2, sampling_rate = 30))
      expect_length(out, n)
    }
  }
})

test_that("a signal shorter than the pad is filtered, not reversed", {
  # The pad width asked for here is 40 while the signal is 20 long, so the trim
  # used to start past the signal and return the reversed end pad instead --
  # correlating -0.73 with the answer, with no NA and no warning to show for it.
  x <- sin(seq_len(20) / 3)

  out <- suppressWarnings(
    filter_lowpass(x, cutoff_freq = 2, sampling_rate = 30)
  )

  padded <- c(rev(x), x, rev(x))
  expected <- signal::filtfilt(signal::butter(4, 2 / 15, type = "low"), padded)
  expect_equal(out, expected[21:40], tolerance = 1e-12)
})

test_that("the bandwidth filters have nothing to do with nothing", {
  for (f in list(
    filter_lowpass,
    filter_highpass,
    filter_lowpass_fft,
    filter_highpass_fft
  )) {
    expect_length(f(numeric(0), cutoff_freq = 2, sampling_rate = 30), 0L)
  }
})
