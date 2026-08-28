#' Replace Missing Values Using Stineman Interpolation
#'
#' @description
#' Replaces missing values using Stineman interpolation, with control over both
#' minimum and maximum gap sizes to interpolate.
#'
#' @param x A vector containing numeric data with missing values (NAs)
#' @param min_gap Integer specifying minimum gap size to interpolate. Gaps shorter
#'   than this will be left as NA. Default is 1 (interpolate all gaps).
#' @param max_gap Integer or Inf specifying maximum gap size to interpolate. Gaps longer
#'   than this will be left as NA. Default is Inf (no upper limit).
#' @param times Optional numeric vector of positions for the values in `x`,
#'   normally the frame's index. Interpolation is then over elapsed time
#'   rather than over row position, so an irregularly sampled gap is filled
#'   correctly. Defaults to row position.
#' @param ... Additional parameters passed to stinepack::stinterp
#'
#' @return A numeric vector with NA values replaced by interpolated values where
#' gap length criteria are met.
#'
#' @details
#' The function applies both minimum and maximum gap criteria:
#' - Gaps shorter than min_gap are left as NA
#' - Gaps longer than max_gap are left as NA
#' - Only gaps that meet both criteria are interpolated
#' If both parameters are specified, min_gap must be less than or equal to max_gap.
#'
#' Stineman interpolation is particularly good at preserving the shape of the data
#' and avoiding overshooting.
#'
#' @examples
#' \dontrun{
#' x <- c(1, NA, NA, 4, 5, NA, NA, NA, 9)
#' replace_na_stine(x)  # interpolates all gaps
#' replace_na_stine(x, min_gap = 2)  # only gaps >= 2
#' replace_na_stine(x, max_gap = 2)  # only gaps <= 2
#' replace_na_stine(x, min_gap = 2, max_gap = 3)  # gaps between 2 and 3
#' }
#' @export
replace_na_stine <- function(x, min_gap = 1, max_gap = Inf, times = NULL, ...) {
  check_stinepack()
  ensure_replace_na_args(x, min_gap, max_gap)

  if (!anyNA(x)) {
    return(x)
  }

  if (sum(!is.na(x)) < 2) {
    cli::cli_warn("At least 2 non-NA data points required for interpolation")
    return(x)
  }

  # Get indices
  n <- length(x)
  missindx <- is.na(x)
  allindx <- interpolation_positions(x, times)
  indx <- allindx[!missindx]

  # Perform interpolation
  interp <- stinepack::stinterp(indx, x[!missindx], allindx, ...)$y

  # Handle any edge NAs like approx does
  if (any(is.na(interp))) {
    interp <- data.table::nafill(interp, type = "locf")
  }

  # Apply gap filtering
  if (min_gap > 1 || is.finite(max_gap)) {
    # Get run lengths of NA sequences
    runs <- rle(is.na(x))

    # Create logical vector for valid gap sizes
    valid_gaps <- runs$values &
      runs$lengths >= min_gap &
      runs$lengths <= max_gap

    # Update runs to only interpolate valid gaps
    runs$values[runs$values] <- valid_gaps[runs$values]
    gaps <- inverse.rle(runs)

    # Keep original NAs for invalid gaps
    interp[!gaps & missindx] <- NA
  }

  # Replace only the NA values
  x[missindx] <- interp[missindx]
  return(x)
}
