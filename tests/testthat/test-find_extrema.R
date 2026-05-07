#' @title Tests for peak and trough detection functions
#' @description Tests for find_peaks and find_troughs functions

library(testthat)

test_that("basic peak detection works", {
  # Simple peaks
  x <- c(1, 3, 1, 4, 2, 5, 2, 3, 1)
  expect_equal(which(find_peaks(x)), c(2, 4, 6, 8))

  # No peaks
  x <- c(1, 2, 3, 4, 5)
  expect_equal(which(find_peaks(x)), integer(0))

  # All same value
  x <- rep(1, 5)
  expect_equal(which(find_peaks(x)), integer(0))
})

test_that("basic trough detection works", {
  # Simple troughs
  x <- c(5, 2, 4, 1, 3, 0, 4)
  expect_equal(which(find_troughs(x)), c(2, 4, 6))

  # No troughs
  x <- c(5, 4, 3, 2, 1)
  expect_equal(which(find_troughs(x)), integer(0))

  # All same value
  x <- rep(1, 5)
  expect_equal(which(find_troughs(x)), integer(0))
})

test_that("height thresholds work correctly", {
  x <- c(1, 3, 1, 5, 2, 4, 1)

  # Peaks
  expect_equal(which(find_peaks(x, min_height = 4)), c(4))
  expect_equal(which(find_peaks(x, min_height = 6)), integer(0))

  # Troughs
  expect_equal(which(find_troughs(x, max_height = 2)), c(3))
  expect_equal(which(find_troughs(x, max_height = 0)), integer(0))
})

test_that("prominence filtering works", {
  # Peaks with different prominences
  x <- c(1, 3, 2.5, 2.8, 2, 5, 2)
  expect_equal(which(find_peaks(x, min_prominence = 1)), c(2, 6))
  expect_equal(which(find_peaks(x, min_prominence = 3)), c(6))

  # Troughs with different prominences
  x <- c(5, 3, 3.5, 3.2, 4, 1, 4)
  expect_equal(which(find_troughs(x, min_prominence = 1)), c(2, 6))
  expect_equal(which(find_troughs(x, min_prominence = 3)), c(6))
})

test_that("NA handling works correctly", {
  # Test NA in the middle
  x <- c(1, 3, NA, 2, 4)
  expect_equal(is.na(find_peaks(x)), c(TRUE, TRUE, TRUE, TRUE, TRUE))

  # Test NA at start/end
  x <- c(NA, 2, 4, 1, NA)
  expect_equal(is.na(find_peaks(x)), c(TRUE, TRUE, FALSE, TRUE, TRUE))

  # Test consecutive NAs
  x <- c(1, NA, NA, 1)
  expect_equal(is.na(find_peaks(x)), c(TRUE, TRUE, TRUE, TRUE))
})

test_that("plateau handling works for peaks", {
  x <- c(1, 3, 3, 3, 1)

  # Test strict mode
  expect_equal(which(find_peaks(x, plateau_handling = "strict")), integer(0))

  # Test middle mode
  middle_peaks <- which(find_peaks(x, plateau_handling = "middle"))
  expect_equal(middle_peaks, 3)

  # Test first mode
  expect_equal(which(find_peaks(x, plateau_handling = "first")), 2)

  # Test last mode
  expect_equal(which(find_peaks(x, plateau_handling = "last")), 4)

  # Test all mode
  expect_equal(which(find_peaks(x, plateau_handling = "all")), 2:4)
})

test_that("plateau handling works for troughs", {
  x <- c(3, 1, 1, 1, 3)

  # Test strict mode
  expect_equal(which(find_troughs(x, plateau_handling = "strict")), integer(0))

  # Test middle mode
  middle_troughs <- which(find_troughs(x, plateau_handling = "middle"))
  expect_equal(middle_troughs, 3)

  # Test first mode
  expect_equal(which(find_troughs(x, plateau_handling = "first")), 2)

  # Test last mode
  expect_equal(which(find_troughs(x, plateau_handling = "last")), 4)

  # Test all mode
  expect_equal(which(find_troughs(x, plateau_handling = "all")), 2:4)
})

test_that("edge cases are handled correctly", {
  # Test very short sequences
  expect_equal(is.na(find_peaks(c(1))), TRUE)
  expect_equal(is.na(find_peaks(c(1, 2))), c(TRUE, TRUE))

  # Test sequences with all equal values
  x <- rep(1, 10)
  expect_equal(sum(find_peaks(x)), as.integer(NA))
  expect_equal(sum(find_troughs(x)), as.integer(NA))

  # Test extreme values
  x <- c(-.Machine$double.max, 0, -.Machine$double.max)
  expect_equal(which(find_peaks(x)), 2)
  x <- c(.Machine$double.max, 0, .Machine$double.max)
  expect_equal(which(find_troughs(x)), 2)
})

test_that("input validation works", {
  # Test non-numeric input
  expect_error(find_peaks(letters))
  expect_error(find_troughs(letters))

  # Test invalid plateau handling method
  expect_error(find_peaks(1:5, plateau_handling = "invalid"))

  # Test NULL input
  # expect_error(find_peaks(NULL))
  # expect_error(find_troughs(NULL))
})

test_that("multiple plateaus are handled correctly", {
  x <- c(1, 3, 3, 2, 2, 2, 4, 4, 1)

  # Test middle mode with multiple plateaus
  middle_peaks <- which(find_peaks(x, plateau_handling = "middle"))
  expect_equal(middle_peaks, c(2, 3, 7, 8)) # Both points for even-length plateau

  # Test multiple plateaus with different lengths
  x <- c(1, 3, 3, 3, 2, 4, 4, 1)
  first_peaks <- which(find_peaks(x, plateau_handling = "first"))
  expect_equal(first_peaks, c(2, 6))
})

test_that("prominence uses the standard topographic definition (saddle = max of left/right valley min)", {
  # Regression test for a bug where prominence was computed as
  # peak - min(everything in surrounding valley) instead of
  # peak - max(min_left_valley, min_right_valley). The two definitions
  # disagree when the left and right valley minima differ; the buggy
  # version overestimated prominence.
  #
  # x = c(1, 5, 2, 8, 3, 1):
  #   Peak at idx 2 (val 5) is between the start (val 1) and a higher
  #   peak at idx 4 (val 8). Left valley min = 1, right valley min = 2.
  #   Standard prominence = 5 - max(1, 2) = 3.
  #   Buggy "base elevation" prominence would be 5 - 1 = 4.
  x <- c(1, 5, 2, 8, 3, 1)

  # min_prominence = 3.5: standard prominence (3) is below threshold,
  # so idx 2 must be excluded. The buggy version would keep it.
  expect_false(find_peaks(x, min_prominence = 3.5)[2])

  # min_prominence = 2.5: standard prominence (3) is above, so kept.
  expect_true(find_peaks(x, min_prominence = 2.5)[2])

  # Symmetric check on troughs.
  y <- c(9, 5, 8, 2, 7, 9)
  expect_false(find_troughs(y, min_prominence = 3.5)[2])
  expect_true(find_troughs(y, min_prominence = 2.5)[2])
})

test_that("plateaus below the height threshold are not flagged", {
  # Plateau at value 2 with min_height = 5 — value fails the height
  # check inside handle_plateau and the plateau is not flagged.
  x <- c(1, 2, 2, 2, 1)
  out <- find_peaks(x, min_height = 5, plateau_handling = "all")
  expect_false(any(out, na.rm = TRUE))
})

test_that("plateau adjacent to NA is marked NA", {
  # Plateau at idx 2:4 with NA immediately after. handle_plateau cannot
  # determine extremum status (NA in extended window) and returns
  # is_na = TRUE; the plateau positions are set to NA in the output.
  x <- c(1, 5, 5, 5, NA, 1)
  out <- find_peaks(x, plateau_handling = "all")
  expect_true(all(is.na(out[2:4])))
})

test_that("prominence calculation marks NA when the boundary walk hits NA", {
  # Peak at idx 3 (val 5). The left-walk decrements until x[1] = NA,
  # which terminates the loop with x[left_idx] = NA -> is_extremum
  # becomes NA, not TRUE.
  x <- c(NA, 0, 5, 1, 6, 2, NA)
  out <- find_peaks(x, min_prominence = 1)
  expect_true(is.na(out[3]))
})

test_that("prominence works with plateaus", {
  x <- c(1, 3, 3, 3, 2, 5, 5, 1)

  # Test prominence with plateau handling
  peaks <- which(find_peaks(x, min_prominence = 3, plateau_handling = "all"))
  expect_equal(peaks, 6:7) # Only the higher plateau qualifies

  # Test lower prominence
  peaks <- which(find_peaks(x, min_prominence = 1, plateau_handling = "all"))
  expect_equal(peaks, c(2:4, 6:7)) # Both plateaus qualify
})

test_that("window size parameter works correctly", {
  # Test case where wider window identifies fewer peaks
  x <- c(1, 3, 2, 4, 3, 5, 4, 6, 5, 7, 6)
  peaks_w3 <- which(find_peaks(x, window_size = 3))
  peaks_w5 <- which(find_peaks(x, window_size = 5))
  expect_true(length(peaks_w3) > length(peaks_w5))

  # Test window size validation
  expect_error(find_peaks(1:10, window_size = 2)) # Too small
  expect_error(find_peaks(1:10, window_size = 4)) # Even number
  expect_error(find_peaks(1:10, window_size = "3")) # Not numeric

  # Test behavior with window size larger than data
  x_short <- 1:5
  expect_equal(find_peaks(x_short, window_size = 7), rep(NA, 5))

  # Test edge handling with different window sizes
  x <- c(1, 3, 2, 4, 2, 3, 1)
  result_w3 <- find_peaks(x, window_size = 3)
  result_w5 <- find_peaks(x, window_size = 5)
  expect_equal(sum(is.na(result_w3)), 2) # First and last points
  expect_equal(sum(is.na(result_w5)), 4) # Two points on each end

  # Test with noisy data
  set.seed(123)
  x <- sin(seq(0, 4 * pi, length.out = 100)) + rnorm(100, 0, 0.1)
  peaks_w3 <- sum(find_peaks(x, window_size = 3), na.rm = TRUE)
  peaks_w7 <- sum(find_peaks(x, window_size = 7), na.rm = TRUE)
  peaks_w11 <- sum(find_peaks(x, window_size = 11), na.rm = TRUE)
  expect_true(peaks_w3 > peaks_w7)
  expect_true(peaks_w7 > peaks_w11)

  # Test plateau handling with different window sizes
  x <- c(1, 3, 3, 3, 2, 4, 4, 4, 2)
  peaks_w3 <- which(find_peaks(x, window_size = 3, plateau_handling = "middle"))
  peaks_w5 <- which(find_peaks(x, window_size = 5, plateau_handling = "middle"))
  expect_equal(peaks_w3, c(3, 7)) # Both plateaus are peaks
  expect_equal(peaks_w5, 7) # Only second plateau is peak

  # Test with NAs and different window sizes
  x <- c(1, 3, NA, 4, 2, 5, NA, 3, 1)
  result_w3 <- find_peaks(x, window_size = 3)
  result_w5 <- find_peaks(x, window_size = 5)
  expect_true(sum(is.na(result_w5)) > sum(is.na(result_w3)))
})
