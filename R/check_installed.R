#' @keywords internal
check_data_table <- function() {
  rlang::check_installed(
    "data.table (>= 1.18.0)",
    reason = "to use rolling filters",
    action = function(...) {
      utils::install.packages(
        'data.table',
        repos = c(
          'https://animovement.r-universe.dev',
          'https://cloud.r-project.org'
        )
      )
    }
  )
}

#' @keywords internal
check_signal <- function() {
  rlang::check_installed(
    "signal",
    reason = "to use the bandwidth filters",
    action = function(...) {
      utils::install.packages(
        'signal',
        repos = c(
          'https://animovement.r-universe.dev',
          'https://cloud.r-project.org'
        )
      )
    }
  )
}

#' @keywords internal
check_animetric <- function() {
  rlang::check_installed(
    "animetric",
    reason = "to calculate speed",
    action = function(...) {
      utils::install.packages(
        'animetric',
        repos = c(
          'https://animovement.r-universe.dev',
          'https://cloud.r-project.org'
        )
      )
    }
  )
}
