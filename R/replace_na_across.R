#' Fill missing values across an aniframe's spatial columns
#'
#' @description
#' `r lifecycle::badge('experimental')`
#'
#' The aniframe-level entry point to the `replace_na_*()` family. Fills
#' gaps in the columns given by the `variables_where` metadata field,
#' within the frame's existing grouping — so a gap is never filled by
#' interpolating between two different tracks.
#'
#' @param data An aniframe.
#' @param method Character string specifying the replacement method:
#'   - `"linear"`: Linear interpolation (default)
#'   - `"spline"`: Spline interpolation for smoother curves
#'   - `"stine"`: Stineman interpolation preserving data shape
#'   - `"locf"`: Last observation carried forward
#'   - `"value"`: Replace with a constant value
#' @param variables Columns to fill, as a tidyselect expression. Defaults
#'   to the `variables_where` metadata field.
#' @param ... Arguments passed to [replace_na_with()], such as `value`,
#'   `min_gap` and `max_gap`.
#'
#' @return An aniframe of the same shape, with gaps filled.
#'
#' @examples
#' \dontrun{
#' replace_na_across(tracking_data, "linear", max_gap = 5)
#' replace_na_across(tracking_data, "value", value = 0, variables = c(x, y))
#' }
#'
#' @seealso [replace_na_with()] for the vector-level generic.
#' @export
replace_na_across <- function(
  data,
  method = c("linear", "spline", "stine", "locf", "value"),
  variables = NULL,
  ...
) {
  method <- match.arg(method)
  anicore::ensure_is_spatial(data)

  variables <- resolve_variables(data, rlang::enquo(variables))
  args <- c(list(method = method), rlang::list2(...))

  dplyr::mutate(
    data,
    apply_across_columns(
      dplyr::pick(dplyr::all_of(variables)),
      variables = variables,
      fn = replace_na_with,
      args = args
    )
  )
}
