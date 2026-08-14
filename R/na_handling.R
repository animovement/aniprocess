#' Shared NA-handling arguments for the filter family
#'
#' Documented in one place so every `filter_*()` function states the same
#' contract. Inherit with `@inheritParams filter-na-args`.
#'
#' @param na_action Method used to fill `NA` values *before* filtering, so
#'   the filter sees a complete series. One of `"linear"` (default),
#'   `"spline"`, `"stine"`, `"locf"`, `"value"`, or `"error"` to abort when
#'   `NA`s are present. Filling is internal: whether the filled values reach
#'   the output is controlled by `keep_na`.
#' @param keep_na Logical. If `TRUE` (default), positions that were `NA` in
#'   the input are `NA` in the output — gaps stay gaps. If `FALSE`, the
#'   values used to fill those gaps are kept, so the output has **fewer
#'   `NA`s than the input** and genuinely-missing stretches come back as
#'   interpolated estimates.
#'
#' @name filter-na-args
#' @keywords internal
NULL

#' Validate a `keep_na` argument
#'
#' @param keep_na The value to validate.
#' @param call Environment used for the error's call context.
#'
#' @return Invisibly `NULL`. Called for side effects (errors).
#' @keywords internal
ensure_keep_na <- function(keep_na, call = rlang::caller_env()) {
  if (!is.logical(keep_na) || length(keep_na) != 1L || is.na(keep_na)) {
    cli::cli_abort(
      "{.arg keep_na} must be a single {.code TRUE} or {.code FALSE}.",
      call = call
    )
  }
  invisible(NULL)
}

#' Record and fill NA positions before filtering
#'
#' Captures where the `NA`s are, then fills them via [replace_na_with()] so the
#' filter receives a complete series. Pair with [restore_na()] to put the
#' gaps back afterwards.
#'
#' Accepts a numeric vector or a numeric matrix; a matrix is filled
#' column-wise, since interpolating down a column is meaningful whereas
#' interpolating across coordinates is not.
#'
#' @param x Numeric vector or matrix.
#' @param na_action One of the [replace_na_with()] methods, or `"error"`.
#' @param replace_na_args Named list of extra arguments for [replace_na_with()],
#'   typically `list(...)` from the calling filter.
#' @param call Environment used for the error's call context.
#'
#' @return A list with `x` (the filled input) and `na_positions` (a logical
#'   vector or matrix, matching the shape of `x`, marking the original
#'   `NA`s).
#' @keywords internal
prepare_na <- function(
  x,
  na_action,
  replace_na_args = list(),
  call = rlang::caller_env()
) {
  na_positions <- is.na(x)

  if (!any(na_positions)) {
    return(list(x = x, na_positions = na_positions))
  }
  if (identical(na_action, "error")) {
    cli::cli_abort("Input contains {.code NA} values.", call = call)
  }

  fill <- function(v) {
    do.call(replace_na_with, c(list(v, method = na_action), replace_na_args))
  }

  if (is.matrix(x)) {
    for (i in seq_len(ncol(x))) {
      if (anyNA(x[, i])) {
        x[, i] <- fill(x[, i])
      }
    }
  } else {
    x <- fill(x)
  }

  list(x = x, na_positions = na_positions)
}

#' Restore NAs to their original positions after filtering
#'
#' The counterpart to [prepare_na()], and also usable on its own by filters
#' that never fill (they infer through gaps, or handle `NA` natively) but
#' should still honour `keep_na`.
#'
#' @param result Filter output, the same shape as the original input.
#' @param na_positions Logical vector or matrix from [prepare_na()], or from
#'   `is.na()` on the original input.
#' @param keep_na Logical. When `FALSE`, `result` is returned untouched.
#'
#' @return `result`, with `NA` written back at `na_positions` when
#'   `keep_na` is `TRUE`.
#' @keywords internal
restore_na <- function(result, na_positions, keep_na) {
  if (isTRUE(keep_na) && any(na_positions)) {
    result[na_positions] <- NA_real_
  }
  result
}
