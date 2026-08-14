#' Dispatch a method name to its implementation.
#'
#' Shared machinery for the `*_with()` generics. Applies the
#' shape-preserving contract: a vector in gives a vector out, a frame of
#' coordinate columns gives a frame out.
#'
#' Univariate methods are applied column-wise when given a frame.
#' Multivariate methods — where each result depends on all coordinates
#' jointly — require a frame, and say so when handed a bare vector.
#'
#' @param x A numeric vector or a data frame of coordinate columns.
#' @param method The resolved method name.
#' @param fn The function implementing `method`.
#' @param multivariate `TRUE` if `method` needs all coordinates at once.
#' @param generic Name of the calling generic, for error messages.
#' @param ... Passed on to `fn`.
#' @param call Environment used for the error's call context.
#'
#' @return The same shape as `x`.
#' @keywords internal
dispatch_method <- function(
  x,
  method,
  fn,
  multivariate,
  generic,
  ...,
  call = rlang::caller_env()
) {
  # An aniframe is a data frame, so without this it would be filtered
  # column-wise -- including `time` and any identity columns.
  if (aniframe::is_aniframe(x)) {
    cli::cli_abort(
      c(
        "{.arg x} is an aniframe, but {.fn {generic}} works on a vector or a frame of coordinate columns.",
        "i" = "Inside {.fn dplyr::mutate}, use {.code pick(all_of(...))}.",
        "i" = "To filter a whole aniframe, use {.fn filter_aniframe}."
      ),
      call = call
    )
  }

  if (multivariate) {
    if (!is.data.frame(x)) {
      cli::cli_abort(
        c(
          "Method {.val {method}} needs a frame of coordinate columns, not a vector.",
          "i" = "Each result depends on all coordinates jointly.",
          "i" = "Inside {.fn dplyr::mutate}, use {.code pick(all_of(...))}."
        ),
        call = call
      )
    }
    return(fn(x, ...))
  }

  # Univariate: a frame is filtered one column at a time.
  if (is.data.frame(x)) {
    ensure_coords(x, arg = "x", call = call)
    for (col in names(x)) {
      x[[col]] <- fn(x[[col]], ...)
    }
    return(x)
  }

  fn(x, ...)
}
