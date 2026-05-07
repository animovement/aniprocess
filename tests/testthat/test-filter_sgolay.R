test_that("filter reproduces polynomials of degree <= order (defining property)", {
  # The defining property of the Savitzky-Golay filter: a polynomial of
  # degree <= order is reproduced exactly (up to floating-point error).
  n <- 100
  t <- seq_len(n) - 1
  for (deg in 0:4) {
    x <- t^deg
    out <- filter_sgolay(
      x,
      sampling_rate = 60,
      window_size = 11,
      order = max(deg, 2)
    )
    # Tolerance loosens with degree because the Vandermonde-like fit gets
    # numerically harder for higher-degree polynomials.
    expect_equal(out, x, tolerance = 10^(deg - 12))
  }
})

test_that("filter handles basic cases correctly", {
  # Create simple sine wave
  t <- seq(0, 1, by = 1 / 60) # 60 FPS
  x <- sin(2 * pi * 2 * t) # 2 Hz sine wave

  # Basic filtering should work
  expect_no_error(filter_sgolay(x, sampling_rate = 60))

  # Output should be same length as input
  filtered <- filter_sgolay(x, sampling_rate = 60)
  expect_equal(length(filtered), length(x))

  # Filtered data should be smoother (less variance in differences)
  expect_lt(var(diff(filtered)), var(diff(x)))
})

test_that("parameter validation works", {
  x <- rnorm(100)

  # Invalid data type
  expect_error(
    filter_sgolay("not numeric", sampling_rate = 60),
    "Data must be numeric"
  )

  # Invalid sampling rate
  expect_error(
    filter_sgolay(x, sampling_rate = -1),
    "Sampling rate must be a positive number"
  )
  expect_error(
    filter_sgolay(x, sampling_rate = 0),
    "Sampling rate must be a positive number"
  )

  # Invalid window size
  expect_error(
    filter_sgolay(x, sampling_rate = 60, window_size = 4),
    "Window size must be odd"
  )
  expect_error(
    filter_sgolay(x, sampling_rate = 60, window_size = 101),
    "Window size cannot be larger than data length"
  )

  # Invalid polynomial order
  expect_error(
    filter_sgolay(x, sampling_rate = 60, window_size = 11, order = 11),
    "Polynomial order must be less than window size"
  )
})

test_that("NA handling works correctly", {
  x <- rnorm(100)
  x[c(25, 75)] <- NA

  # Error on NA with na_action = "error"
  expect_error(
    filter_sgolay(x, sampling_rate = 60, na_action = "error"),
    "NA values present in data"
  )

  # Linear interpolation (default)
  filtered <- filter_sgolay(x, sampling_rate = 60)
  expect_false(any(is.na(filtered)))

  # Keep NA option
  filtered_with_na <- filter_sgolay(x, sampling_rate = 60, keep_na = TRUE)
  expect_true(all(is.na(filtered_with_na[c(25, 75)])))
})

test_that("filter preserves signal features appropriately", {
  # Create complex signal with multiple frequencies
  t <- seq(0, 1, by = 1 / 60)
  x <- sin(2 * pi * 2 * t) + 0.5 * sin(2 * pi * 10 * t) # 2 Hz and 10 Hz components

  # Test different polynomial orders
  filtered_order2 <- filter_sgolay(x, sampling_rate = 60, order = 2)
  filtered_order4 <- filter_sgolay(x, sampling_rate = 60, order = 4)

  # Higher order should preserve more high-frequency content
  freq_content_order2 <- abs(fft(filtered_order2))
  freq_content_order4 <- abs(fft(filtered_order4))
  high_freq_power2 <- sum(freq_content_order2[11:30])
  high_freq_power4 <- sum(freq_content_order4[11:30])
  expect_gt(high_freq_power4, high_freq_power2)
})

test_that("window size affects smoothing appropriately", {
  # Create noisy sine wave
  t <- seq(0, 1, by = 1 / 60)
  x <- sin(2 * pi * 2 * t) + rnorm(length(t), 0, 0.1)

  # Test different window sizes
  filtered_small <- filter_sgolay(x, sampling_rate = 60, window_size = 5)
  filtered_large <- filter_sgolay(x, sampling_rate = 60, window_size = 21)

  # Larger window should result in smoother output
  expect_gt(var(diff(filtered_small)), var(diff(filtered_large)))
})

test_that("default parameters are reasonable", {
  # Create typical movement data
  t <- seq(0, 1, by = 1 / 60)
  x <- sin(2 * pi * 2 * t) + rnorm(length(t), 0, 0.1)

  # Should work with just data and sampling rate
  expect_no_error(filter_sgolay(x, sampling_rate = 60))

  # Default window size should be sampling_rate/10 rounded to odd
  expected_window <- ceiling(60 / 10) * 2 + 1
  default_result <- filter_sgolay(x, sampling_rate = 60)
  explicit_result <- filter_sgolay(
    x,
    sampling_rate = 60,
    window_size = expected_window
  )
  expect_equal(default_result, explicit_result)
})
