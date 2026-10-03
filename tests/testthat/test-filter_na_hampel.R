# Tests for filter_na_hampel()
# - Agrees with a direct, row-by-row implementation of the definition
# - Masks spikes; leaves smooth motion, fast or slow, alone
# - The threshold follows the local motion, unlike a speed threshold
# - Masks every axis of a flagged point
# - min_distance floors the threshold
# - window_width and k
# - Missing values, the majority rule and the series edges
# - 1, 2 and 3 coordinate columns
# - Through filter_na_across() and filter_na_with()
# - Argument validation

# A direct transcription of the documented rule, one row at a time, to
# check the vectorised implementation against.
hampel_reference <- function(
  coords,
  window_width = 5,
  k = 3,
  min_distance = 0
) {
  p <- as.matrix(coords)
  n <- nrow(p)
  half <- (window_width - 1) %/% 2
  complete <- stats::complete.cases(p)
  flagged <- rep(FALSE, n)
  for (i in seq_len(n)) {
    if (!complete[i]) {
      next
    }
    rows <- max(1, i - half):min(n, i + half)
    rows <- rows[complete[rows]]
    if (length(rows) < half + 1) {
      next
    }
    window <- p[rows, , drop = FALSE]
    centre <- apply(window, 2, stats::median)
    dist <- sqrt(rowSums(sweep(window, 2, centre)^2))
    deviation <- sqrt(sum((p[i, ] - centre)^2))
    spread <- 1.4826 * stats::median(dist)
    flagged[i] <- deviation > max(k * spread, min_distance)
  }
  flagged
}

masked_rows <- function(out) which(is.na(out[[1]]))

# --- the definition ---------------------------------------------------------

test_that("filter_na_hampel agrees with a row-by-row implementation", {
  set.seed(90)
  for (dims in 1:3) {
    for (window_width in c(3, 5, 7, 11)) {
      n <- 120
      coords <- as.data.frame(
        matrix(cumsum(rnorm(n * dims)), ncol = dims)
      )
      spikes <- sample(n, 8)
      coords[spikes, ] <- coords[spikes, ] + rnorm(8 * dims, sd = 15)
      # Missing values, whole rows and single axes
      coords[sample(n, 10), ] <- NA
      coords[sample(n, 5), 1] <- NA

      for (k in c(0, 2, 3)) {
        for (min_distance in c(0, 1)) {
          expected <- hampel_reference(coords, window_width, k, min_distance)
          out <- filter_na_hampel(
            coords,
            window_width = window_width,
            k = k,
            min_distance = min_distance
          )
          info <- paste(dims, window_width, k, min_distance)
          expect_equal(
            hampel_mask(coords, window_width, k, min_distance),
            expected,
            info = info
          )
          # Masked rows are blank in every axis; others are untouched
          expect_true(all(is.na(as.matrix(out[expected, ]))), info = info)
          expect_equal(out[!expected, ], coords[!expected, ], info = info)
        }
      }
    }
  }
})

test_that("with one column it is Pearson's Hampel identifier", {
  # Worked by hand: window 3:7 holds 3, 4, 50, 6, 7; its median is 6, and
  # the distances from it are 3, 2, 44, 0, 1, so the MAD is 2.
  coords <- data.frame(x = c(1, 2, 3, 4, 50, 6, 7, 8, 9))
  deviation <- 44
  threshold <- 3 * 1.4826 * 2
  expect_gt(deviation, threshold)

  out <- filter_na_hampel(coords)
  expect_equal(masked_rows(out), 5L)
  expect_equal(out$x[-5], coords$x[-5])
})

# --- what it masks, and what it does not ------------------------------------

test_that("smooth motion is never masked, however fast", {
  for (step in c(0.01, 1, 1e3)) {
    tt <- 1:200
    coords <- data.frame(
      x = step * tt,
      y = step * 20 * sin(tt / 10),
      z = step * tt^2 / 100
    )
    expect_equal(filter_na_hampel(coords), coords, info = step)
  }
})

test_that("the threshold scales with the local motion", {
  # On steady motion with step v, a spike at right angles to it is masked
  # once it exceeds 3 * 1.4826 * 2v (the spike itself is one of the larger
  # distances in its window, so the MAD is 2v).
  for (v in c(1, 10)) {
    spike_at <- function(size) {
      data.frame(x = v * (0:20), y = replace(rep(0, 21), 11, size))
    }
    threshold <- 3 * 1.4826 * 2 * v
    expect_equal(
      masked_rows(filter_na_hampel(spike_at(0.95 * threshold))),
      integer(0),
      info = v
    )
    expect_equal(
      masked_rows(filter_na_hampel(spike_at(1.05 * threshold))),
      11L,
      info = v
    )
  }
})

test_that("a spike on a slow stretch is masked; a fast stretch is not", {
  # Along the diagonal, one unit per frame and then twenty. The spike is 15
  # units, at right angles -- smaller than a single step of the fast stretch.
  along <- c(0:29, 29 + 20 * (1:30)) / sqrt(2)
  coords <- data.frame(x = along, y = along)
  coords[15, ] <- coords[15, ] + c(15, -15) / sqrt(2)

  expect_equal(masked_rows(filter_na_hampel(coords)), 15L)

  # No speed threshold separates the two: low enough to take the spike,
  # it takes the fast stretch too; high enough to spare the fast stretch,
  # it misses the spike.
  time <- seq_len(nrow(coords))
  low <- masked_rows(filter_na_speed(coords, threshold = 14, time = time))
  expect_true(15L %in% low)
  expect_true(all(31:60 %in% low))
  high <- masked_rows(filter_na_speed(coords, threshold = 21, time = time))
  expect_false(15L %in% high)

  # The excursion criterion's sigma is the spread of the whole track, which
  # the fast stretch makes far larger than the spike.
  expect_false(15L %in% masked_rows(filter_na_excursion(coords)))
  expect_false(
    15L %in% masked_rows(filter_na_excursion(coords, by_axis = FALSE))
  )
})

test_that("a noisy track keeps its noise and loses its spikes", {
  set.seed(1)
  n <- 300
  tt <- seq_len(n)
  truth <- data.frame(x = 10 * sin(tt / 15), y = 6 * cos(tt / 25))
  coords <- truth + rnorm(2 * n, sd = 0.1)
  spikes <- c(40, 90, 150, 220, 280)
  coords[spikes, "x"] <- coords[spikes, "x"] + 25

  # A floor a few noise-widths wide keeps the noise
  out <- filter_na_hampel(coords, min_distance = 1)
  expect_equal(masked_rows(out), spikes)
})

test_that("a flagged point is masked in every axis", {
  coords <- data.frame(
    x = as.numeric(1:9),
    y = as.numeric(1:9),
    z = as.numeric(1:9)
  )
  # The spike is in z alone
  coords$z[5] <- 100

  out <- filter_na_hampel(coords)
  expect_true(all(is.na(unlist(out[5, ]))))
  expect_false(anyNA(out[-5, ]))
})

test_that("runs of spikes are caught up to half the window", {
  base <- rep(0, 21)

  # Two in a window of five: still the minority
  two <- data.frame(x = replace(base, 10:11, 100))
  expect_equal(masked_rows(filter_na_hampel(two)), 10:11)

  # Three are the majority, and become the median
  three <- data.frame(x = replace(base, 10:12, 100))
  expect_equal(masked_rows(filter_na_hampel(three)), integer(0))

  # A wider window catches the longer run
  expect_equal(
    masked_rows(filter_na_hampel(three, window_width = 7)),
    10:12
  )
})

# --- min_distance and k -----------------------------------------------------

test_that("min_distance keeps the noise of a keypoint that barely moves", {
  # Most of each window is identical, so its MAD is zero and any deviation
  # at all exceeds k of it.
  still <- data.frame(
    x = c(5, 5, 5.01, 5, 5, 5, 4.99, 5),
    y = 2
  )
  expect_equal(masked_rows(filter_na_hampel(still)), c(3L, 7L))
  expect_equal(filter_na_hampel(still, min_distance = 0.05), still)

  # The floor is on the threshold itself, not on the spread: a deviation of
  # 0.01 is masked under a floor of 0.009 and kept under one of 0.011.
  expect_equal(
    masked_rows(filter_na_hampel(still, min_distance = 0.009)),
    c(3L, 7L)
  )
  expect_equal(
    masked_rows(filter_na_hampel(still, min_distance = 0.011)),
    integer(0)
  )
})

test_that("min_distance does not spare a real spike", {
  coords <- data.frame(x = c(rep(5, 4), 50, rep(5, 4)))
  expect_equal(masked_rows(filter_na_hampel(coords, min_distance = 1)), 5L)
})

test_that("a constant track is never masked", {
  coords <- data.frame(x = rep(3, 10), y = rep(-1, 10))
  expect_equal(filter_na_hampel(coords), coords)
})

test_that("k sets how many robust deviations a point may lie away", {
  # Window 3:7 holds 3, 4, 9, 6, 7: median 6, distances 3, 2, 3, 0, 1, so
  # the MAD is 2 and row 5 lies 3 / (1.4826 * 2) = 1.01 deviations out.
  coords <- data.frame(x = c(1, 2, 3, 4, 9, 6, 7, 8, 9))
  expect_true(5L %in% masked_rows(filter_na_hampel(coords, k = 1)))
  expect_false(5L %in% masked_rows(filter_na_hampel(coords, k = 1.1)))
  expect_false(5L %in% masked_rows(filter_na_hampel(coords)))

  # k = 0 masks any point off its median by more than min_distance
  expect_equal(
    masked_rows(filter_na_hampel(coords, k = 0, min_distance = 2.5)),
    5L
  )
})

test_that("window_width sets the neighbourhood", {
  # Two spikes in a row are the majority of a window of three, but not of
  # one of five
  two <- data.frame(x = replace(rep(0, 21), 10:11, 100))
  expect_equal(
    masked_rows(filter_na_hampel(two, window_width = 3)),
    integer(0)
  )
  expect_equal(masked_rows(filter_na_hampel(two, window_width = 5)), 10:11)
})

# --- missing values and edges -----------------------------------------------

test_that("existing NAs are kept, and do not spread", {
  coords <- data.frame(x = as.numeric(1:12), y = as.numeric(1:12))
  coords[4, ] <- NA
  out <- filter_na_hampel(coords)
  expect_equal(out, coords)
})

test_that("a row missing one axis is neither judged nor used to judge", {
  coords <- data.frame(
    x = c(0, 0, 0, 0, 0, 0, 0),
    y = c(0, 0, 0, 0, 0, 0, 0)
  )
  # Row 4 lacks y but is wildly off in x: not a point, so left as it is
  coords$x[4] <- 1000
  coords$y[4] <- NA
  out <- filter_na_hampel(coords)
  expect_equal(out, coords)

  # Nor does it count towards the majority of its neighbours' windows. Row 4
  # is judged on rows 3 to 5 ...
  sparse <- data.frame(
    x = c(NA, NA, 0, 50, 0, NA, NA),
    y = c(NA, NA, 0, 0, 0, NA, NA)
  )
  expect_true(is.na(filter_na_hampel(sparse)$x[4]))
  # ... but not once row 3 has lost an axis, leaving two of five
  sparse$x[3] <- NA
  expect_equal(filter_na_hampel(sparse), sparse)
})

test_that("a row is judged only when most of its window is observed", {
  # Window of five around row 5: three observed is a majority ...
  three <- data.frame(x = c(0, 0, NA, 0, 50, NA, 0, 0, 0))
  expect_true(5L %in% masked_rows(filter_na_hampel(three)))

  # ... two is not, and the spike is left alone
  two <- data.frame(x = c(0, 0, NA, NA, 50, NA, 0, 0, 0))
  expect_equal(filter_na_hampel(two), two)
})

test_that("the first and last rows are judged on the window that exists", {
  first <- data.frame(x = c(100, 1, 1, 1, 1, 1))
  expect_equal(masked_rows(filter_na_hampel(first)), 1L)

  last <- data.frame(x = c(1, 1, 1, 1, 1, 100))
  expect_equal(masked_rows(filter_na_hampel(last)), 6L)

  # Beyond the series counts as missing: with row 2 gone too, row 1 has only
  # two of the three it needs
  gap <- data.frame(x = c(100, NA, 1, 1, 1, 1))
  expect_false(is.na(filter_na_hampel(gap)$x[1]))
})

test_that("short and empty inputs come back unchanged", {
  empty <- data.frame(x = numeric(0), y = numeric(0))
  expect_equal(filter_na_hampel(empty), empty)

  # Fewer rows than a majority of the window: nothing can be judged
  expect_equal(filter_na_hampel(data.frame(x = 1)), data.frame(x = 1))
  expect_equal(
    filter_na_hampel(data.frame(x = c(1, 100))),
    data.frame(x = c(1, 100))
  )
  all_na <- data.frame(x = rep(NA_real_, 6), y = rep(NA_real_, 6))
  expect_equal(filter_na_hampel(all_na), all_na)
})

# --- dimensions and shapes --------------------------------------------------

test_that("one, two and three coordinate columns all work", {
  base <- c(0, 1, 2, 3, 30, 5, 6, 7, 8)
  one <- data.frame(x = base)
  two <- data.frame(x = base, y = 0:8)
  three <- data.frame(x = base, y = 0:8, z = 8:0)

  for (coords in list(one, two, three)) {
    out <- filter_na_hampel(coords)
    expect_equal(names(out), names(coords))
    expect_equal(masked_rows(out), 5L, info = ncol(coords))
  }
})

test_that("integer columns and tibbles are accepted", {
  coords <- dplyr::tibble(x = c(1L, 1L, 1L, 1L, 100L, 1L), y = 1L)
  out <- filter_na_hampel(coords)
  expect_s3_class(out, "tbl_df")
  expect_equal(masked_rows(out), 5L)
})

test_that("row_median ignores NA and returns NA for an empty row", {
  m <- matrix(
    c(3, 1, NA, 2, NA, NA, NA, NA, 5, 4, 1, 2, 7, NA, 1, NA),
    nrow = 4,
    byrow = TRUE
  )
  expect_equal(row_median(m), c(2, NA, 3, 4))

  set.seed(5)
  m <- matrix(rnorm(500), ncol = 5)
  m[sample(length(m), 100)] <- NA
  expected <- apply(m, 1, function(r) {
    if (all(is.na(r))) NA_real_ else stats::median(r, na.rm = TRUE)
  })
  expect_equal(row_median(m), expected)
})

# --- through the generics ---------------------------------------------------

hampel_fixture <- function() {
  anicore::anipoint(
    time = 1:12,
    x = c(0, 1, 2, 3, 4, 5, 6, 26, 46, 66, 86, 106),
    y = c(0, 0, 0, 15, 0, 0, 0, 0, 0, 0, 0, 0),
    confidence = rep(0.9, 12)
  )
}

test_that("filter_na_across(method = 'hampel') masks the declared position", {
  d <- hampel_fixture()
  out <- filter_na_across(d, "hampel")

  expect_s3_class(out, "anipoint")
  expect_equal(which(is.na(out$x)), 4L)
  expect_equal(which(is.na(out$y)), 4L)
  # confidence is blanked on the masked row only
  expect_equal(which(is.na(out$confidence)), 4L)
  # time is not a coordinate, and is left alone
  expect_equal(out$time, d$time)

  # Arguments reach filter_na_hampel()
  expect_equal(
    which(is.na(filter_na_across(d, "hampel", min_distance = 20)$x)),
    integer(0)
  )
})

test_that("filter_na_across(method = 'hampel') works in three dimensions", {
  d <- anicore::anipoint(
    time = 1:9,
    x = as.numeric(1:9),
    y = as.numeric(1:9),
    z = c(1, 2, 3, 4, 100, 6, 7, 8, 9),
    variables_where = c("x", "y", "z")
  )
  out <- filter_na_across(d, "hampel")

  expect_equal(which(is.na(out$x)), 5L)
  expect_equal(which(is.na(out$y)), 5L)
  expect_equal(which(is.na(out$z)), 5L)
})

test_that("filter_na_across(method = 'hampel') respects variables", {
  d <- hampel_fixture()
  # Judged on x alone, the spike in y is invisible
  out <- filter_na_across(d, "hampel", variables = x)
  expect_false(anyNA(out$x))
  expect_equal(out$y, d$y)
})

test_that("filter_na_across(method = 'hampel') never spans a track boundary", {
  # Track "a" ends on a spike. Within the track, the last window is 0, 0,
  # 100 and the spike stands out; spanning into "b" (all 100) it would be the
  # median.
  d <- anicore::anipoint(
    time = rep(1:10, 2),
    individual = rep(c("a", "b"), each = 10),
    x = c(rep(0, 9), 100, rep(100, 10)),
    y = rep(0, 20),
    variables_what = "individual"
  )
  expect_equal(dplyr::group_vars(d), "individual")

  expect_equal(which(is.na(filter_na_across(d, "hampel")$x)), 10L)
  # The same rows as one track
  stacked <- data.frame(x = d$x, y = d$y)
  expect_equal(filter_na_hampel(stacked), stacked)
})

test_that("filter_na_with(method = 'hampel') matches the function", {
  coords <- data.frame(
    x = c(0, 1, 2, 3, 4, 5, 6, 26, 46, 66, 86, 106),
    y = c(0, 0, 0, 15, 0, 0, 0, 0, 0, 0, 0, 0)
  )
  expect_equal(
    filter_na_with(coords, "hampel"),
    filter_na_hampel(coords)
  )
  expect_equal(
    filter_na_with(coords, "hampel", window_width = 3, k = 2, min_distance = 1),
    filter_na_hampel(coords, window_width = 3, k = 2, min_distance = 1)
  )
})

test_that("filter_na_hampel works inside a grouped mutate", {
  d <- data.frame(
    id = rep(c("a", "b"), each = 9),
    x = c(0, 1, 2, 3, 40, 5, 6, 7, 8, 0, 1, 2, 3, 4, 5, 6, 7, 8),
    y = 0
  )
  out <- d |>
    dplyr::group_by(id) |>
    dplyr::mutate(filter_na_hampel(dplyr::pick("x", "y")))
  expect_equal(which(is.na(out$x)), 5L)
  expect_equal(out$id, d$id)
})

# --- validation ---------------------------------------------------------------

test_that("filter_na_hampel validates data", {
  expect_error(filter_na_hampel(1:10), "aniframe or a data frame")
  expect_error(filter_na_hampel(data.frame()), "has no columns")
  expect_error(
    filter_na_hampel(data.frame(x = 1:3, id = c("a", "b", "c"))),
    "must be numeric"
  )
  expect_error(
    filter_na_hampel(hampel_fixture()),
    "filter_na_across"
  )
})

test_that("filter_na_hampel validates window_width", {
  coords <- data.frame(x = 1:10)
  for (bad in list(4, 1, 2.5, -3, Inf, NA, NA_real_, "5", c(3, 5), NULL)) {
    expect_error(
      filter_na_hampel(coords, window_width = bad),
      "odd whole number of at least 3",
      info = deparse(bad)
    )
  }
  expect_no_error(filter_na_hampel(coords, window_width = 3L))
})

test_that("filter_na_hampel validates k and min_distance", {
  coords <- data.frame(x = 1:10)
  for (bad in list(-1, NA, NA_real_, Inf, "3", c(1, 2), NULL)) {
    expect_error(
      filter_na_hampel(coords, k = bad),
      "`k` must be a single non-negative number",
      info = deparse(bad)
    )
    expect_error(
      filter_na_hampel(coords, min_distance = bad),
      "`min_distance` must be a single non-negative number",
      info = deparse(bad)
    )
  }
  expect_no_error(filter_na_hampel(coords, k = 0, min_distance = 0))
})
