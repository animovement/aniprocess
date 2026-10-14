#' @keywords internal
check_stinepack <- function() {
  rlang::check_installed("stinepack", reason = "to use Stineman interpolation")
}
