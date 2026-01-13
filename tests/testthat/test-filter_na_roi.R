# Tests for filter_na_roi and helper functions
# - Rectangular ROI with individual boundaries (x_min, x_max, y_min, y_max)
# - Rectangular ROI with multiple boundaries
# - Cuboid ROI (3D) with z boundaries
# - Circular ROI filters correctly (2D)
# - Spherical ROI filters correctly (3D)
# - Points on boundaries are handled correctly
# - Preserves existing NAs
# - Validates ROI parameters are provided
# - Validates circular/spherical ROI has all required parameters
# - Validates z parameters only used with 3D data
# - Error messages are clear

test_that("filter_na_roi filters rectangular ROI with x_min", {
  data <- aniframe::aniframe(
    time = 1:4,
    x = c(0, 5, 10, 15),
    y = c(0, 5, 10, 15)
  )

  result <- filter_na_roi(data, x_min = 7)

  expect_equal(result$x, c(NA, NA, 10, 15))
  expect_equal(result$y, c(NA, NA, 10, 15))
})

test_that("filter_na_roi filters rectangular ROI with x_max", {
  data <- aniframe::aniframe(
    time = 1:4,
    x = c(0, 5, 10, 15),
    y = c(0, 5, 10, 15)
  )

  result <- filter_na_roi(data, x_max = 7)

  expect_equal(result$x, c(0, 5, NA, NA))
  expect_equal(result$y, c(0, 5, NA, NA))
})

test_that("filter_na_roi filters rectangular ROI with y_min", {
  data <- aniframe::aniframe(
    time = 1:4,
    x = c(0, 5, 10, 15),
    y = c(0, 5, 10, 15)
  )

  result <- filter_na_roi(data, y_min = 7)

  expect_equal(result$x, c(NA, NA, 10, 15))
  expect_equal(result$y, c(NA, NA, 10, 15))
})

test_that("filter_na_roi filters rectangular ROI with y_max", {
  data <- aniframe::aniframe(
    time = 1:4,
    x = c(0, 5, 10, 15),
    y = c(0, 5, 10, 15)
  )

  result <- filter_na_roi(data, y_max = 7)

  expect_equal(result$x, c(0, 5, NA, NA))
  expect_equal(result$y, c(0, 5, NA, NA))
})

test_that("filter_na_roi filters rectangular ROI with multiple boundaries", {
  data <- aniframe::aniframe(
    time = 1:5,
    x = c(0, 5, 10, 15, 20),
    y = c(0, 5, 10, 15, 20)
  )

  result <- filter_na_roi(data, x_min = 5, x_max = 15, y_min = 5, y_max = 15)

  expect_equal(result$x, c(NA, 5, 10, 15, NA))
  expect_equal(result$y, c(NA, 5, 10, 15, NA))
})

test_that("filter_na_roi handles points on rectangular boundary correctly", {
  data <- aniframe::aniframe(
    time = 1:3,
    x = c(5, 10, 15),
    y = c(5, 10, 15)
  )

  result <- filter_na_roi(data, x_min = 5, x_max = 15, y_min = 5, y_max = 15)

  # Boundary points should be included
  expect_equal(result$x, c(5, 10, 15))
  expect_equal(result$y, c(5, 10, 15))
})

test_that("filter_na_roi filters cuboid ROI with z_min", {
  data <- aniframe::aniframe(
    time = 1:4,
    x = c(10, 10, 10, 10),
    y = c(10, 10, 10, 10),
    z = c(0, 5, 10, 15),
    variables_where = c("x", "y", "z")
  )

  result <- filter_na_roi(data, z_min = 7)

  expect_equal(result$x, c(NA, NA, 10, 10))
  expect_equal(result$y, c(NA, NA, 10, 10))
  expect_equal(result$z, c(NA, NA, 10, 15))
})

test_that("filter_na_roi filters cuboid ROI with z_max", {
  data <- aniframe::aniframe(
    time = 1:4,
    x = c(10, 10, 10, 10),
    y = c(10, 10, 10, 10),
    z = c(0, 5, 10, 15),
    variables_where = c("x", "y", "z")
  )

  result <- filter_na_roi(data, z_max = 7)

  expect_equal(result$x, c(10, 10, NA, NA))
  expect_equal(result$y, c(10, 10, NA, NA))
  expect_equal(result$z, c(0, 5, NA, NA))
})

test_that("filter_na_roi filters cuboid ROI with all boundaries", {
  data <- aniframe::aniframe(
    time = 1:8,
    x = rep(c(0, 10), 4),
    y = rep(c(0, 10), each = 2, times = 2),
    z = rep(c(0, 10), each = 4),
    variables_where = c("x", "y", "z")
  )

  result <- filter_na_roi(
    data,
    x_min = 5,
    x_max = 15,
    y_min = 5,
    y_max = 15,
    z_min = 5,
    z_max = 15
  )

  # Only point (10, 10, 10) should remain
  expect_equal(sum(!is.na(result$x)), 1)
  expect_equal(result$x[!is.na(result$x)], 10)
  expect_equal(result$y[!is.na(result$y)], 10)
  expect_equal(result$z[!is.na(result$z)], 10)
})

test_that("filter_na_roi filters circular ROI correctly", {
  data <- aniframe::aniframe(
    time = 1:4,
    x = c(0, 3, 6, 9),
    y = c(0, 0, 0, 0)
  )

  result <- filter_na_roi(data, x_center = 5, y_center = 0, radius = 3)

  # Points at x=0 and x=9 are outside (distance > 3)
  # Points at x=3 and x=6 are inside
  expect_equal(result$x, c(NA, 3, 6, NA))
  expect_equal(result$y, c(NA, 0, 0, NA))
})

test_that("filter_na_roi handles circular ROI with various distances", {
  data <- aniframe::aniframe(
    time = 1:3,
    x = c(5, 8, 10),
    y = c(5, 5, 5)
  )

  # Circle centered at (5, 5) with radius 4
  result <- filter_na_roi(data, x_center = 5, y_center = 5, radius = 4)

  # (5, 5): distance = 0, inside
  # (8, 5): distance = 3, inside
  # (10, 5): distance = 5, outside
  expect_equal(result$x, c(5, 8, NA))
  expect_equal(result$y, c(5, 5, NA))
})

test_that("filter_na_roi filters spherical ROI correctly", {
  data <- aniframe::aniframe(
    time = 1:5,
    x = c(5, 5, 5, 5, 10),
    y = c(5, 5, 5, 8, 5),
    z = c(5, 8, 2, 5, 5),
    variables_where = c("x", "y", "z")
  )

  # Sphere centered at (5, 5, 5) with radius 4
  result <- filter_na_roi(
    data,
    x_center = 5,
    y_center = 5,
    z_center = 5,
    radius = 4
  )

  # (5, 5, 5): distance = 0, inside
  # (5, 5, 8): distance = 3, inside
  # (5, 5, 2): distance = 3, inside
  # (5, 8, 5): distance = 3, inside
  # (10, 5, 5): distance = 5, outside
  expect_equal(result$x, c(5, 5, 5, 5, NA))
  expect_equal(result$y, c(5, 5, 5, 8, NA))
  expect_equal(result$z, c(5, 8, 2, 5, NA))
})

test_that("filter_na_roi handles spherical ROI boundary", {
  data <- aniframe::aniframe(
    time = 1:3,
    x = c(5, 7, 9),
    y = c(5, 5, 5),
    z = c(5, 5, 5),
    variables_where = c("x", "y", "z")
  )

  # Sphere at (5, 5, 5) with radius 2
  result <- filter_na_roi(
    data,
    x_center = 5,
    y_center = 5,
    z_center = 5,
    radius = 2
  )

  # (5, 5, 5): distance = 0, inside
  # (7, 5, 5): distance = 2, on boundary (included)
  # (9, 5, 5): distance = 4, outside
  expect_equal(result$x, c(5, 7, NA))
})

test_that("filter_na_roi preserves existing NAs in rectangular ROI", {
  data <- aniframe::aniframe(
    time = 1:4,
    x = c(0, NA, 10, 15),
    y = c(0, 5, NA, 15)
  )

  result <- filter_na_roi(data, x_min = 5, x_max = 12)

  expect_equal(result$x, c(NA, NA, 10, NA))
  expect_true(is.na(result$y[2]))
  expect_true(is.na(result$y[3]))
})

test_that("filter_na_roi preserves existing NAs in circular ROI", {
  data <- aniframe::aniframe(
    time = 1:3,
    x = c(5, NA, 6),
    y = c(5, 5, NA)
  )

  result <- filter_na_roi(data, x_center = 5, y_center = 5, radius = 2)

  expect_true(is.na(result$x[2]))
  expect_true(is.na(result$y[3]))
})

test_that("filter_na_roi preserves existing NAs in 3D ROI", {
  data <- aniframe::aniframe(
    time = 1:4,
    x = c(10, NA, 10, 10),
    y = c(10, 10, NA, 10),
    z = c(10, 10, 10, NA),
    variables_where = c("x", "y", "z")
  )

  result <- filter_na_roi(data, x_min = 5)

  expect_true(is.na(result$x[2]))
  expect_true(is.na(result$y[3]))
  expect_true(is.na(result$z[4]))
})

test_that("filter_na_roi errors when no parameters provided", {
  data <- aniframe::aniframe(
    time = 1:3,
    x = c(1, 2, 3),
    y = c(1, 2, 3)
  )

  expect_error(
    filter_na_roi(data),
    "No ROI parameters provided"
  )
})

test_that("filter_na_roi errors when circular ROI parameters incomplete", {
  data <- aniframe::aniframe(
    time = 1:3,
    x = c(1, 2, 3),
    y = c(1, 2, 3)
  )

  # Only x_center provided
  expect_error(
    filter_na_roi(data, x_center = 5),
    class = "rlang_error"
  )

  # Only x_center and y_center provided
  expect_error(
    filter_na_roi(data, x_center = 5, y_center = 5),
    "radius"
  )

  # Only radius provided
  expect_error(
    filter_na_roi(data, radius = 5),
    class = "rlang_error"
  )
})

test_that("filter_na_roi errors when spherical ROI missing z_center for 3D data", {
  data <- aniframe::aniframe(
    time = 1:3,
    x = c(1, 2, 3),
    y = c(1, 2, 3),
    z = c(1, 2, 3),
    variables_where = c("x", "y", "z")
  )

  expect_error(
    filter_na_roi(data, x_center = 5, y_center = 5, radius = 3),
    "z_center.*must be provided for 3D data"
  )
})

test_that("filter_na_roi errors when z parameters used with 2D data", {
  data <- aniframe::aniframe(
    time = 1:3,
    x = c(1, 2, 3),
    y = c(1, 2, 3)
  )

  expect_error(
    filter_na_roi(data, z_min = 0),
    "Cannot use.*z_min.*with 2D data"
  )

  expect_error(
    filter_na_roi(data, x_center = 5, y_center = 5, z_center = 5, radius = 3),
    "Cannot use.*z_center.*with 2D data"
  )
})

test_that("filter_na_roi errors when mixing rectangular and circular params", {
  data <- aniframe::aniframe(
    time = 1:3,
    x = c(1, 2, 3),
    y = c(1, 2, 3)
  )

  expect_error(
    filter_na_roi(data, x_min = 0, x_center = 5, y_center = 5, radius = 3),
    "Cannot mix rectangular and circular"
  )
})

test_that("filter_na_roi validates data is an aniframe", {
  data <- data.frame(x = c(1, 2, 3), y = c(1, 2, 3))

  expect_error(
    filter_na_roi(data, x_min = 0),
    class = "rlang_error"
  )
})

test_that("filter_na_roi_rect handles each boundary independently", {
  data <- aniframe::aniframe(
    time = 1:3,
    x = c(0, 10, 20),
    y = c(0, 10, 20)
  )

  # Test x_min only
  result <- filter_na_roi_rect(
    data,
    x_min = 5,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    FALSE
  )
  expect_equal(result$x, c(NA, 10, 20))

  # Test x_max only
  result <- filter_na_roi_rect(
    data,
    NULL,
    x_max = 15,
    NULL,
    NULL,
    NULL,
    NULL,
    FALSE
  )
  expect_equal(result$x, c(0, 10, NA))

  # Test y_min only
  result <- filter_na_roi_rect(
    data,
    NULL,
    NULL,
    y_min = 5,
    NULL,
    NULL,
    NULL,
    FALSE
  )
  expect_equal(result$y, c(NA, 10, 20))

  # Test y_max only
  result <- filter_na_roi_rect(
    data,
    NULL,
    NULL,
    NULL,
    y_max = 15,
    NULL,
    NULL,
    FALSE
  )
  expect_equal(result$y, c(0, 10, NA))
})

test_that("filter_na_roi_rect handles z boundaries in 3D", {
  data <- aniframe::aniframe(
    time = 1:3,
    x = c(10, 10, 10),
    y = c(10, 10, 10),
    z = c(0, 10, 20),
    variables_where = c("x", "y", "z")
  )

  # Test z_min only
  result <- filter_na_roi_rect(
    data,
    NULL,
    NULL,
    NULL,
    NULL,
    z_min = 5,
    NULL,
    TRUE
  )
  expect_equal(result$z, c(NA, 10, 20))
  expect_equal(result$x, c(NA, 10, 10))

  # Test z_max only
  result <- filter_na_roi_rect(
    data,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    z_max = 15,
    TRUE
  )
  expect_equal(result$z, c(0, 10, NA))
  expect_equal(result$x, c(10, 10, NA))
})

test_that("filter_na_roi_sphere calculates 2D distance correctly", {
  data <- aniframe::aniframe(
    time = 1:5,
    x = c(2, 3, 5, 7, 8),
    y = c(4, 4, 4, 4, 4)
  )

  # Circle at (5, 4) with radius 2
  result <- filter_na_roi_sphere(
    data,
    x_center = 5,
    y_center = 4,
    z_center = NULL,
    radius = 2,
    has_z = FALSE
  )

  expect_equal(result$x, c(NA, 3, 5, 7, NA))
  expect_equal(result$y, c(NA, 4, 4, 4, NA))
})

test_that("filter_na_roi_sphere calculates 3D distance correctly", {
  data <- aniframe::aniframe(
    time = 1:4,
    x = c(5, 5, 5, 8),
    y = c(5, 5, 8, 5),
    z = c(5, 8, 5, 5),
    variables_where = c("x", "y", "z")
  )

  # Sphere at (5, 5, 5) with radius 2
  result <- filter_na_roi_sphere(
    data,
    x_center = 5,
    y_center = 5,
    z_center = 5,
    radius = 2,
    has_z = TRUE
  )

  # (5, 5, 5): distance = 0, inside
  # (5, 5, 8): distance = 3, outside
  # (5, 8, 5): distance = 3, outside
  # (8, 5, 5): distance = 3, outside
  expect_equal(result$x, c(5, NA, NA, NA))
})

test_that("filter_na_roi returns an aniframe", {
  data <- aniframe::aniframe(
    time = 1:3,
    x = c(1, 5, 10),
    y = c(1, 5, 10)
  )

  result <- filter_na_roi(data, x_min = 3)

  expect_s3_class(result, "aniframe")
})

test_that("filter_na_roi works with grid data", {
  data <- aniframe::aniframe(
    time = 1:9,
    x = rep(c(0, 5, 10), 3),
    y = rep(c(0, 5, 10), each = 3)
  )

  result <- filter_na_roi(data, x_min = 3, x_max = 8, y_min = 3, y_max = 8)

  # Only (5, 5) should remain
  non_na_rows <- result[!is.na(result$x) & !is.na(result$y), ]
  expect_equal(nrow(non_na_rows), 1)
  expect_equal(non_na_rows$x, 5)
  expect_equal(non_na_rows$y, 5)
})
