# `replace_na()` is deprecated in favour of `replace_na_with()`.
# Its behaviour is tested in test-replace_na_with.R; this file only
# covers the deprecation contract.

test_that("replace_na is deprecated in favour of replace_na_with", {
  rlang::local_options(lifecycle_verbosity = "warning")

  expect_warning(
    replace_na(c(1, NA, 3)),
    "deprecated"
  )
  # It still delegates correctly, for every method and the gap arguments
  x <- c(1, NA, NA, 4, 5, NA, 7)
  for (m in c("linear", "spline", "stine", "locf")) {
    expect_equal(
      suppressWarnings(replace_na(x, m)),
      replace_na_with(x, m),
      info = m
    )
  }
  expect_equal(
    suppressWarnings(replace_na(x, "value", value = 0)),
    replace_na_with(x, "value", value = 0)
  )
  expect_equal(
    suppressWarnings(replace_na(x, "linear", max_gap = 1)),
    replace_na_with(x, "linear", max_gap = 1)
  )
})
