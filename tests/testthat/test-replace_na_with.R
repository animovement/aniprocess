# Tests for replace_na_with()
# - Every method dispatches to the same result as calling the function directly
# - Gap constraints are forwarded
# - Shape is preserved; frames are filled column by column
# - replace_na() is an alias for it
# - "value" requires a value

test_that("replace_na_with dispatches every method", {
  x <- c(1, NA, NA, 4, 5, NA, 7)

  expect_equal(replace_na_with(x, "linear"), replace_na_linear(x))
  expect_equal(replace_na_with(x, "spline"), replace_na_spline(x))
  expect_equal(replace_na_with(x, "stine"), replace_na_stine(x))
  expect_equal(replace_na_with(x, "locf"), replace_na_locf(x))
  expect_equal(
    replace_na_with(x, "value", value = 0),
    replace_na_value(x, value = 0)
  )
})

test_that("replace_na_with defaults to linear", {
  x <- c(1, NA, 3)
  expect_equal(replace_na_with(x), replace_na_linear(x))
})

test_that("replace_na_with forwards the gap constraints", {
  x <- c(1, NA, NA, NA, 5, NA, 7)

  expect_equal(
    replace_na_with(x, "linear", max_gap = 1),
    replace_na_linear(x, max_gap = 1)
  )
  expect_equal(
    replace_na_with(x, "linear", min_gap = 2),
    replace_na_linear(x, min_gap = 2)
  )
  expect_equal(
    replace_na_with(x, "locf", max_gap = 1),
    replace_na_locf(x, max_gap = 1)
  )
  expect_equal(
    replace_na_with(x, "value", value = -1, max_gap = 1),
    replace_na_value(x, value = -1, max_gap = 1)
  )
})

test_that("replace_na_with requires a value for method = 'value'", {
  expect_error(
    replace_na_with(c(1, NA, 3), "value"),
    "must be specified"
  )
})

test_that("replace_na_with preserves shape and fills column by column", {
  x <- c(1, NA, NA, 4, 5)

  out_vec <- replace_na_with(x, "linear")
  expect_type(out_vec, "double")
  expect_length(out_vec, length(x))

  frame <- data.frame(a = x, b = rev(x))
  out_frame <- replace_na_with(frame, "locf")
  expect_s3_class(out_frame, "data.frame")
  expect_equal(out_frame$a, replace_na_locf(x))
  expect_equal(out_frame$b, replace_na_locf(rev(x)))
})

test_that("replace_na_with works with dplyr::across", {
  # Every method is univariate, so unlike the other two generics this one
  # is across()-compatible.
  frame <- data.frame(a = c(1, NA, 3), b = c(NA, 2, 3))
  out <- dplyr::mutate(
    frame,
    dplyr::across(dplyr::everything(), \(v) replace_na_with(v, "locf"))
  )
  expect_equal(out$a, replace_na_locf(c(1, NA, 3)))
  expect_equal(out$b, replace_na_locf(c(NA, 2, 3)))
})

test_that("replace_na_with rejects an unknown method", {
  expect_error(replace_na_with(c(1, NA, 3), "nope"), "should be one of")
})

test_that("replace_na_with rejects an aniframe", {
  d <- anicore::aniframe(
    time = 1:3,
    x = c(1, NA, 3),
    y = c(1, 2, 3),
    variables_what = character(0)
  )
  expect_error(replace_na_with(d), "is an aniframe")
})

# --- behaviour moved from test-replace_na.R -----------------------------

# Test data setup
simple_vec <- c(1, NA, NA, 4, 5, NA, NA, NA, 9)
edge_nas <- c(NA, NA, 3, 4, NA, NA)
single_gap <- c(1, NA, 3)
no_nas <- c(1, 2, 3, 4, 5)
all_nas <- rep(NA_real_, 5)

test_that("replace_na_with input validation works", {
  # Check numeric input requirement
  expect_error(replace_na_with("not numeric"), "must be numeric")
  expect_error(replace_na_with(factor(1:3)), "must be numeric")

  # Check method validation
  expect_error(replace_na_with(simple_vec, method = "invalid"))

  # Check value parameter
  expect_error(
    replace_na_with(simple_vec, method = "value"),
    "must be specified"
  )
  expect_error(
    replace_na_with(simple_vec, method = "value", value = "0"),
    "must be a single numeric value"
  )
  expect_error(
    replace_na_with(simple_vec, method = "value", value = c(1, 2)),
    "must be a single numeric value"
  )

  # Check gap parameters
  expect_error(replace_na_with(simple_vec, min_gap = 0), "min_gap must be >= 1")
  expect_error(
    replace_na_with(simple_vec, min_gap = 3, max_gap = 2),
    "max_gap must be >= min_gap"
  )
})

test_that("replace_na_with handles edge cases correctly", {
  # No NAs
  expect_identical(replace_na_with(no_nas), no_nas)
  expect_identical(replace_na_with(no_nas, method = "spline"), no_nas)
  expect_identical(replace_na_with(no_nas, method = "value", value = 0), no_nas)

  # All NAs
  expect_warning(
    replace_na_with(all_nas),
    "At least 2 non-NA data points required"
  )
  expect_warning(
    replace_na_with(all_nas, method = "spline"),
    "At least 2 non-NA data points required"
  )
})

test_that("linear interpolation works correctly", {
  # Basic interpolation
  result <- replace_na_with(c(1, NA, 3), method = "linear")
  expect_equal(result, c(1, 2, 3))

  # Edge NAs should be filled using rule = 2
  result <- replace_na_with(edge_nas, method = "linear")
  expect_equal(result[1:2], c(3, 3)) # First NAs filled with first non-NA
  expect_equal(result[5:6], c(4, 4)) # Last NAs filled with last non-NA

  # Gap constraints
  result <- replace_na_with(simple_vec, method = "linear", min_gap = 3)
  expect_true(is.na(result[2])) # Single NA should remain

  result <- replace_na_with(simple_vec, method = "linear", max_gap = 2)
  expect_true(all(is.na(result[6:8]))) # Gap of 3 should remain NA
})

test_that("spline interpolation works correctly", {
  # Basic interpolation
  result <- replace_na_with(single_gap, method = "spline")
  expect_equal(result[2], 2, tolerance = 0.1)

  # Gap constraints
  result <- replace_na_with(simple_vec, method = "spline", min_gap = 3)
  expect_true(is.na(result[2])) # Single NA should remain

  # Should handle edge cases like linear
  result <- replace_na_with(edge_nas, method = "spline")
  expect_false(any(is.na(result)))
})

test_that("stine interpolation works correctly", {
  skip_if_not_installed("stinepack")
  # Basic interpolation
  result <- replace_na_with(single_gap, method = "stine")
  expect_equal(result[2], 2, tolerance = 0.1)

  # Gap constraints
  result <- replace_na_with(simple_vec, method = "stine", min_gap = 3)
  expect_true(is.na(result[2])) # Single NA should remain

  # Trailing NAs cannot be extrapolated by stinterp; they should be
  # carried forward (LOCF) so the output ends at the last known value.
  # Leading NAs stay NA because there is nothing to carry forward.
  trailing <- c(NA, NA, 1, 2, 3, 4, 5, NA, NA)
  result <- replace_na_with(trailing, method = "stine")
  expect_true(all(is.na(result[1:2])))
  expect_equal(result[3:7], c(1, 2, 3, 4, 5))
  expect_equal(result[8:9], c(5, 5))
})

test_that("locf works correctly", {
  # Basic filling
  expect_equal(
    replace_na_with(c(1, NA, NA, 2), method = "locf"),
    c(1, 1, 1, 2)
  )

  # Edge NAs at start should remain NA
  result <- replace_na_with(c(NA, NA, 1, NA), method = "locf")
  expect_true(all(is.na(result[1:2])))
  expect_equal(result[3:4], c(1, 1))

  # Gap constraints
  result <- replace_na_with(simple_vec, method = "locf", min_gap = 3)
  expect_true(is.na(result[2])) # Single NA should remain

  result <- replace_na_with(simple_vec, method = "locf", max_gap = 2)
  expect_true(all(is.na(result[6:8]))) # Gap of 3 should remain NA
})

test_that("value replacement works correctly", {
  # Basic replacement
  expect_equal(
    replace_na_with(c(1, NA, NA, 2), method = "value", value = 0),
    c(1, 0, 0, 2)
  )

  # Gap constraints
  result <- replace_na_with(
    simple_vec,
    method = "value",
    value = -999,
    min_gap = 3
  )
  expect_true(is.na(result[2])) # Single NA should remain
  expect_equal(result[6:8], rep(-999, 3)) # Longer gap should be filled

  result <- replace_na_with(
    simple_vec,
    method = "value",
    value = -999,
    max_gap = 2
  )
  expect_equal(result[2], -999) # Single NA should be filled
  expect_true(all(is.na(result[6:8]))) # Gap of 3 should remain NA
})

test_that("min_gap and max_gap work together correctly", {
  # Test all methods with both constraints
  methods <- c("linear", "spline", "stine", "locf")

  for (method in methods) {
    result <- replace_na_with(
      simple_vec,
      method = method,
      min_gap = 2,
      max_gap = 2
    )

    # Single NA should remain (gap too small)
    expect_true(!is.na(result[2]))

    # Triple NA should remain (gap too large)
    expect_true(all(is.na(result[6:8])))

    # Double NA should be filled (gap size 2)
    expect_false(any(is.na(result[3:4])))
  }

  # Test value method separately
  result <- replace_na_with(
    simple_vec,
    method = "value",
    value = 0,
    min_gap = 2,
    max_gap = 2
  )

  expect_true(!is.na(result[2])) # Single NA
  expect_true(all(is.na(result[6:8]))) # Triple NA
  expect_equal(result[2:3], c(0, 0)) # Double NA
})

# Direct replace_na_*() calls — the public functions are reachable on
# their own (not just via replace_na_with()), so the early-return paths and
# the < 2 non-NA warning are their responsibility to cover.

test_that("replace_na_locf returns input unchanged when no NAs are present", {
  expect_identical(replace_na_locf(c(1, 2, 3)), c(1, 2, 3))
})

test_that("replace_na_stine returns input unchanged when no NAs are present", {
  skip_if_not_installed("stinepack")
  expect_identical(replace_na_stine(c(1, 2, 3)), c(1, 2, 3))
})

test_that("replace_na_stine warns and returns when < 2 non-NA values", {
  skip_if_not_installed("stinepack")
  expect_warning(
    out <- replace_na_stine(c(NA_real_, NA_real_, 1, NA_real_, NA_real_)[1:2]),
    "2 non-NA"
  )
  expect_equal(length(out), 2)
})

test_that("replace_na_linear honours an explicit rule argument", {
  # When `rule` is passed via ..., the function takes the alternate
  # stats::approx() branch (no rule = 2 default).
  out <- replace_na_linear(c(NA, 1, 2, 3, NA), rule = 1)
  # rule = 1 leaves out-of-range NAs as NA.
  expect_true(is.na(out[1]))
  expect_true(is.na(out[5]))
  expect_equal(out[2:4], c(1, 2, 3))
})
