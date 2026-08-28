#' Resolve which columns an `*_across()` verb should operate on.
#'
#' Defaults to the columns named by the `variables_where` metadata field.
#' A tidyselect expression overrides that.
#'
#' @param data An aniframe.
#' @param variables A tidyselect expression, already defused, or `NULL`.
#' @param call Environment used for the error's call context.
#'
#' @return A character vector of column names.
#' @keywords internal
resolve_variables <- function(data, variables, call = rlang::caller_env()) {
  if (rlang::quo_is_null(variables)) {
    return(anicore::get_metadata(data, "variables_where"))
  }

  selected <- names(tidyselect::eval_select(variables, data, error_call = call))
  if (length(selected) == 0L) {
    cli::cli_abort("{.arg variables} selected no columns.", call = call)
  }

  non_numeric <- selected[!vapply(data[selected], is.numeric, logical(1))]
  if (length(non_numeric) > 0L) {
    cli::cli_abort(
      "Selected column{?s} {.val {non_numeric}} {?is/are} not numeric.",
      call = call
    )
  }
  selected
}

#' Look up a required parameter from aniframe metadata.
#'
#' The frame already knows its sampling rate and which column holds time,
#' so an `*_across()` verb should not make the caller repeat them.
#'
#' @param data An aniframe.
#' @param field Metadata field to read.
#' @param what Human-readable name of the parameter, for errors.
#' @param call Environment used for the error's call context.
#'
#' @return The metadata value.
#' @keywords internal
metadata_value <- function(data, field, what, call = rlang::caller_env()) {
  value <- anicore::get_metadata(data, field)
  if (length(value) == 0L || all(is.na(value))) {
    cli::cli_abort(
      c(
        "Cannot determine {what}.",
        "i" = "Set the {.field {field}} metadata field, or pass it directly."
      ),
      call = call
    )
  }
  value
}

#' Resolve a helper column named by an argument.
#'
#' At the aniframe level a per-row argument such as `time` has to be a
#' column *name*, not a vector: each group needs its own slice, and a
#' whole-frame vector cannot be sliced by [dplyr::mutate()]. The vector
#' form belongs to the vector-level functions.
#'
#' @param value The supplied argument, or `NULL`.
#' @param arg Argument name, for errors.
#' @param generic Name of the vector-level function, for the hint.
#' @param call Environment used for the error's call context.
#'
#' @return A single column name, or `NULL`.
#' @keywords internal
helper_column <- function(value, arg, generic, call = rlang::caller_env()) {
  if (is.null(value)) {
    return(NULL)
  }
  if (!is.character(value) || length(value) != 1L) {
    cli::cli_abort(
      c(
        "{.arg {arg}} must be the name of a column.",
        "i" = "Each group needs its own slice, so a whole-frame vector cannot be used here.",
        "i" = "To pass a vector, use {.fn {generic}} on a coordinate frame."
      ),
      call = call
    )
  }
  value
}

#' Apply a per-column function across one group's columns.
#'
#' Called inside [dplyr::mutate()] with [dplyr::pick()], so `cols` holds
#' one group's rows. Returns a frame of just `variables`, which mutate
#' splices back over them.
#'
#' @param cols A data frame of the group's columns: `variables` plus any
#'   helper column the method needs.
#' @param variables Names of the columns to transform.
#' @param fn Function applied to each column.
#' @param args Additional arguments for `fn`.
#' @param helpers Named list mapping an argument name to a column name in
#'   `cols`, supplied per group (e.g. `list(times = "time")`).
#'
#' @return A data frame with the `variables` columns transformed.
#' @keywords internal
apply_across_columns <- function(
  cols,
  variables,
  fn,
  args = list(),
  helpers = list()
) {
  for (arg in names(helpers)) {
    args[[arg]] <- cols[[helpers[[arg]]]]
  }
  out <- cols[variables]
  for (v in variables) {
    out[[v]] <- do.call(fn, c(list(cols[[v]]), args))
  }
  out
}
