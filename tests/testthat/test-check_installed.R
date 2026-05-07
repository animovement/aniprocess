# Testing check_roll() and check_signal()
# - Functions call rlang::check_installed with correct arguments
# - Custom action installs from correct repositories
# - Correct reason messages are provided

test_that("check_roll works and calls correct functions", {
  captured_args <- NULL

  local_mocked_bindings(
    check_installed = function(pkg, reason, action) {
      captured_args <<- list(pkg = pkg, reason = reason, action = action)
      # Actually execute the action to get coverage
      action()
    },
    .package = "rlang"
  )

  install_args <- NULL
  local_mocked_bindings(
    install.packages = function(pkgs, repos, ...) {
      install_args <<- list(pkgs = pkgs, repos = repos)
    },
    .package = "utils"
  )

  check_roll()

  expect_equal(captured_args$pkg, "roll")
  expect_match(captured_args$reason, "to use rolling filters")
  expect_type(captured_args$action, "closure")

  expect_equal(install_args$pkgs, "roll")
  expect_equal(
    install_args$repos,
    c('https://animovement.r-universe.dev', 'https://cloud.r-project.org')
  )
})

test_that("check_signal works and calls correct functions", {
  captured_args <- NULL

  local_mocked_bindings(
    check_installed = function(pkg, reason, action) {
      captured_args <<- list(pkg = pkg, reason = reason, action = action)
      # Actually execute the action to get coverage
      action()
    },
    .package = "rlang"
  )

  install_args <- NULL
  local_mocked_bindings(
    install.packages = function(pkgs, repos, ...) {
      install_args <<- list(pkgs = pkgs, repos = repos)
    },
    .package = "utils"
  )

  check_signal()

  expect_equal(captured_args$pkg, "signal")
  expect_match(
    captured_args$reason,
    "to use the bandwidth filters"
  )
  expect_type(captured_args$action, "closure")

  expect_equal(install_args$pkgs, "signal")
  expect_equal(
    install_args$repos,
    c('https://animovement.r-universe.dev', 'https://cloud.r-project.org')
  )
})

