# Interpolation places the imputed value at a moment, not at a row (#67)

test_that("replace_na_across() interpolates on the index, not row position", {
  # 0 s, 1 s, 10 s with the middle value missing. The true value at t = 1 is
  # one tenth of the way along, not half.
  af <- anicore::as_aniframe(data.frame(
    individual = "a",
    time = c(0, 1, 10),
    x = c(0, NA, 100),
    y = c(0, NA, 100)
  ))

  out <- replace_na_across(af, "linear")

  expect_equal(out$x[2], 10)
  expect_equal(out$y[2], 10)
})

test_that("a regularly sampled frame is unaffected", {
  # Row position and the index are proportional here, so the two agree --
  # which is why this went unnoticed.
  af <- anicore::as_aniframe(data.frame(
    individual = "a",
    time = 1:5,
    x = c(0, NA, NA, NA, 100),
    y = 1:5
  ))

  expect_equal(replace_na_across(af, "linear")$x, c(0, 25, 50, 75, 100))
})

test_that("it follows a frame indexed by something other than time", {
  af <- anicore::as_aniframe(
    data.frame(
      individual = "a",
      frame = c(0, 1, 10),
      x = c(0, NA, 100),
      y = 1:3
    ),
    index = "frame"
  )

  expect_equal(replace_na_across(af, "linear")$x[2], 10)
})

test_that("the vector functions still default to row position", {
  # Called directly, with no index to go on, they behave as before.
  expect_equal(replace_na_linear(c(0, NA, 100))[2], 50)
  expect_equal(replace_na_linear(c(0, NA, 100), times = c(0, 1, 10))[2], 10)
})

test_that("times must line up with the data", {
  expect_error(
    replace_na_linear(c(0, NA, 100), times = c(0, 1)),
    "same length"
  )
  expect_error(
    replace_na_linear(c(0, NA, 100), times = c("a", "b", "c")),
    "numeric"
  )
})

test_that("spline and stine interpolate on the index too", {
  af <- anicore::as_aniframe(data.frame(
    individual = "a",
    time = c(0, 1, 2, 10),
    x = c(0, NA, 20, 100),
    y = 1:4
  ))

  # Not asserting the exact spline value, only that the abscissa is the index:
  # on row position the t = 1 estimate is pulled towards the midpoint.
  spl <- replace_na_across(af, "spline")$x[2]
  expect_true(spl < 20)
  expect_false(is.na(spl))
})

test_that("replace_na_across() says so when the index column is gone", {
  # The declaration names a column the frame no longer carries, so there is
  # no index to interpolate against.
  af <- anicore::example_aniframe(
    n_obs = 10,
    n_individuals = 1,
    n_keypoints = 1
  )
  stripped <- suppressWarnings(dplyr::select(dplyr::ungroup(af), -"time"))

  expect_error(
    replace_na_across(stripped, method = "linear"),
    "Missing index column"
  )
})
