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

test_that("replace_na is an alias for replace_na_with", {
  x <- c(1, NA, NA, 4, 5, NA, 7)

  for (m in c("linear", "spline", "stine", "locf")) {
    expect_equal(replace_na(x, m), replace_na_with(x, m), info = m)
  }
  expect_equal(
    replace_na(x, "value", value = 0),
    replace_na_with(x, "value", value = 0)
  )
  expect_equal(
    replace_na(x, "linear", max_gap = 1),
    replace_na_with(x, "linear", max_gap = 1)
  )
})

test_that("replace_na_with rejects an unknown method", {
  expect_error(replace_na_with(c(1, NA, 3), "nope"), "should be one of")
})

test_that("replace_na_with rejects an aniframe", {
  d <- aniframe::aniframe(
    time = 1:3,
    x = c(1, NA, 3),
    y = c(1, 2, 3),
    variables_what = character(0)
  )
  expect_error(replace_na_with(d), "is an aniframe")
})
