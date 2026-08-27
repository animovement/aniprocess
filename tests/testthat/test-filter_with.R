# Tests for filter_with()
# - Every method dispatches to the same result as calling the filter directly
# - Shape is preserved: vector -> vector, frame -> frame (column-wise)
# - The multivariate method (ccma) requires a frame
# - An aniframe is rejected with a message pointing at the right tool
# - Unknown methods are rejected

test_that("filter_with dispatches univariate methods to the same result", {
  x <- c(1, 2, 3, 100, 5, 6, 7, 8, 9, 10, 11, 12)

  expect_equal(
    filter_with(x, "gaussian", sigma = 1),
    filter_gaussian(x, sigma = 1)
  )
  expect_equal(
    filter_with(x, "rollmean", window_width = 3),
    filter_rollmean(x, window_width = 3)
  )
  expect_equal(
    filter_with(x, "rollmedian", window_width = 3),
    filter_rollmedian(x, window_width = 3)
  )
  expect_equal(
    filter_with(x, "triangular", window_width = 3),
    filter_triangular(x, window_width = 3)
  )
  expect_equal(
    filter_with(x, "sgolay", sampling_rate = 60, window_width = 5),
    filter_sgolay(x, sampling_rate = 60, window_width = 5)
  )
  expect_equal(
    filter_with(x, "kalman", sampling_rate = 60),
    filter_kalman(x, sampling_rate = 60)
  )
})

test_that("filter_with dispatches the frequency filters", {
  fs <- 100
  x <- sin(2 * pi * 2 * seq(0, 1, by = 1 / fs))

  for (m in c("lowpass", "highpass", "lowpass_fft", "highpass_fft")) {
    direct <- switch(
      m,
      lowpass = filter_lowpass(x, cutoff_freq = 10, sampling_rate = fs),
      highpass = filter_highpass(x, cutoff_freq = 10, sampling_rate = fs),
      lowpass_fft = filter_lowpass_fft(x, cutoff_freq = 10, sampling_rate = fs),
      highpass_fft = filter_highpass_fft(
        x,
        cutoff_freq = 10,
        sampling_rate = fs
      )
    )
    expect_equal(
      filter_with(x, m, cutoff_freq = 10, sampling_rate = fs),
      direct,
      info = m
    )
  }
})

test_that("filter_with passes `times` through to kalman_irregular", {
  x <- c(1, 1.1, NA, 0.9, 1.2, 0.8)
  times <- c(0, 0.1, 0.3, 0.35, 0.5, 0.8)

  expect_equal(
    filter_with(x, "kalman_irregular", times = times),
    filter_kalman_irregular(x, times = times)
  )
})

test_that("filter_with preserves shape", {
  x <- c(1, 2, 3, 100, 5, 6, 7, 8, 9)

  out_vec <- filter_with(x, "rollmean", window_width = 3)
  expect_type(out_vec, "double")
  expect_length(out_vec, length(x))

  frame <- data.frame(a = x, b = rev(x))
  out_frame <- filter_with(frame, "rollmean", window_width = 3)
  expect_s3_class(out_frame, "data.frame")
  expect_equal(names(out_frame), c("a", "b"))
  expect_equal(nrow(out_frame), length(x))
})

test_that("filter_with applies univariate methods column by column", {
  x <- c(1, 2, 3, 100, 5, 6, 7, 8, 9)
  frame <- data.frame(a = x, b = rev(x))
  out <- filter_with(frame, "rollmean", window_width = 3)

  expect_equal(out$a, filter_rollmean(x, window_width = 3))
  expect_equal(out$b, filter_rollmean(rev(x), window_width = 3))
})

test_that("filter_with requires a frame for ccma", {
  expect_error(
    filter_with(rnorm(20), "ccma"),
    "needs a frame of coordinate columns"
  )
})

test_that("filter_with dispatches ccma on a frame", {
  t <- seq(0, 2 * pi, length.out = 40)
  coords <- data.frame(x = cos(t), y = sin(t))

  expect_equal(filter_with(coords, "ccma"), filter_ccma(coords))
})

test_that("filter_with rejects an aniframe", {
  d <- anicore::aniframe(
    time = 1:9,
    x = as.numeric(1:9),
    y = as.numeric(1:9),
    variables_what = character(0)
  )
  expect_error(filter_with(d, "gaussian"), "is an aniframe")
})

test_that("filter_with rejects an unknown method", {
  expect_error(filter_with(rnorm(10), "nope"), "should be one of")
})

test_that("filter_with rejects a non-numeric column in a frame", {
  expect_error(
    filter_with(data.frame(a = 1:5, b = letters[1:5]), "rollmean"),
    "must be numeric"
  )
})
