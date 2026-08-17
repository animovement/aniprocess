#' Mask values to NA across an aniframe's spatial columns
#'
#' @description
#' `r lifecycle::badge('experimental')`
#'
#' The aniframe-level entry point to the `filter_na_*()` family. Applies a
#' named criterion to the columns given by the `variables_where` metadata
#' field, within the frame's existing grouping — so a criterion is never
#' evaluated across a track boundary.
#'
#' @details
#' Beyond looping over columns, it fills in what the frame already knows:
#' `"speed"` takes its `time` from the column named by `variables_when`,
#' and `"confidence"` takes its `confidence` from the column of that name.
#' Either can be passed explicitly to override.
#'
#' Only `"range"` is univariate. The others decide per row using all the
#' selected columns at once, and blank every one of them on a flagged row.
#'
#' Where a `confidence` column is present, it is blanked on rows that this
#' call masked — the cross-column effect that the vector-level functions
#' cannot perform, since `confidence` is not a coordinate.
#'
#' @param data An aniframe.
#' @param method Criterion to apply. One of `"range"`, `"speed"`,
#'   `"excursion"`, `"roi"` or `"confidence"`.
#' @param variables Columns to mask, as a tidyselect expression. Defaults
#'   to the `variables_where` metadata field.
#' @param ... Arguments passed to the underlying function.
#'
#'   For `"speed"`, `threshold` additionally accepts `"pooled"`: `"auto"`
#'   estimates a threshold separately for each group, so every track is
#'   judged against its own noise; `"pooled"` estimates one threshold from
#'   all groups at once, which is steadier when tracks are short.
#'
#' @return An aniframe of the same shape, with failing values replaced by
#'   `NA`.
#'
#' @examples
#' \dontrun{
#' # time comes from the aniframe's metadata
#' filter_na_across(tracking_data, "speed", threshold = "auto")
#'
#' filter_na_across(tracking_data, "range", min_value = 0, max_value = 1920)
#' }
#'
#' @seealso [filter_na_with()] for the vector-level generic.
#' @export
filter_na_across <- function(
  data,
  method = c("range", "speed", "excursion", "roi", "confidence"),
  variables = NULL,
  ...
) {
  method <- match.arg(method)
  aniframe::ensure_is_spatial(data)

  variables <- resolve_variables(data, rlang::enquo(variables))
  args <- rlang::list2(...)

  # "range" is univariate: applied one column at a time.
  if (method == "range") {
    return(dplyr::mutate(
      data,
      apply_across_columns(
        dplyr::pick(dplyr::all_of(variables)),
        variables = variables,
        fn = filter_na_range,
        args = args
      )
    ))
  }

  # `time` and `confidence` name columns here, not vectors: mutate() has to
  # slice them per group alongside the coordinates.
  helpers <- list()
  if (method == "speed") {
    helpers$time <- helper_column(args$time, "time", "filter_na_with") %||%
      metadata_value(data, "variables_when", "which column holds time")[1]
    args$time <- NULL
  }
  if (method == "confidence") {
    helpers$confidence <- helper_column(
      args$confidence,
      "confidence",
      "filter_na_with"
    ) %||%
      "confidence"
    args$confidence <- NULL
  }
  for (col in unlist(helpers, use.names = FALSE)) {
    if (!col %in% names(data)) {
      cli::cli_abort("Missing required column: {.val {col}}.")
    }
  }

  fn <- filter_na_method_fn(method)
  needed <- unique(c(variables, unlist(helpers, use.names = FALSE)))

  # "auto" is resolved per group by filter_na_speed(), which sees one
  # group at a time. "pooled" is resolved here instead, from every group's
  # speeds at once, and passed down as a number.
  if (method == "speed" && identical(args$threshold, "pooled")) {
    speeds <- dplyr::mutate(
      data,
      .aniprocess_speed = calculate_step_speed(
        dplyr::pick(dplyr::all_of(variables)),
        .data[[helpers$time]]
      )
    )$.aniprocess_speed
    args$threshold <- mean(speeds, na.rm = TRUE) +
      3 * stats::sd(speeds, na.rm = TRUE)
  }

  out <- dplyr::mutate(
    data,
    mask_across_columns(
      dplyr::pick(dplyr::all_of(needed)),
      variables = variables,
      fn = fn,
      args = args,
      helpers = helpers
    )
  )

  # `confidence` is not a coordinate, so the vector-level functions cannot
  # reach it. Blank it wherever this call masked a row.
  if ("confidence" %in% names(out)) {
    masked <- newly_masked(data, out, variables)
    out$confidence[masked] <- NA_real_
  }

  # Filtering on confidence also drops the failing confidence values.
  if (method == "confidence") {
    threshold <- args$threshold %||% formals(filter_na_confidence)$threshold
    out$confidence <- filter_na_range(
      out$confidence,
      min_value = as.numeric(threshold)
    )
  }

  out
}


#' Look up the function implementing an NA-masking method.
#' @keywords internal
filter_na_method_fn <- function(method) {
  # "range" is handled before this lookup, being the only univariate method
  switch(
    method,
    speed = filter_na_speed,
    excursion = filter_na_excursion,
    roi = filter_na_roi,
    confidence = filter_na_confidence
  )
}


#' Apply a multivariate masker to one group's columns.
#'
#' Called inside [dplyr::mutate()] with [dplyr::pick()], so `cols` holds
#' one group's rows.
#'
#' @inheritParams apply_across_columns
#'
#' @return A data frame of the `variables` columns, masked.
#' @keywords internal
mask_across_columns <- function(
  cols,
  variables,
  fn,
  args = list(),
  helpers = list()
) {
  for (arg in names(helpers)) {
    args[[arg]] <- cols[[helpers[[arg]]]]
  }
  do.call(fn, c(list(cols[variables]), args))
}


#' Which rows did a masking call newly blank?
#'
#' A masker blanks every selected column on a flagged row, so a row is
#' newly masked when all of them are `NA` afterwards but were not before.
#'
#' @param before,after The aniframe on either side of the call.
#' @param variables Columns that were masked.
#'
#' @return A logical vector, one value per row.
#' @keywords internal
newly_masked <- function(before, after, variables) {
  all_na <- function(d) {
    Reduce(`&`, lapply(variables, function(v) is.na(d[[v]])))
  }
  all_na(after) & !all_na(before)
}
