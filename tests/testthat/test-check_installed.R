# Testing check_stinepack()
# - It asks rlang::check_installed() for stinepack, with a reason
# - stinepack is on CRAN, so it installs the default way, from the user's repos

test_that("check_stinepack asks for stinepack, installed from CRAN", {
  captured <- NULL
  local_mocked_bindings(
    check_installed = function(pkg, reason = NULL, action = NULL, ...) {
      captured <<- list(pkg = pkg, reason = reason, action = action)
      invisible()
    },
    .package = "rlang"
  )

  check_stinepack()

  expect_equal(captured$pkg, "stinepack")
  expect_match(captured$reason, "Stineman interpolation")
  expect_null(captured$action)
})
