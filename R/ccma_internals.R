#' Construct a CCMA kernel of the given odd width.
#'
#' @param width Odd integer kernel width.
#' @param type Either `"hanning"` or `"uniform"`.
#'
#' @return Numeric vector of length `width`, summing to 1.
#' @keywords internal
ccma_kernel <- function(width, type) {
  switch(
    type,
    uniform = rep(1 / width, width),
    hanning = {
      ext <- width + 2L
      h <- 0.5 * (1 - cos(2 * pi * seq.int(0, ext - 1) / (ext - 1)))
      h <- h[2:(ext - 1)]
      h / sum(h)
    },
    cli::cli_abort("Unknown kernel type {.val {type}}.")
  )
}


#' Per-column valid-mode correlation (kernel symmetry assumed).
#'
#' Output length = `nrow(P) - length(weights) + 1`.
#'
#' @param P Numeric matrix.
#' @param weights Numeric vector (kernel).
#'
#' @return Numeric matrix with the same number of columns as `P`.
#' @keywords internal
ccma_convolve_valid <- function(P, weights) {
  apply(P, 2, function(col) stats::convolve(col, weights, type = "filter"))
}


#' 3D cross product.
#'
#' @param a,b Numeric vectors of length 3.
#' @return Numeric vector of length 3.
#' @keywords internal
ccma_cross <- function(a, b) {
  c(
    a[2] * b[3] - a[3] * b[2],
    a[3] * b[1] - a[1] * b[3],
    a[1] * b[2] - a[2] * b[1]
  )
}


#' Apply CCMA to a single trajectory.
#'
#' Operates on the `n × d` coordinate matrix of one group. Lifts 2D to 3D
#' internally; the original returns 2D output for 2D input. Boundary mode
#' `"padding"` extends endpoints so that output length equals input length.
#'
#' @param P Numeric matrix `n × d` with `d %in% c(2, 3)`.
#' @param w_ma Half-width of the moving-average kernel.
#' @param w_cc Half-width of the curvature-correction kernel.
#' @param kernel One of `"hanning"`, `"uniform"`.
#' @param boundary Currently only `"padding"`.
#' @param cc_mode If `FALSE`, return the moving-average result without
#'   curvature correction.
#'
#' @return Numeric matrix the same shape as `P`.
#' @keywords internal
ccma_apply <- function(P, w_ma, w_cc, kernel, boundary, cc_mode) {
  n <- nrow(P)
  d <- ncol(P)

  if (n < 3L) {
    return(P)
  }

  is_2d <- d == 2L
  if (is_2d) {
    P <- cbind(P, 0)
  }

  pad <- w_ma + w_cc + 1L
  P_pad <- rbind(
    matrix(rep(P[1, ], pad), ncol = 3L, byrow = TRUE),
    P,
    matrix(rep(P[n, ], pad), ncol = 3L, byrow = TRUE)
  )

  weights_ma <- ccma_kernel(2L * w_ma + 1L, kernel)

  P_ma <- ccma_convolve_valid(P_pad, weights_ma)

  if (!cc_mode) {
    keep <- (w_cc + 2L):(nrow(P_ma) - w_cc - 1L)
    out <- P_ma[keep, , drop = FALSE]
  } else {
    weights_cc <- ccma_kernel(2L * w_cc + 1L, kernel)
    out <- ccma_correct(P_ma, w_ma, w_cc, weights_ma, weights_cc)
  }

  if (is_2d) {
    out <- out[, 1:2, drop = FALSE]
  }
  out
}


#' Curvature-correction reconstruction step.
#'
#' Implements steps 2–5 of the CCMA algorithm: compute curvature vectors,
#' alpha angles, normalised MA radii, and shift each MA point outward to
#' undo the corner-cutting bias.
#'
#' @param P_ma Moving-average-smoothed trajectory (matrix, 3 columns).
#' @param w_ma,w_cc Half-widths of the MA and CC kernels.
#' @param weights_ma,weights_cc Kernel weight vectors.
#'
#' @return Corrected trajectory (matrix, 3 columns) with
#'   `nrow = nrow(P_ma) - 2 * (w_ma + w_cc + 1)` rows.
#' @keywords internal
ccma_correct <- function(P_ma, w_ma, w_cc, weights_ma, weights_cc) {
  N <- nrow(P_ma)

  # Curvature vectors per interior point (1 and N stay zero).
  curvature_vectors <- matrix(0, N, 3)
  for (i in seq.int(2L, N - 1L)) {
    v1 <- P_ma[i, ] - P_ma[i - 1L, ]
    v2 <- P_ma[i + 1L, ] - P_ma[i, ]
    cross_v <- ccma_cross(v1, v2)
    cross_norm <- sqrt(sum(cross_v^2))
    if (cross_norm > 0) {
      v1_norm <- sqrt(sum(v1^2))
      v2_norm <- sqrt(sum(v2^2))
      d_norm <- sqrt(sum((P_ma[i + 1L, ] - P_ma[i - 1L, ])^2))
      R <- (v1_norm * v2_norm * d_norm) / (2 * cross_norm)
      kappa <- 1 / R
      curvature_vectors[i, ] <- kappa * cross_v / cross_norm
    }
  }
  curvatures <- sqrt(rowSums(curvature_vectors^2))

  # Alpha angles.
  alphas <- numeric(N)
  for (i in seq.int(2L, N - 1L)) {
    if (curvatures[i] > 0) {
      R <- 1 / curvatures[i]
      d_neighbor <- sqrt(sum((P_ma[i + 1L, ] - P_ma[i - 1L, ])^2))
      arg <- (d_neighbor / 2) / R
      arg <- max(-1, min(1, arg))
      alphas[i] <- asin(arg)
    }
  }

  # Normalised MA radii.
  central <- weights_ma[w_ma + 1L]
  radii_ma <- numeric(N)
  for (i in seq.int(2L, N - 1L)) {
    r <- central
    if (w_ma > 0L) {
      for (k in seq_len(w_ma)) {
        r <- r + 2 * cos(alphas[i] * k) * weights_ma[w_ma + 1L + k]
      }
    }
    radii_ma[i] <- max(0.35, r)
  }

  # Reconstruction. The output length is the number of *original* padded
  # input rows minus 2*w_ccma. P_ma was already trimmed by the MA convolution
  # (lost 2*w_ma rows), so out_n = N - 2*(w_cc + 1).
  out_n <- N - 2L * (w_cc + 1L)
  out <- matrix(0, out_n, 3L)
  for (idx in seq_len(out_n)) {
    centre <- idx + w_cc + 1L
    tangent <- P_ma[centre + 1L, ] - P_ma[centre - 1L, ]
    tan_norm <- sqrt(sum(tangent^2))
    if (tan_norm > 0) {
      tangent <- tangent / tan_norm
    }

    shift <- c(0, 0, 0)
    for (k in 0:(2L * w_cc)) {
      cc_idx <- idx + k + 1L
      if (curvatures[cc_idx] == 0) {
        next
      }
      u <- curvature_vectors[cc_idx, ] / curvatures[cc_idx]
      shift_mag <- (1 / curvatures[cc_idx]) *
        (1 / radii_ma[cc_idx] - 1)
      shift <- shift + u * weights_cc[k + 1L] * shift_mag
    }

    out[idx, ] <- P_ma[centre, ] + ccma_cross(tangent, shift)
  }

  out
}
