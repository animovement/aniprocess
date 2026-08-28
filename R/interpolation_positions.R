#' Positions to interpolate against
#'
#' Row position by default, the index values when the caller supplies them.
#' On a regularly sampled frame the two are proportional and agree; on an
#' irregular one they do not, and row position silently places an imputed
#' value at the wrong moment (#67).
#'
#' @param x The vector being filled.
#' @param times Index values, or `NULL` for row position.
#'
#' @return Numeric vector the same length as `x`.
#' @keywords internal
interpolation_positions <- function(x, times = NULL) {
  if (is.null(times)) {
    return(seq_along(x))
  }
  if (!is.numeric(times) || length(times) != length(x)) {
    cli::cli_abort(
      "{.arg times} must be a numeric vector the same length as the data."
    )
  }
  times
}
