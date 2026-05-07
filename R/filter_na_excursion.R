#' Filter Out Position Excursions That Return
#'
#' @description
#' Flags multi-frame tracking errors as `NA` using the criterion from
#' Todd, Kain & de Bivort (2017): a frame-to-frame jump of more than
#' `outlier_sd` standard deviations starts an excursion, which is then
#' rejected if (and only if) the trajectory eventually returns either
#' close to the pre-excursion position or close to the overall median
#' position.
#'
#' @param data An aniframe.
#' @param outlier_sd Threshold (in standard deviations) for flagging
#'   frame-to-frame jumps and for the "return to pre-excursion position"
#'   acceptance check. Todd's default is `5`.
#' @param return_sd Threshold (in standard deviations) for the
#'   "return to overall median position" acceptance check. Todd's
#'   default is `1`.
#' @param by_axis Logical. If `TRUE` (the default), Todd's literal
#'   per-axis behaviour is used: each spatial column has its own σ,
#'   median, and excursion state machine, and a row is blanked if any
#'   axis flags it. If `FALSE`, a single state machine runs on the
#'   joint Euclidean displacement (consistent with [filter_na_speed()]).
#'
#' @details
#' For each spatial coordinate listed in the metadata field
#' `variables_where` (and within each existing aniframe group), the
#' algorithm:
#'
#' 1. Computes the standard deviation `σ` of the coordinate over the
#'    full series and the overall median `m`.
#' 2. Walks the series. When a frame-to-frame change exceeds
#'    `outlier_sd * σ`, an excursion starts: that frame is flagged
#'    and subsequent frames are flagged until the position is either
#'    within `outlier_sd * σ` of its pre-excursion value, or within
#'    `return_sd * σ` of the overall median. The first such frame is
#'    accepted (not flagged), and the state machine resets.
#'
#' This distinguishes transient excursions (a tracking glitch where
#' the position eventually comes back) from sustained shifts (the
#' animal genuinely moved to a new region) — the latter never satisfy
#' the return condition unless the new region happens to be near the
#' median, in which case it is accepted via the second criterion.
#'
#' Spatial columns and `confidence` (if present) are set to `NA` at
#' flagged rows, matching the convention used by [filter_na_speed()].
#'
#' @return An aniframe of the same shape, with flagged rows blanked.
#'
#' @references
#' Todd, J. G., Kain, J. S., & de Bivort, B. L. (2017). Systematic
#' exploration of unsupervised methods for mapping behavior.
#' *Physical Biology*, 14(1), 015002.
#' \doi{10.1088/1478-3975/14/1/015002}.
#'
#' @examples
#' \dontrun{
#' # Default Todd thresholds, per-axis.
#' filter_na_excursion(tracking_data)
#'
#' # Joint Euclidean variant, looser thresholds.
#' filter_na_excursion(tracking_data, outlier_sd = 4, by_axis = FALSE)
#' }
#'
#' @seealso [filter_na_speed()] for single-frame outliers.
#'
#' @export
filter_na_excursion <- function(
  data,
  outlier_sd = 5,
  return_sd = 1,
  by_axis = TRUE
) {
  ensure_aniframe_spatial(data)
  variables_where <- aniframe::get_metadata(data, "variables_where")

  for (sd_arg in c("outlier_sd", "return_sd")) {
    val <- get(sd_arg)
    if (!is.numeric(val) || length(val) != 1L || val <= 0) {
      cli::cli_abort("{.arg {sd_arg}} must be a single positive number.")
    }
  }

  # Determine row groups (one ungrouped block when nothing is grouped)
  group_id <- if (
    inherits(data, "grouped_df") && length(dplyr::group_vars(data)) > 0L
  ) {
    dplyr::group_indices(data)
  } else {
    rep(1L, nrow(data))
  }

  for (g in unique(group_id)) {
    rows <- which(group_id == g)
    if (length(rows) < 2L) {
      next
    }
    flagged <- if (by_axis) {
      excursion_mask_per_axis(
        data,
        rows,
        variables_where,
        outlier_sd,
        return_sd
      )
    } else {
      excursion_mask_joint(
        data,
        rows,
        variables_where,
        outlier_sd,
        return_sd
      )
    }
    if (!any(flagged)) {
      next
    }
    target_rows <- rows[flagged]
    for (col in variables_where) {
      data[[col]][target_rows] <- NA_real_
    }
    if ("confidence" %in% names(data)) {
      data$confidence[target_rows] <- NA_real_
    }
  }

  data
}


#' Per-axis excursion state machine.
#'
#' Returns a logical vector (length `length(rows)`) with `TRUE` at rows
#' where any spatial axis is currently inside an excursion run.
#'
#' @keywords internal
excursion_mask_per_axis <- function(
  data,
  rows,
  variables_where,
  outlier_sd,
  return_sd
) {
  flagged <- rep(FALSE, length(rows))
  for (col in variables_where) {
    x <- data[[col]][rows]
    sigma <- stats::sd(x, na.rm = TRUE)
    med <- stats::median(x, na.rm = TRUE)
    if (!is.finite(sigma) || sigma == 0) {
      next
    }
    flagged <- flagged |
      excursion_state_machine_1d(x, sigma, med, outlier_sd, return_sd)
  }
  flagged
}


#' Joint-Euclidean excursion state machine.
#'
#' @keywords internal
excursion_mask_joint <- function(
  data,
  rows,
  variables_where,
  outlier_sd,
  return_sd
) {
  P <- as.matrix(as.data.frame(data)[rows, variables_where, drop = FALSE])
  axis_sd <- vapply(
    seq_len(ncol(P)),
    function(j) stats::sd(P[, j], na.rm = TRUE),
    numeric(1)
  )
  if (any(!is.finite(axis_sd)) || all(axis_sd == 0)) {
    return(rep(FALSE, nrow(P)))
  }
  sigma <- sqrt(sum(axis_sd^2))
  med <- vapply(
    seq_len(ncol(P)),
    function(j) stats::median(P[, j], na.rm = TRUE),
    numeric(1)
  )

  n <- nrow(P)
  flagged <- rep(FALSE, n)
  in_run <- FALSE
  pre_pos <- NULL
  last_valid <- NA_integer_
  for (i in seq_len(n)) {
    if (anyNA(P[i, ])) {
      next
    }
    if (is.na(last_valid)) {
      last_valid <- i
      next
    }
    if (!in_run) {
      step <- sqrt(sum((P[i, ] - P[last_valid, ])^2))
      if (step > outlier_sd * sigma) {
        pre_pos <- P[last_valid, ]
        flagged[i] <- TRUE
        in_run <- TRUE
        next
      }
    } else {
      d_pre <- sqrt(sum((P[i, ] - pre_pos)^2))
      d_med <- sqrt(sum((P[i, ] - med)^2))
      if (d_pre <= outlier_sd * sigma || d_med <= return_sd * sigma) {
        in_run <- FALSE
      } else {
        flagged[i] <- TRUE
        next
      }
    }
    last_valid <- i
  }
  flagged
}


#' One-dimensional excursion state machine.
#'
#' @keywords internal
excursion_state_machine_1d <- function(
  x,
  sigma,
  med,
  outlier_sd,
  return_sd
) {
  n <- length(x)
  flagged <- rep(FALSE, n)
  in_run <- FALSE
  pre_x <- NA_real_
  last_valid <- NA_integer_
  for (i in seq_len(n)) {
    if (is.na(x[i])) {
      next
    }
    if (is.na(last_valid)) {
      last_valid <- i
      next
    }
    if (!in_run) {
      if (abs(x[i] - x[last_valid]) > outlier_sd * sigma) {
        pre_x <- x[last_valid]
        flagged[i] <- TRUE
        in_run <- TRUE
        next
      }
    } else {
      if (
        abs(x[i] - pre_x) <= outlier_sd * sigma ||
          abs(x[i] - med) <= return_sd * sigma
      ) {
        in_run <- FALSE
      } else {
        flagged[i] <- TRUE
        next
      }
    }
    last_valid <- i
  }
  flagged
}
