# Tests for filter_na_with()
# - "range" is univariate; the rest need a frame of coordinates
# - Every method dispatches to the same result as calling the function directly
# - Shape is preserved
# - An aniframe is rejected

test_that("filter_na_with dispatches range on a vector", {
  x <- c(1, 5, 10, 15)

  expect_equal(
    filter_na_with(x, "range", min_value = 3, max_value = 12),
    filter_na_range(x, min_value = 3, max_value = 12)
  )
})

test_that("filter_na_with applies range column by column", {
  frame <- data.frame(a = c(1, 5, 10, 15), b = c(20, 5, 1, 8))
  out <- filter_na_with(frame, "range", min_value = 3, max_value = 12)

  expect_equal(out$a, filter_na_range(frame$a, min_value = 3, max_value = 12))
  expect_equal(out$b, filter_na_range(frame$b, min_value = 3, max_value = 12))
})

test_that("filter_na_with dispatches speed on a frame", {
  coords <- data.frame(x = c(0, 1, 2, 50, 4, 5), y = rep(0, 6))
  tm <- 1:6

  expect_equal(
    filter_na_with(coords, "speed", threshold = 10, time = tm),
    filter_na_speed(coords, threshold = 10, time = tm)
  )
})

test_that("filter_na_with dispatches excursion on a frame", {
  set.seed(21)
  x <- rnorm(40, sd = 2)
  x[10:12] <- x[10:12] + 40
  coords <- data.frame(x = x, y = rnorm(40, sd = 2))

  expect_equal(
    filter_na_with(coords, "excursion"),
    filter_na_excursion(coords)
  )
})

test_that("filter_na_with dispatches roi on a frame", {
  coords <- data.frame(x = c(0, 10, 20), y = c(0, 10, 20))

  expect_equal(
    filter_na_with(coords, "roi", x_min = 5, x_max = 15),
    filter_na_roi(coords, x_min = 5, x_max = 15)
  )
})

test_that("filter_na_with dispatches confidence on a frame", {
  coords <- data.frame(x = c(1, 2, 3, 4), y = c(5, 6, 7, 8))
  conf <- c(0.9, 0.2, 0.8, 0.7)

  expect_equal(
    filter_na_with(coords, "confidence", threshold = 0.6, confidence = conf),
    filter_na_confidence(coords, threshold = 0.6, confidence = conf)
  )
})

test_that("filter_na_with requires a frame for the multivariate methods", {
  for (m in c("speed", "excursion", "roi", "confidence")) {
    expect_error(
      filter_na_with(rnorm(10), m),
      "needs a frame of coordinate columns",
      info = m
    )
  }
})

test_that("filter_na_with preserves shape", {
  out_vec <- filter_na_with(c(1, 5, 10, 15), "range", min_value = 3)
  expect_type(out_vec, "double")

  coords <- data.frame(x = c(0, 1, 2, 50, 4, 5), y = rep(0, 6))
  out_frame <- filter_na_with(coords, "speed", threshold = 10, time = 1:6)
  expect_s3_class(out_frame, "data.frame")
  expect_equal(names(out_frame), c("x", "y"))
})

test_that("filter_na_with rejects an aniframe", {
  d <- aniframe::aniframe(
    time = 1:9,
    x = as.numeric(1:9),
    y = as.numeric(1:9),
    variables_what = character(0)
  )
  expect_error(filter_na_with(d, "speed"), "is an aniframe")
})

test_that("filter_na_with rejects an unknown method", {
  expect_error(filter_na_with(rnorm(10), "nope"), "should be one of")
})
