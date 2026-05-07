#' @keywords internal
check_roll <- function() {
  rlang::check_installed(
    "roll",
    reason = "to use rolling filters",
    action = function(...) {
      utils::install.packages(
        'roll',
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
