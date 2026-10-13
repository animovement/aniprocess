#' @keywords internal
check_stinepack <- function() {
  rlang::check_installed(
    "stinepack",
    reason = "to use Stineman interpolation",
    action = function(...) {
      utils::install.packages(
        'stinepack',
        repos = c(
          'https://animovement.r-universe.dev',
          'https://cloud.r-project.org'
        )
      )
    }
  )
}
