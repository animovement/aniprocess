#' Validate aniframe spatial readiness.
#'
#' Consolidates the input validation that every aniframe-aware filter
#' has to do before touching the spatial coordinates: the input must
#' be an aniframe, every column named in the metadata field
#' `variables_where` must be present, and each must be numeric.
#'
#' Aborts with a granular error message identifying which condition
#' failed; otherwise returns `data` invisibly.
#'
#' @param data An aniframe.
#'
#' @return `data`, invisibly.
#' @keywords internal
ensure_aniframe_spatial <- function(data) {
  aniframe::ensure_is_aniframe(data)
  variables_where <- aniframe::get_metadata(data, "variables_where")
  missing_where <- setdiff(variables_where, names(data))
  if (length(missing_where) > 0L) {
    cli::cli_abort(c(
      "Missing spatial column{?s}: {.val {missing_where}}.",
      "i" = "Spatial variables from metadata: {.val {variables_where}}."
    ))
  }
  for (col in variables_where) {
    if (!is.numeric(data[[col]])) {
      cli::cli_abort("Column {.val {col}} must be numeric.")
    }
  }
  invisible(data)
}
