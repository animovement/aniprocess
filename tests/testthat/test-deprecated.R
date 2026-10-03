# The filter_na_*() names warn and forward to mask_na_*() (#94)

test_that("filter_na_across() warns and matches mask_na_across()", {
  af <- anicore::as_anipoint(data.frame(
    time = 1:6,
    x = c(1, 2, 50, 4, 5, 6),
    y = c(1, 2, 3, 4, -40, 6)
  ))
  expect_warning(
    old <- filter_na_across(af, "range", min_value = 0, max_value = 10),
    class = "lifecycle_warning_deprecated"
  )
  expect_equal(
    old,
    mask_na_across(af, "range", min_value = 0, max_value = 10)
  )
})

test_that("filter_na_with() warns and matches mask_na_with()", {
  x <- c(1, 2, 50, 4)
  expect_warning(
    old <- filter_na_with(x, "range", max_value = 10),
    class = "lifecycle_warning_deprecated"
  )
  expect_equal(old, mask_na_with(x, "range", max_value = 10))
})

test_that("filter_na_range() warns and matches mask_na_range()", {
  x <- c(-5, 1, 2, 50)
  expect_warning(
    old <- filter_na_range(x, min_value = 0, max_value = 10),
    class = "lifecycle_warning_deprecated"
  )
  expect_equal(old, mask_na_range(x, min_value = 0, max_value = 10))
})

test_that("filter_na_confidence() warns and matches mask_na_confidence()", {
  d <- data.frame(x = 1:4, y = 1:4)
  conf <- c(0.9, 0.2, 0.8, 0.1)
  expect_warning(
    old <- filter_na_confidence(d, threshold = 0.5, confidence = conf),
    class = "lifecycle_warning_deprecated"
  )
  expect_equal(
    old,
    mask_na_confidence(d, threshold = 0.5, confidence = conf)
  )
})

test_that("filter_na_speed() warns and matches mask_na_speed()", {
  d <- data.frame(x = c(0, 1, 2, 30, 4, 5), y = 0)
  expect_warning(
    old <- filter_na_speed(d, threshold = 5, time = 1:6),
    class = "lifecycle_warning_deprecated"
  )
  expect_equal(old, mask_na_speed(d, threshold = 5, time = 1:6))
})

test_that("filter_na_excursion() warns and matches mask_na_excursion()", {
  set.seed(1)
  d <- data.frame(x = c(rnorm(30), 40, 41, rnorm(30)), y = rnorm(62))
  expect_warning(
    old <- filter_na_excursion(d, outlier_sd = 4),
    class = "lifecycle_warning_deprecated"
  )
  expect_equal(old, mask_na_excursion(d, outlier_sd = 4))
})

test_that("filter_na_roi() warns and matches mask_na_roi()", {
  d <- data.frame(x = c(0, 5, 20), y = c(0, 5, 20))
  expect_warning(
    old <- filter_na_roi(d, x_min = 0, x_max = 10, y_min = 0, y_max = 10),
    class = "lifecycle_warning_deprecated"
  )
  expect_equal(
    old,
    mask_na_roi(d, x_min = 0, x_max = 10, y_min = 0, y_max = 10)
  )
})
