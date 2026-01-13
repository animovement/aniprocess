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

check_signal <- function() {
  rlang::check_installed(
    "signal",
    reason = "to use the low-pass filter",
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
