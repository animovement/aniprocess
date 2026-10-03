# Tests for mask_na_segment_length()
# - The reference is the structure's length, else the median per track
# - A segment is off when it exceeds both tolerance and min_difference
# - The point to blame is masked, not its neighbours
# - Individuals, sessions and trials are judged independently
# - Missing points and segments are not judged
# - Argument validation

# A pose that drifts along x without changing shape, so its lengths stay
# constant. `pose` has a `keypoint` column and one column per axis; each
# individual is scaled by `scale` and set 10 apart along y.
pose_anipoint <- function(
  pose,
  n_frames = 10,
  n_individuals = 1,
  scale = rep(1, n_individuals),
  drift = 0.1,
  confidence = TRUE
) {
  grid <- expand.grid(
    time = seq_len(n_frames),
    individual = seq_len(n_individuals),
    keypoint = pose$keypoint,
    stringsAsFactors = FALSE
  )
  at <- match(grid$keypoint, pose$keypoint)
  axes <- intersect(c("x", "y", "z"), names(pose))
  args <- list(
    individual = grid$individual,
    keypoint = grid$keypoint,
    time = grid$time
  )
  for (axis in axes) {
    args[[axis]] <- pose[[axis]][at] * scale[grid$individual]
  }
  args$x <- args$x + drift * grid$time
  args$y <- args$y + 10 * grid$individual
  if (confidence) {
    args$confidence <- rep(0.9, nrow(grid))
  }
  args$variables_what <- c("individual", "keypoint")
  args$index <- "time"
  args$variables_where <- axes
  do.call(anicore::anipoint, args)
}

# Move one point by `by` (one value per axis) at the given times.
displace <- function(data, keypoint, time, by, individual = NULL) {
  rows <- data$keypoint == keypoint & data$time %in% time
  if (!is.null(individual)) {
    rows <- rows & data$individual %in% individual
  }
  axes <- c("x", "y", "z")[seq_along(by)]
  for (i in seq_along(by)) {
    data[[axes[i]]][rows] <- data[[axes[i]]][rows] + by[i]
  }
  data
}

# Rows of `data` matching a point and times.
rows_of <- function(data, keypoint, time, individual = NULL) {
  rows <- data$keypoint %in% keypoint & data$time %in% time
  if (!is.null(individual)) {
    rows <- rows & data$individual %in% individual
  }
  rows
}

# Which rows came out masked.
masked <- function(out) is.na(out$x)

# A leg: hip, knee, ankle and toe. The toe points forward.
leg_pose <- data.frame(
  keypoint = c("hip", "knee", "ankle", "toe"),
  x = c(0, 0, 0, 1),
  y = c(4, 2, 0, 0)
)

leg_structure <- function(length = NA_real_) {
  anicore::anistructure(
    segments = data.frame(
      segment = c("thigh", "shin", "foot"),
      from = c("hip", "knee", "ankle"),
      to = c("knee", "ankle", "toe"),
      length = length
    )
  )
}

leg_anipoint <- function(..., length = NA_real_) {
  pose_anipoint(leg_pose, ...) |>
    anicore::set_structure(leg_structure(length))
}

# The pose of anicore's example structure, which spans the keypoints of
# example_anipoint().
body_pose <- data.frame(
  keypoint = c(
    "head",
    "neck",
    "shoulder_right",
    "shoulder_left",
    "abdomen",
    "hip_right",
    "hip_left",
    "knee_right",
    "knee_left",
    "foot_right",
    "foot_left"
  ),
  x = c(0, 0, 1, -1, 0, 0.5, -0.5, 0.5, -0.5, 0.5, -0.5),
  y = c(4, 3, 3, 3, 0, 0, 0, -2, -2, -4, -4),
  z = c(0, 0, 0.5, 0.5, 0, 0, 0, 0.3, 0.3, 0, 0)
)

body_anipoint <- function(n_dims = 3, ...) {
  pose <- body_pose[seq_len(n_dims + 1L)]
  pose_anipoint(pose, ...) |>
    anicore::set_structure(anicore::example_structure())
}


# Blame -------------------------------------------------------------------

test_that("only the displaced point is masked, with anicore's example structure", {
  d <- body_anipoint() |>
    displace("knee_right", 3:5, by = c(3, 0, 0))
  out <- mask_na_segment_length(d)

  expected <- rows_of(d, "knee_right", 3:5)
  expect_equal(masked(out), expected)
  expect_true(all(is.na(out$y[expected])))
  expect_true(all(is.na(out$z[expected])))
  # Everything else is untouched
  expect_equal(out$x[!expected], d$x[!expected])
  expect_equal(out$y[!expected], d$y[!expected])
  expect_equal(out$z[!expected], d$z[!expected])
})

test_that("a wrong ankle masks the ankle, not the knee and not the toe", {
  d <- leg_anipoint() |> displace("ankle", 4, by = c(0, -3))
  out <- mask_na_segment_length(d)

  expect_equal(masked(out), rows_of(d, "ankle", 4))
})

test_that("a wrong knee masks the knee, not the hip or the ankle", {
  d <- leg_anipoint() |> displace("knee", 4, by = c(3, 0))
  out <- mask_na_segment_length(d)

  expect_equal(masked(out), rows_of(d, "knee", 4))
})

test_that("a wrong end point is masked when the point at the other end is in place", {
  toe <- leg_anipoint() |> displace("toe", 4, by = c(3, 0))
  expect_equal(
    masked(mask_na_segment_length(toe)),
    rows_of(toe, "toe", 4)
  )

  hip <- leg_anipoint() |> displace("hip", 4, by = c(0, 3))
  expect_equal(
    masked(mask_na_segment_length(hip)),
    rows_of(hip, "hip", 4)
  )
})

test_that("two wrong neighbours are both masked, and the toe stays", {
  d <- leg_anipoint() |>
    displace("knee", 4, by = c(3, 0)) |>
    displace("ankle", 4, by = c(-3, -3))
  out <- mask_na_segment_length(d)

  expect_equal(masked(out), rows_of(d, c("knee", "ankle"), 4))
})

test_that("a correct point whose neighbours are all wrong goes with them", {
  # One pass: the knee's thigh and shin are both off, so it is masked with
  # the ankle. The hip is an end point whose neighbour is masked, so it
  # stays.
  d <- leg_anipoint() |>
    displace("hip", 4, by = c(0, 3)) |>
    displace("ankle", 4, by = c(0, -3))
  out <- mask_na_segment_length(d)

  expect_equal(masked(out), rows_of(d, c("knee", "ankle"), 4))
})

test_that("neither end of an isolated off segment is masked", {
  d <- leg_anipoint() |> displace("ankle", 4, by = c(0, -3))
  # With the shin alone, both its ends are end points
  out <- mask_na_segment_length(d, segments = "shin")

  expect_false(any(masked(out)))
})


# Reference length -----------------------------------------------------------

test_that("the structure's length is the reference when it is given", {
  # The data's thigh is 2 throughout; the structure says 1
  d <- leg_anipoint(length = c(1, 2, 1))
  out <- mask_na_segment_length(d)
  # The thigh is off in every frame. The knee's shin is fine, so the hip
  # is to blame.
  expect_equal(masked(out), rows_of(d, "hip", 1:10))

  # Without lengths in the structure, the median agrees with the data
  expect_false(any(masked(mask_na_segment_length(leg_anipoint()))))
})

test_that("segments without a length in the structure fall back to the median", {
  # Only the foot has a length, and it agrees with the data
  d <- leg_anipoint(length = c(NA, NA, 1)) |>
    displace("ankle", 4, by = c(0, -3))
  out <- mask_na_segment_length(d)

  expect_equal(masked(out), rows_of(d, "ankle", 4))
})

test_that("the median is taken per individual", {
  # The second individual is twice the size of the first
  d <- leg_anipoint(n_individuals = 2, scale = c(1, 2))
  expect_false(any(masked(mask_na_segment_length(d))))

  # A displacement in one individual masks only that individual's point
  d <- displace(d, "knee", 4, by = c(6, 0), individual = 2)
  out <- mask_na_segment_length(d)
  expect_equal(masked(out), rows_of(d, "knee", 4, individual = 2))
})

test_that("the median is taken per trial", {
  one <- pose_anipoint(leg_pose)
  two <- pose_anipoint(leg_pose, scale = 2)
  d <- anicore::anipoint(
    individual = c(one$individual, two$individual),
    keypoint = c(as.character(one$keypoint), as.character(two$keypoint)),
    trial = rep(1:2, c(nrow(one), nrow(two))),
    time = c(one$time, two$time),
    x = c(one$x, two$x),
    y = c(one$y, two$y),
    variables_what = c("individual", "keypoint"),
    variables_when = "trial",
    index = "time",
    variables_where = c("x", "y")
  ) |>
    anicore::set_structure(leg_structure())

  # Pooled over both trials, every segment would be a third off
  expect_false(any(masked(mask_na_segment_length(d))))
})

test_that("a structure length applies to every individual alike", {
  d <- leg_anipoint(n_individuals = 2, scale = c(1, 2), length = c(2, 2, 1))
  out <- mask_na_segment_length(d)

  # Individual 2's lengths are all double: every segment is off, and the
  # middle points are masked; the ends have no neighbour in place.
  expect_equal(
    masked(out),
    rows_of(d, c("knee", "ankle"), 1:10, individual = 2)
  )
})


# Thresholds -------------------------------------------------------------------

test_that("tolerance is relative, and a difference equal to it is not off", {
  # The foot (reference 1) is 1.5 long in frame 4: half again. No drift,
  # so the lengths are exact.
  d <- leg_anipoint(length = c(2, 2, 1), drift = 0) |>
    displace("toe", 4, by = c(0.5, 0))
  toe <- rows_of(d, "toe", 4)

  expect_equal(masked(mask_na_segment_length(d, tolerance = 0.4)), toe)
  expect_false(any(masked(mask_na_segment_length(d, tolerance = 0.5))))
  expect_false(any(masked(mask_na_segment_length(d, tolerance = 0.6))))
})

test_that("min_difference is absolute, and both thresholds must be exceeded", {
  d <- leg_anipoint(length = c(2, 2, 1), drift = 0) |>
    displace("toe", 4, by = c(0.5, 0))
  toe <- rows_of(d, "toe", 4)

  expect_equal(
    masked(mask_na_segment_length(d, min_difference = 0.49)),
    toe
  )
  # Exceeds tolerance (0.3) but not min_difference
  expect_false(any(masked(
    mask_na_segment_length(d, min_difference = 0.5)
  )))
  # Exceeds min_difference but not tolerance
  expect_false(any(masked(
    mask_na_segment_length(d, tolerance = 0.6, min_difference = 0.1)
  )))
  # tolerance = 0 leaves min_difference alone to decide
  expect_equal(
    masked(mask_na_segment_length(d, tolerance = 0, min_difference = 0.4)),
    toe
  )
})

test_that("min_difference keeps a short segment from being off", {
  pose <- data.frame(
    keypoint = c("knee", "ankle", "toe"),
    x = c(0, 0, 0.1),
    y = c(2, 0, 0)
  )
  d <- pose_anipoint(pose) |>
    anicore::set_structure(
      anicore::anistructure(
        segments = list(c("knee", "ankle"), c("ankle", "toe"))
      )
    ) |>
    displace("toe", 4, by = c(0.05, 0))
  toe <- rows_of(d, "toe", 4)

  # Half again as long, but by 0.05
  expect_equal(masked(mask_na_segment_length(d)), toe)
  expect_false(any(masked(
    mask_na_segment_length(d, min_difference = 0.1)
  )))
})


# Segments ---------------------------------------------------------------------

test_that("segments restricts the judging to the named segments", {
  d <- leg_anipoint() |> displace("toe", 4, by = c(3, 0))

  # The toe is in no selected segment, so it is left alone
  expect_false(any(masked(
    mask_na_segment_length(d, segments = c("thigh", "shin"))
  )))
  expect_equal(
    masked(mask_na_segment_length(d, segments = c("shin", "foot"))),
    rows_of(d, "toe", 4)
  )
})

test_that("with fewer segments, a point can become an end point", {
  d <- leg_anipoint() |> displace("ankle", 4, by = c(0, -3))

  # Without the foot, the ankle has only the shin; the knee's thigh is fine
  expect_equal(
    masked(mask_na_segment_length(d, segments = c("thigh", "shin"))),
    rows_of(d, "ankle", 4)
  )
  # Repeated names count once
  expect_equal(
    mask_na_segment_length(d, segments = c("thigh", "shin", "shin")),
    mask_na_segment_length(d, segments = c("thigh", "shin"))
  )
})


# Dimensions -------------------------------------------------------------------

test_that("2D frames are judged in the plane", {
  d <- body_anipoint(n_dims = 2) |>
    displace("foot_left", 7:8, by = c(0, -3))
  out <- mask_na_segment_length(d)

  expect_equal(masked(out), rows_of(d, "foot_left", 7:8))
  expect_true(all(is.na(out$y[masked(out)])))
})

test_that("3D frames are judged in space", {
  # A displacement along z alone
  d <- body_anipoint(n_dims = 3) |>
    displace("neck", 2, by = c(0, 0, 4))
  out <- mask_na_segment_length(d)

  expect_equal(masked(out), rows_of(d, "neck", 2))
  expect_true(all(is.na(out$z[masked(out)])))
})


# Missing values ---------------------------------------------------------------

test_that("a point that is already NA is not judged, and its neighbours lose a segment", {
  # The toe is missing in frame 4, so the ankle has only its shin there,
  # and the knee's thigh shows the knee is in place
  d <- leg_anipoint() |> displace("ankle", 4, by = c(0, -3))
  toe <- rows_of(d, "toe", 4)
  d$x[toe] <- NA
  d$y[toe] <- NA
  out <- mask_na_segment_length(d)

  expect_equal(masked(out), rows_of(d, c("ankle", "toe"), 4))
  expect_equal(out$confidence[toe], d$confidence[toe])
})

test_that("a point missing in one axis is not judged and is left as it is", {
  d <- leg_anipoint()
  knee <- rows_of(d, "knee", 4)
  d$x[knee] <- NA
  out <- mask_na_segment_length(d)

  expect_equal(out$y, d$y)
  expect_equal(out$x, d$x)
})

test_that("a point with no row in a frame counts as missing", {
  d <- leg_anipoint() |> displace("ankle", 4, by = c(0, -3))
  d <- d[!rows_of(d, "toe", 4), ]
  out <- mask_na_segment_length(d)

  expect_equal(masked(out), rows_of(d, "ankle", 4))
})

test_that("a missing point can leave an off segment with no one to blame", {
  # The knee is missing, so the shin is unmeasured, and the ankle and toe
  # share only the foot
  d <- leg_anipoint() |> displace("ankle", 4, by = c(0, -3))
  knee <- rows_of(d, "knee", 4)
  d$x[knee] <- NA
  d$y[knee] <- NA
  out <- mask_na_segment_length(d)

  expect_equal(masked(out), knee)
})

test_that("a segment with no reference is not judged", {
  # The toe is never present, and the structure gives no length for the
  # foot. The ankle has only the shin.
  d <- leg_anipoint() |> displace("ankle", 4, by = c(0, -3))
  d$x[d$keypoint == "toe"] <- NA
  out <- mask_na_segment_length(d)

  expect_equal(masked(out), rows_of(d, "ankle", 4) | is.na(d$x))
})

test_that("a segment whose median length is zero is not judged", {
  # The heel sits on the ankle in most frames
  pose <- data.frame(
    keypoint = c("knee", "ankle", "heel"),
    x = c(0, 0, 0),
    y = c(2, 0, 0)
  )
  d <- pose_anipoint(pose) |>
    anicore::set_structure(
      anicore::anistructure(
        segments = list(c("knee", "ankle"), c("ankle", "heel"))
      )
    ) |>
    displace("heel", 4, by = c(0.5, 0))

  expect_false(any(masked(mask_na_segment_length(d))))
})


# What is masked and kept ------------------------------------------------------

test_that("confidence is blanked on masked rows only", {
  d <- leg_anipoint() |> displace("ankle", 4, by = c(0, -3))
  out <- mask_na_segment_length(d)
  ankle <- rows_of(d, "ankle", 4)

  expect_true(all(is.na(out$confidence[ankle])))
  expect_equal(out$confidence[!ankle], d$confidence[!ankle])
})

test_that("a frame without confidence is masked all the same", {
  d <- pose_anipoint(leg_pose, confidence = FALSE) |>
    anicore::set_structure(leg_structure()) |>
    displace("ankle", 4, by = c(0, -3))
  out <- mask_na_segment_length(d)

  expect_equal(masked(out), rows_of(d, "ankle", 4))
  expect_false("confidence" %in% names(out))
})

test_that("keypoints outside the structure are left alone", {
  pose <- rbind(leg_pose, data.frame(keypoint = "tail", x = 5, y = 5))
  d <- pose_anipoint(pose) |>
    anicore::set_structure(leg_structure()) |>
    displace("tail", 4, by = c(30, 30)) |>
    displace("ankle", 4, by = c(0, -3))
  out <- mask_na_segment_length(d)

  expect_equal(masked(out), rows_of(d, "ankle", 4))
})

test_that("the frame's class, metadata, grouping and row order are kept", {
  d <- leg_anipoint(n_individuals = 2) |>
    displace("ankle", 4, by = c(0, -3)) |>
    dplyr::arrange(dplyr::desc(time))
  out <- mask_na_segment_length(d)

  expect_s3_class(out, "anipoint")
  expect_identical(class(out), class(d))
  expect_identical(anicore::get_metadata(out), anicore::get_metadata(d))
  expect_identical(dplyr::group_vars(out), dplyr::group_vars(d))
  expect_equal(out$time, d$time)
  expect_equal(out$keypoint, d$keypoint)
  expect_equal(masked(out), rows_of(d, "ankle", 4))
})

test_that("nothing off returns the frame unchanged", {
  d <- leg_anipoint()
  expect_identical(mask_na_segment_length(d), d)
})

test_that("a structure over another variable is judged the same way", {
  # Three players holding a triangle; the third runs off in frame 4
  d <- anicore::anipoint(
    player = rep(c("a", "b", "c"), each = 6),
    time = rep(1:6, 3),
    x = rep(c(0, 4, 0), each = 6),
    y = rep(c(0, 0, 3), each = 6),
    variables_what = "player",
    index = "time",
    variables_where = c("x", "y")
  ) |>
    anicore::set_structure(
      anicore::anistructure(
        segments = list(c("a", "b"), c("b", "c"), c("c", "a"))
      ),
      variable = "player",
      name = "team"
    )
  rows <- d$player == "c" & d$time == 4
  d$y[rows] <- 20
  out <- mask_na_segment_length(d)

  expect_equal(is.na(out$x), rows)
})


# Structures -------------------------------------------------------------------

test_that("a frame without a structure errors", {
  d <- pose_anipoint(leg_pose)
  expect_error(mask_na_segment_length(d), "has no structure with segments")

  points_only <- anicore::set_structure(
    d,
    anicore::anistructure(points = leg_pose$keypoint)
  )
  expect_error(
    mask_na_segment_length(points_only),
    "has no structure with segments"
  )
  expect_error(
    mask_na_segment_length(d, structure = "keypoint"),
    "no structures"
  )
})

test_that("several structures with segments need one named", {
  d <- leg_anipoint() |>
    anicore::set_structure(
      anicore::anistructure(segments = list(c("hip", "ankle"))),
      name = "reach"
    ) |>
    displace("ankle", 4, by = c(0, -3))

  expect_error(mask_na_segment_length(d), "several structures")
  expect_equal(
    masked(mask_na_segment_length(d, structure = "keypoint")),
    rows_of(d, "ankle", 4)
  )
  # Judged by the reach alone, hip and ankle share one segment
  expect_false(any(masked(mask_na_segment_length(d, structure = "reach"))))
})

test_that("a structure without segments is skipped when choosing one", {
  d <- leg_anipoint() |>
    anicore::set_structure(
      anicore::anistructure(points = c("hip", "knee")),
      name = "upper"
    ) |>
    displace("ankle", 4, by = c(0, -3))

  expect_equal(
    masked(mask_na_segment_length(d)),
    rows_of(d, "ankle", 4)
  )
  expect_error(
    mask_na_segment_length(d, structure = "upper"),
    "has no segments"
  )
})

test_that("structure must name a known structure", {
  d <- leg_anipoint()
  expect_error(
    mask_na_segment_length(d, structure = "skeleton"),
    "no structure named"
  )
  expect_error(mask_na_segment_length(d, structure = 1), "single string")
  expect_error(
    mask_na_segment_length(d, structure = c("keypoint", "keypoint")),
    "single string"
  )
  expect_error(
    mask_na_segment_length(d, structure = NA_character_),
    "single string"
  )
})


# Validation -------------------------------------------------------------------

test_that("data must be a 2D or 3D Cartesian anipoint", {
  d <- leg_anipoint()
  expect_error(
    mask_na_segment_length(as.data.frame(d)),
    "must be an anipoint"
  )
  expect_error(
    mask_na_segment_length(data.frame(x = 1:3, y = 1:3)),
    "must be an anipoint"
  )

  one_d <- anicore::example_anipoint(n_obs = 3, n_individuals = 1, n_dims = 1)
  expect_error(
    mask_na_segment_length(one_d),
    "2D or 3D Cartesian"
  )
})

test_that("tolerance and min_difference must be single non-negative numbers", {
  d <- leg_anipoint()
  for (bad in list(-0.1, NA_real_, Inf, c(0.1, 0.2), "0.3", NULL)) {
    expect_error(
      mask_na_segment_length(d, tolerance = bad),
      "tolerance.*single non-negative number"
    )
    expect_error(
      mask_na_segment_length(d, min_difference = bad),
      "min_difference.*single non-negative number"
    )
  }
})

test_that("segments must name segments of the structure", {
  d <- leg_anipoint()
  expect_error(
    mask_na_segment_length(d, segments = c("shin", "neck")),
    "has no segment"
  )
  expect_error(
    mask_na_segment_length(d, segments = character(0)),
    "character vector of segment names"
  )
  expect_error(
    mask_na_segment_length(d, segments = 1),
    "character vector of segment names"
  )
  expect_error(
    mask_na_segment_length(d, segments = c("shin", NA)),
    "character vector of segment names"
  )
})
