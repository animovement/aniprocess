#' Apply a filter across an aniframe's spatial columns
#'
#' @description
#' `r lifecycle::badge('experimental')`
#'
#' The aniframe-level entry point to the `filter_*()` family. Applies a
#' named filter to the columns given by the `variables_where` metadata
#' field, within the frame's existing grouping.
#'
#' @details
#' This is the aniframe tier of the interface:
#'
#' * [filter_gaussian()] and friends filter one vector — use them inside
#'   [dplyr::mutate()].
#' * [filter_with()] does the same but picks the method by name.
#' * `filter_across()` applies a method to a whole aniframe.
#'
#' Beyond looping over columns, it fills in what the frame already knows:
#' `sampling_rate` comes from metadata for the methods that need it, and
#' `"kalman_irregular"` takes its `times` from the column named by
#' `variables_when`. Either can still be passed explicitly to override.
#'
#' `"ccma"` is multivariate — each output coordinate depends on all of
#' them — so it is applied jointly rather than column by column.
#'
#' @param data An aniframe.
#' @param method Filter to apply. One of `"gaussian"`, `"rollmean"`,
#'   `"rollmedian"`, `"triangular"`, `"sgolay"`, `"lowpass"`, `"highpass"`,
#'   `"lowpass_fft"`, `"highpass_fft"`, `"kalman"`, `"kalman_irregular"`,
#'   `"one_euro"` or `"ccma"`.
#' @param variables Columns to filter, as a tidyselect expression.
#'   Defaults to the `variables_where` metadata field.
#' @param ... Arguments passed to the underlying filter.
#' @param on_deltas If `TRUE`, difference each column, filter the
#'   differences, and re-integrate from the original starting value. For
#'   trackball data, where the raw measurements are per-frame displacements
#'   and the coordinates were integrated from them, smoothing belongs on
#'   the displacements rather than on the integrated positions.
#'
#'   A `NA` among the filtered differences counts as no movement when
#'   accumulating, and is restored as `NA` at its own position, so one
#'   missing step does not blank the rest of the series.
#'
#' @return An aniframe of the same shape, with the selected columns
#'   filtered.
#'
#' @examples
#' \dontrun{
#' # sampling_rate is taken from the aniframe's metadata
#' filter_across(tracking_data, "lowpass", cutoff_freq = 5)
#'
#' # restrict to some of the spatial columns
#' filter_across(tracking_data, "gaussian", variables = c(x, y), sigma = 2)
#' }
#'
#' @seealso [filter_with()] for the vector-level generic.
#' @export
filter_across <- function(
  data,
  method = c(
    "gaussian",
    "rollmean",
    "rollmedian",
    "triangular",
    "sgolay",
    "lowpass",
    "highpass",
    "lowpass_fft",
    "highpass_fft",
    "kalman",
    "kalman_irregular",
    "one_euro",
    "ccma"
  ),
  variables = NULL,
  ...,
  on_deltas = FALSE
) {
  method <- match.arg(method)
  ensure_aniframe_spatial(data)

  variables <- resolve_variables(data, rlang::enquo(variables))
  args <- rlang::list2(...)

  # ccma is multivariate: hand it all the columns at once.
  if (method == "ccma") {
    # The curvature math is Cartesian-specific, and only the aniframe knows
    # its coordinate system -- filter_ccma() sees bare columns.
    coord_system <- as.character(
      aniframe::get_metadata(data, "coordinate_system")
    )
    if (length(coord_system) > 0L && !startsWith(coord_system, "cartesian")) {
      cli::cli_abort(c(
        "CCMA requires a Cartesian coordinate system; got {.val {coord_system}}.",
        "i" = "The curvature math (cross product, Euclidean norm, circumradius) is Cartesian-specific."
      ))
    }
    return(dplyr::mutate(
      data,
      do.call(
        filter_ccma,
        c(list(dplyr::pick(dplyr::all_of(variables))), args)
      )
    ))
  }

  # The frame knows its own sampling rate and time column.
  if (!"sampling_rate" %in% names(args) && filter_needs_sampling_rate(method)) {
    args$sampling_rate <- metadata_value(
      data,
      "sampling_rate",
      "the sampling rate"
    )
  }

  # `times` names a column here, not a vector: mutate() has to slice it per
  # group alongside the coordinates.
  helpers <- list()
  if (method == "kalman_irregular") {
    helpers$times <- helper_column(args$times, "times", "filter_with") %||%
      metadata_value(data, "variables_when", "which column holds time")[1]
    args$times <- NULL
    if (!helpers$times %in% names(data)) {
      cli::cli_abort("Missing time column: {.val {helpers$times}}.")
    }
  }

  fn <- filter_method_fn(method)
  if (isTRUE(on_deltas)) {
    fn <- derivative_wrapper(fn)
  }

  needed <- unique(c(variables, unlist(helpers, use.names = FALSE)))
  dplyr::mutate(
    data,
    apply_across_columns(
      dplyr::pick(dplyr::all_of(needed)),
      variables = variables,
      fn = fn,
      args = args,
      helpers = helpers
    )
  )
}


#' Look up the function implementing a filter method.
#'
#' "ccma" is handled before this lookup, being the only multivariate method.
#'
#' @keywords internal
filter_method_fn <- function(method) {
  switch(
    method,
    gaussian = filter_gaussian,
    rollmean = filter_rollmean,
    rollmedian = filter_rollmedian,
    triangular = filter_triangular,
    sgolay = filter_sgolay,
    lowpass = filter_lowpass,
    highpass = filter_highpass,
    lowpass_fft = filter_lowpass_fft,
    highpass_fft = filter_highpass_fft,
    kalman = filter_kalman,
    kalman_irregular = filter_kalman_irregular,
    one_euro = filter_one_euro
  )
}


#' Does a filter method require a sampling rate?
#' @keywords internal
filter_needs_sampling_rate <- function(method) {
  method %in%
    c(
      "sgolay",
      "lowpass",
      "highpass",
      "lowpass_fft",
      "highpass_fft",
      "kalman",
      "one_euro"
    )
}


#' Wrap a filter so it acts on differences rather than on levels.
#'
#' Differences the column, filters the differences, then re-integrates from
#' the original starting value — so with a filter that does nothing, the
#' round trip returns the input unchanged.
#'
#' A `NA` among the filtered differences is treated as no movement for the
#' purpose of accumulation, and restored as `NA` at its own position, so one
#' missing step does not blank the rest of the series.
#'
#' @param fn The filter to wrap.
#'
#' @return A function with the same interface as `fn`.
#' @keywords internal
derivative_wrapper <- function(fn) {
  # `fn` is reassigned to this wrapper by the caller, so the promise has to
  # be forced here or the closure would call itself.
  force(fn)
  function(col, ...) {
    d <- col - dplyr::lag(col)
    d <- fn(d, ...)
    # There is no step into the first sample; it *is* the starting point.
    d[1] <- 0
    col[1] + cumsum(dplyr::coalesce(d, 0)) + d * 0
  }
}
